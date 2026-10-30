"""Physical-price transition audit; no sovereign solution or calibration edits.

Compare original Rouwenhorst index switching with physical Gaussian cell
transitions on seven-node regime-specific supports and finer fixed supports.
The Gaussian nearest-cell method is a candidate, not the moment-matched
549-node solver kernel. Its results cannot select a grid for economic claims.
"""
from pathlib import Path
import csv,json,math
import numpy as np
from test_claims import number,digest
from gaussian_y import interval_moments

ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'model/oil_prod_CES.f90'
OUT=ROOT/'results/current_branch_claims/small_grid_audit'
OUT.mkdir(parents=True,exist_ok=True)
s=SOURCE.read_text()
mu,rho,muh,rh,eta=[number(s,k) for k in ['mean_p','rho_p','mean_p_vol','rho_p_vol','eta']]
h=muh+np.linspace(-2,2,5)*eta/np.sqrt(1-rh**2)
sd=np.exp(h/2);v0=np.exp(muh+.5*eta**2/(1-rh**2))
uncond=np.sqrt(v0/(1-rho*rho));width=number(s,'p_width_sd')
threshold=number(s,'alpha')**(1/number(s,'theta'))
erfc=np.vectorize(math.erfc,otypes=[float])
def cells(dest,loc,sigma):
    bounds=np.r_[-1e100,(dest[:-1]+dest[1:])/2,1e100]
    prob,_=interval_moments(bounds[:-1],bounds[1:],loc,sigma)
    assert abs(prob.sum()-1)<2e-14 and prob.min()>=0
    return prob
def rouwenhorst(n,r):
    p=(1+r)/2;mat=np.array([[p,1-p],[1-p,p]])
    for size in range(3,n+1):
        a=np.zeros((size,size))
        a[:-1,:-1]+=p*mat;a[:-1,1:]+=(1-p)*mat
        a[1:,:-1]+=(1-p)*mat;a[1:,1:]+=p*mat
        a[1:-1]/=2;mat=a
    return mat

# Original seven-node Rouwenhorst supports, using the corrected log-variance
# convention. Preserve THESE bounds for refinement; changing sqrt(n-1) with
# n would confound support expansion with resolution.
half=np.sqrt(6)*sd/np.sqrt(1-rho*rho)
native7=mu+np.linspace(-1,1,7)[None,:]*half[:,None]
R=rouwenhorst(7,rho)
assert np.max(abs(R@np.arange(7)-(3+rho*(np.arange(7)-3))))<1e-13
for g,sigma in zip(native7,sd):
    m=R@g
    assert np.max(abs(m-(mu+rho*(g-mu))))<1e-13
    assert np.max(abs(R@(g*g)-m*m-sigma*sigma))<1e-13
examples=[]
for current in [0,2,4]:
    for future in [0,2,4]:
        z=mu+np.log(1.1)
        index=(z-native7[current,0])/(native7[current,1]-native7[current,0])
        lo=int(np.floor(index));f=index-lo
        row=(1-f)*R[lo]+f*R[lo+1]
        got=float(row@native7[future]);target=mu+rho*(z-mu)
        analytic=mu+rho*sd[future]/sd[current]*(z-mu)
        assert abs(got-analytic)<1e-13
        examples.append(dict(current_vol=current+1,future_vol=future+1,
            current_price=float(np.exp(z)),original_expected_log_price=got,
            intended_expected_log_price=float(target),log_mean_error=float(got-target)))

rows=[]
# Identical physical evaluation prices, not identical node indices.
test_z=mu+np.log(np.array([.8,1.,1.2]))
for scheme in ['common_support','original_regime_specific_support']:
    for n in [7,15,31,61,121,241,549]:
        grids=(np.tile(mu+np.linspace(-width*uncond,width*uncond,n),(5,1))
               if scheme=='common_support' else mu+np.linspace(-1,1,n)[None,:]*half[:,None])
        for economy in ['bm','mp']:
            mean_errors=[];var_errors=[];mp_means=[];moves=[];infeasible=0;max_floor_ratio=0.
            for z in test_z:
                level_means=[]
                for future in range(5):
                    drift=-.5*(sd[future]**2-v0) if economy=='mp' else 0.
                    loc=mu+rho*(z-mu)+drift;g=grids[future]
                    # Distribution-free bound: any probabilities on this grid
                    # with mean loc have variance at least (loc-L)*(U-loc),
                    # where L,U are adjacent nodes enclosing loc.
                    upper=int(np.searchsorted(g,loc,side='right'))
                    if upper==0 or upper==len(g):
                        infeasible+=1
                    else:
                        floor=(loc-g[upper-1])*(g[upper]-loc)
                        ratio=float(floor/sd[future]**2)
                        max_floor_ratio=max(max_floor_ratio,ratio)
                        infeasible+=int(ratio>1+1e-12)
                    q=cells(g,loc,sd[future]);ml=float(q@g)
                    vl=float(q@((g-ml)**2));mp=float(q@np.exp(g))
                    target=math.exp(loc+.5*sd[future]**2)
                    mean_errors.append(abs(mp/target-1));var_errors.append(abs(vl/sd[future]**2-1))
                    level_means.append(mp)
                    if abs(z-mu)<1e-12:moves.append(1-float(q[np.argmin(abs(g-mu))]))
                mp_means.append(np.ptp(level_means)/np.mean(level_means))
            rows.append(dict(scheme=scheme,economy=economy,nodes_per_vol=n,
                minimum_price=float(np.exp(grids.min())),maximum_price=float(np.exp(grids.max())),
                nodes_at_or_below_CES_threshold=int(np.sum(np.exp(grids)<=threshold)),
                max_relative_level_mean_error_at_test_prices=max(mean_errors),
                infeasible_log_mean_variance_targets_out_of_15=infeasible,
                max_minimum_attainable_log_variance_over_target=max_floor_ratio,
                max_relative_log_variance_error_at_test_prices=max(var_errors),
                max_level_mean_range_across_future_vol_at_test_prices=max(mp_means),
                lowest_vol_probability_leave_center=moves[0],
                minimum_conditional_sd_over_spacing=float(np.min(sd/np.diff(grids,axis=1)[:,0]))))
with (OUT/'resolution_comparison.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
report=dict(source=str(SOURCE),source_sha256=digest(SOURCE),equilibrium_solved=False,
    method='Gaussian nearest-cell transitions from actual physical current price; fixed supports across refinements',
    parameters=dict(mu=mu,rho=rho,mu_h=muh,rho_h=rh,eta_h=eta),
    physical_test_prices=np.exp(test_z).tolist(),ces_threshold=threshold,
    original_seven_node_price_ranges=[[float(np.exp(g[0])),float(np.exp(g[-1]))]for g in native7],
    original_index_switch_examples=examples,comparisons=rows,
    limitations=['No amplification or borrowing claim tested here.',
      'Candidate cell probabilities do not use the solver moment-matching or level-mean tilt.',
      'Conditional moments are evaluated directly at identical physical prices; interpolated value-function accuracy needs a solved-model refinement test.',
      'Regime-specific Gaussian transitions require a kernel indexed by both current and future volatility when stored at current nodes.',
      'The original seven-node support reaches below the finite-oil-input CES threshold under corrected volatility.'])
(OUT/'audit.json').write_text(json.dumps(report,indent=2)+'\n')
for row in rows:
    if row['economy']=='mp' and row['nodes_per_vol'] in [7,61,549]:print(row,flush=True)
print('Wrote',OUT,flush=True)
