"""Audit saved price kernels against the continuous Gaussian laws at every node."""
import math,json
from pathlib import Path
import numpy as np
from test_claims import number
ROOT=Path(__file__).resolve().parents[2]
root=ROOT/'results/current_branch_claims/nested'
out=ROOT/'results/current_branch_claims/boundary_audit';out.mkdir(exist_ok=True)
for e in ['bm','mp']:
 d=root/'raw'/e;source=(d/'source.f90').read_text()
 h=np.loadtxt(d/'graphs_p_vol_grid_dss.txt')
 z=np.loadtxt(d/'graphs_p_grid_dss.txt',usecols=0).reshape(len(h),-1)[0]
 p=np.loadtxt(d/'graphs_trans_matrix_p.txt',usecols=0).reshape(len(h),len(z),len(z))
 s=np.loadtxt(d/'graphs_trans_matrix_p_vol.txt').reshape(len(h),len(h))
 rho=number(source,'rho_p');mu=number(source,'mean_p');eta=number(source,'eta');rh=number(source,'rho_p_vol');muh=number(source,'mean_p_vol')
 v0=np.exp(muh+.5*eta**2/(1-rh**2));v=np.exp(h)
 drift= -.5*(v-v0) if e=='mp' else np.zeros(len(h))
 target=(1-rho)*mu+rho*z[None,:]+drift[:,None]
 level_target=np.exp(target+.5*v[:,None])
 m=p@z;variance=p@(z*z)-m*m
 level=p@np.exp(z)
 erel=level/level_target-1
 worst_v,worst_p=np.unravel_index(np.argmax(abs(erel)),erel.shape)
 cdf=np.vectorize(lambda x:.5*math.erfc(-float(x)/math.sqrt(2)))
 tail_lo=cdf((z[0]-target)/np.sqrt(v[:,None]))
 tail_hi=cdf((target-z[-1])/np.sqrt(v[:,None]))
 # Correct timing: transition volatility first, then price conditional on future volatility.
 pi=np.full((len(h),len(z)),1/(len(h)*len(z)))
 for it in range(10000):
  mixed=s.T@pi
  nxt=np.array([mixed[l]@p[l] for l in range(len(h))])
  gap=np.max(abs(nxt-pi));pi=nxt
  if gap<1e-14:break
 assert gap<1e-14
 # Row diagnostics indexed by current volatility require averaging over future volatility.
 continuous_level=s@level_target;discrete_level=s@level
 mp_range=np.ptp(discrete_level,axis=0)/np.mean(discrete_level,axis=0)
 interior=(z>=mu+np.log(.8))&(z<=mu+np.log(1.5))
 rows=[]
 for ip in [0,1,len(z)//2,len(z)-2,len(z)-1]:
  rows.append(dict(price=float(np.exp(z[ip])),log_price=float(z[ip]),stationary_probability=float(pi[:,ip].sum()),level_mean_relative_errors_by_future_vol=erel[:,ip].tolist(),outside_support_probability_by_future_vol=(tail_lo+tail_hi)[:,ip].tolist(),conditional_level_mean_range_across_current_vol_relative=float(mp_range[ip])))
 report=dict(economy=e,stationary_iterations=it+1,stationary_error=float(gap),row_sum_error=float(np.max(abs(p.sum(axis=2)-1))),max_log_mean_error=float(np.max(abs(m-target))),max_log_variance_error=float(np.max(abs(variance-v[:,None]))),max_level_mean_relative_error=float(np.max(abs(erel))),max_interior_level_mean_relative_error=float(np.max(abs(erel[:,interior]))),stationary_probability_at_endpoints=float(pi[:,[0,-1]].sum()),stationary_probability_outer_5_percent_nodes=float(pi[:,np.r_[0:28,len(z)-28:len(z)]].sum()),stationary_weighted_outside_support_probability=float(np.sum(pi*(s@(tail_lo+tail_hi)))),mp_interior_conditional_level_mean_range=float(np.max(mp_range[interior])) if e=='mp' else None,endpoint_examples=rows)
 report.update(moment_comparison_tolerance=1e-8,rows_missing_log_moment_targets=int(np.sum((abs(m-target)>1e-8)|(abs(variance-v[:,None])>1e-8))),total_rows=int(len(h)*len(z)),worst_level_error_location=dict(future_volatility_index=int(worst_v+1),price=float(np.exp(z[worst_p]))),stationary_weighted_absolute_level_mean_relative_error=float(np.sum(pi*(s@abs(erel)))))
 (out/(e+'_boundary_audit.json')).write_text(json.dumps(report,indent=2)+'\n')
 np.savez_compressed(out/(e+'_stationary_price_volatility.npz'),stationary=pi,z=z,h=h)
 print(e,{k:v for k,v in report.items() if k!='endpoint_examples'},flush=True)
