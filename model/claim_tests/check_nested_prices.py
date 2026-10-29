"""Independently check the complete saved zero-profit equation, including location."""
from pathlib import Path
import argparse,json
import numpy as np
from test_claims import number,price_at_debt
from gaussian_y import repay_payoff_expectations
parser=argparse.ArgumentParser()
parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[2]/'results/current_branch_claims/nested')
root=parser.parse_args().root.resolve()
for economy in ['bm','mp']:
 d=root/'raw'/economy
 assert (d/'solve_status.txt').exists(),'Wait for solver output to finish'
 source=(d/'source.f90').read_text();r=number(source,'rstar');delta=number(source,'delta');coupon=(r+delta)/(1+r)
 b=np.loadtxt(d/'graphs_b_grid_dss.txt');y=np.loadtxt(d/'graphs_y_grid_dss.txt');h=np.loadtxt(d/'graphs_p_vol_grid_dss.txt')
 z=np.loadtxt(d/'graphs_p_grid_dss.txt',usecols=0).reshape(len(h),-1)[0]
 shape=(len(h),len(z),len(y),len(b))
 q=np.loadtxt(d/'graphs_q_dss.txt').reshape(shape)
 paid=np.loadtxt(d/'graphs_q_paid_dss.txt').reshape(shape)
 default=np.loadtxt(d/'graphs_default_dss.txt').reshape(shape)>.5
 ty=np.loadtxt(d/'graphs_trans_matrix_y.txt').reshape(len(y),len(y))
 th=np.loadtxt(d/'graphs_trans_matrix_p_vol.txt').reshape(len(h),len(h))
 tp=np.loadtxt(d/'graphs_trans_matrix_p.txt',usecols=0).reshape(len(h),len(z),len(z))
 continuous_y='call repayment_hat_weights' in source
 if continuous_y:
  bounds=np.loadtxt(d/'graphs_bounds_dss.txt',max_rows=1);b=np.linspace(bounds[0],bounds[1],len(b))
  policy=np.loadtxt(d/'graphs_b0_next_dss.txt',usecols=0).reshape(shape)
  vrecords=np.loadtxt(d/'graphs_v_dss.txt').reshape(*shape,3)
  vr=vrecords[...,1].copy();va=vrecords[:,:,:,0,2].copy();del vrecords
  conditional=price_at_debt(q,policy,b)
  pay=(coupon+(1-delta)*conditional)*np.exp(-r)
  ey=repay_payoff_expectations(vr,va,pay,y,number(source,'rho'),number(source,'std_eps'))
 else:
  pay=(~default)*(coupon+(1-delta)*paid)*np.exp(-r)
  ey=np.einsum('ij,vpjb->vpib',ty,pay,optimize=True)
 ep=np.empty_like(ey)
 for v in range(len(h)):
  ep[v]=(tp[v]@ey[v].reshape(len(z),-1)).reshape(len(z),len(y),len(b))
 fresh=np.einsum('kl,lpib->kpib',th,ep,optimize=True)
 error=np.abs(fresh-q)
 points=[]
 for flat in np.argpartition(error.ravel(),-10)[-10:][np.argsort(error.ravel()[np.argpartition(error.ravel(),-10)[-10:]])[::-1]]:
  v,p,i,j=np.unravel_index(flat,shape)
  points.append(dict(volatility_index=int(v+1),price=float(np.exp(z[p])),log_endowment=float(y[i]),proposed_debt=float(b[j]),stored_price=float(q[v,p,i,j]),equation_price=float(fresh[v,p,i,j]),absolute_residual=float(error[v,p,i,j])))
 report=dict(status=(d/'solve_status.txt').read_text().strip(),continuous_y_cutoff_integration=continuous_y,maximum=float(error.max()),median=float(np.median(error)),percentile_99=float(np.quantile(error,.99)),fraction_above_1e_6=float(np.mean(error>1e-6)),worst_locations=points)
 (root/(economy+'_independent_pricing_check.json')).write_text(json.dumps(report,indent=2)+'\n')
 print(economy,{k:v for k,v in report.items() if k!='worst_locations'},flush=True)
