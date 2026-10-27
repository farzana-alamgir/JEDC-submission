"""Compare continuous-law moments on identical nodes before/after kernel extension."""
import json
from pathlib import Path
import numpy as np
from test_claims import number
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'results/current_branch_claims/upper_boundary_extension'
reports=[]
for e in ['bm','mp']:
 result={'economy':e,'equilibrium_solved':False}
 for label,root in [('original',ROOT/'results/current_branch_claims/nested/raw'),('extended',out/'raw')]:
  d=root/e;src=(d/'source.f90').read_text();h=np.loadtxt(d/'graphs_p_vol_grid_dss.txt');z=np.loadtxt(d/'graphs_p_grid_dss.txt',usecols=0).reshape(len(h),-1)[0];p=np.loadtxt(d/'graphs_trans_matrix_p.txt',usecols=0).reshape(len(h),len(z),len(z));s=np.loadtxt(d/'graphs_trans_matrix_p_vol.txt').reshape(len(h),len(h))
  rho=number(src,'rho_p');mu=number(src,'mean_p');rh=number(src,'rho_p_vol');eta=number(src,'eta');muh=number(src,'mean_p_vol');v0=np.exp(muh+.5*eta**2/(1-rh**2));v=np.exp(h);drift=-.5*(v-v0) if e=='mp' else np.zeros(len(h));target=np.exp((1-rho)*mu+rho*z[None,:]+drift[:,None]+.5*v[:,None]);level=p@np.exp(z);cross=s@level
  result[label]=dict(price_nodes=len(z),lower_price=float(np.exp(z[0])),upper_price=float(np.exp(z[-1])),relative_mean_error_at_original_upper_by_future_vol=(level[:,548]/target[:,548]-1).tolist(),max_absolute_relative_mean_error_at_original_upper=float(np.max(abs(level[:,548]/target[:,548]-1))),mean_range_at_original_upper_across_current_vol_relative=float(np.ptp(cross[:,548])/np.mean(cross[:,548])),max_absolute_relative_mean_error_at_original_lower=float(np.max(abs(level[:,0]/target[:,0]-1))))
 reports.append(result)
(out/'comparison.json').write_text(json.dumps(reports,indent=2)+'\n');print(json.dumps(reports,indent=2))
