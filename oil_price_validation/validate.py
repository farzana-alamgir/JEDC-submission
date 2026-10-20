"""Validate a separate candidate oil-price process; never runs the submitted solver.

Requires numpy. Run from any directory with Python 3.
Candidate parameters are rounded posterior conditional means supplied in the chat;
they are not a re-estimation or a replacement for the submitted calibration.
"""
from pathlib import Path
import csv
import io
import json
import shutil
import subprocess
import tempfile
import math

import numpy as np

ROOT = Path(__file__).resolve().parent
CENTER = -0.1126566
RP, MH, RH, EH = 0.9683596, -4.2718859, 0.6677605, 0.5866213
VH = EH**2 / (1 - RH**2)
INNOVATION_VARIANCE = np.exp(MH + VH/2)
Z_SD = np.sqrt(INNOVATION_VARIANCE/(1-RP**2))


def ndtr(x):
    """Normal CDF using the standard-library erfc (no SciPy dependency)."""
    x = np.asarray(x)
    return np.frompyfunc(lambda t: 0.5*math.erfc(-t/math.sqrt(2)),1,1)(x).astype(float)


def normal_rows(grid, means, scales):
    """Gaussian cell probabilities, with tails assigned to boundary nodes."""
    bounds = np.r_[-np.inf, (grid[:-1]+grid[1:])/2, np.inf]
    lo = (bounds[:-1]-np.asarray(means)[..., None])/np.asarray(scales)[..., None]
    hi = (bounds[1:]-np.asarray(means)[..., None])/np.asarray(scales)[..., None]
    # Use survival probabilities in the upper tail to avoid cancellation.
    return np.maximum(0, np.where(lo >= 0, ndtr(-lo)-ndtr(-hi), ndtr(hi)-ndtr(lo)))


def kernel(nz, nh, z_width=6, h_width=4.5):
    z = np.linspace(CENTER-z_width*Z_SD, CENTER+z_width*Z_SD, nz)
    h = np.linspace(MH-h_width*np.sqrt(VH), MH+h_width*np.sqrt(VH), nh)
    s = normal_rows(h, MH+RH*(h-MH), np.full(nh, EH))
    means = CENTER+RP*(z-CENTER)
    p = normal_rows(z, np.broadcast_to(means, (nh,nz)),
                    np.broadcast_to(np.exp(h[:,None]/2), (nh,nz)))
    assert min(s.min(),p.min()) >= 0
    assert max(abs(s.sum(1)-1).max(),abs(p.sum(2)-1).max()) < 1e-12
    return z,h,s,p


def stationary(s, p):
    nh,nz,_ = p.shape
    d = np.full((nh,nz),1/(nh*nz))
    # Price index i always means the same physical log price, regardless of h.
    for iteration in range(20000):
        weights = s.T @ d
        new = np.einsum('li,lij->lj', weights, p, optimize=False)
        if np.max(abs(new-d)) < 1e-13:
            assert abs(new.sum()-1) < 1e-10
            return new,iteration+1
        d = new
    raise RuntimeError('Stationary iteration did not converge')


def stats(x):
    return dict(mean_log_price=float(x.mean()), sd_log_price=float(x.std(ddof=1)),
                persistence=float(np.corrcoef(x[:-1],x[1:])[0,1]))


def direct_simulation(n=1_000_000, burn=10000):
    rng = np.random.default_rng(123)
    u = rng.standard_normal(n+burn)
    e = rng.standard_normal(n+burn)
    z = np.empty(n+burn)
    z[0],h = CENTER,MH
    for t in range(1,len(z)):
        h = MH+RH*(h-MH)+EH*e[t]
        z[t] = CENTER+RP*(z[t-1]-CENTER)+np.exp(h/2)*u[t]
    return stats(z[burn:])


def chain_stats(z,h,s,p,d):
    marginal = d.sum(0)
    mean = marginal@z
    variance = marginal@((z-mean)**2)
    ez_cond_l = p@z
    ez_next = s@ez_cond_l
    covariance = np.sum(d*(z[None,:]-mean)*(ez_next-mean))
    target_mean = CENTER+RP*(z-CENTER)
    cond_var = np.sum(p*(z[None,None,:]-ez_cond_l[:,:,None])**2,axis=2)
    # Future-h/current-z weights for local diagnostics under the stationary chain.
    weights = s.T@d
    mean_error = ez_cond_l-target_mean
    variance_error = cond_var-np.exp(h[:,None])
    return dict(mean_log_price=float(mean),sd_log_price=float(np.sqrt(variance)),
        persistence=float(covariance/variance),
        mean_innovation_variance=float(d.sum(1)@np.exp(h)),
        conditional_mean_rmse=float(np.sqrt(np.sum(weights*mean_error**2))),
        conditional_mean_max_error=float(abs(mean_error).max()),
        conditional_variance_relative_rmse=float(np.sqrt(np.sum(weights*variance_error**2))/INNOVATION_VARIANCE),
        price_boundary_mass=float(d[:,[0,-1]].sum()),
        volatility_boundary_mass=float(d[[0,-1],:].sum()))


def verify_fortran():
    compiler = shutil.which('gfortran')
    if compiler is None:
        raise RuntimeError('gfortran is required for the independent Fortran check')
    z,h,s,p = kernel(17,9)
    with tempfile.TemporaryDirectory(prefix='oil-kernel-') as temp:
        exe = Path(temp)/'check_kernel'
        subprocess.run([compiler,'-std=f2008','-Wall','-Wextra','-fcheck=all',
                        '-ffpe-trap=invalid,zero,overflow',str(ROOT/'price_kernel.f90'),
                        str(ROOT/'check_kernel.f90'),'-o',str(exe)],cwd=temp,check=True)
        request = '\n'.join(['17 9',f'{CENTER} {RP} {MH} {RH} {EH}',
                             ' '.join(map(str,z)),' '.join(map(str,h))])+'\n'
        result = subprocess.run([str(exe)],input=request,text=True,capture_output=True,check=True)
        values = np.loadtxt(io.StringIO(result.stdout))
    error = float(np.max(abs(values-np.r_[s.ravel(),p.ravel()])))
    assert error < 1e-12, error
    return error


def main():
    fortran_error = verify_fortran()
    rows = []
    for nz,nh,zw,hw in [(101,11,6,4.5),(201,21,6,4.5),(401,41,6,4.5),
                         (401,41,4,4.5),(401,41,8,4.5),(401,41,6,5.5)]:
        z,h,s,p = kernel(nz,nh,zw,hw)
        d,iterations = stationary(s,p)
        row = dict(price_nodes=nz,volatility_nodes=nh,price_width_sd=zw,
                   volatility_width_sd=hw,iterations=iterations,**chain_stats(z,h,s,p,d))
        rows.append(row)
        print(json.dumps(row),flush=True)
        if (nz,nh,zw,hw)==(401,41,6,4.5):
            reference = row
            np.savez_compressed(ROOT/'candidate_kernel.npz',log_price=z,log_variance=h,
                                volatility_transition=s,price_transition=p,stationary=d)
    baseline = rows[1]
    sd_change = abs(reference['sd_log_price']/baseline['sd_log_price']-1)
    assert abs(reference['sd_log_price']/Z_SD-1) < .01
    assert abs(reference['persistence']-RP) < .001
    assert sd_change < .01
    assert reference['conditional_mean_rmse'] < .001
    for row in rows[3:]:
        assert abs(row['sd_log_price']/reference['sd_log_price']-1) < .01
    direct = direct_simulation()
    assert abs(direct['sd_log_price']/Z_SD-1) < .03
    assert abs(direct['persistence']-RP) < .002
    results = dict(parameters=dict(center=CENTER,price_persistence=RP,mu_h=MH,rho_h=RH,eta_h=EH),
        analytical=dict(mean_log_price=CENTER,sd_log_price=float(Z_SD),persistence=RP,
                        mean_innovation_variance=float(INNOVATION_VARIANCE)),
        direct_simulation=direct,fortran_max_probability_error=fortran_error,
        grid_checks=rows,checks_passed=True)
    (ROOT/'results.json').write_text(json.dumps(results,indent=2)+'\n')
    with (ROOT/'grid_checks.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)
    print(json.dumps({'direct':direct,'analytical_sd':float(Z_SD),
                      'fortran_error':fortran_error,'checks_passed':True}),flush=True)


if __name__=='__main__':
    main()
