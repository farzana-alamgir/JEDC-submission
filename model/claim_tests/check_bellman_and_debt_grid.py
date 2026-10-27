"""Independent Bellman residual and interpolated-choice audit; no equilibrium re-solve."""
import argparse,json,csv
from pathlib import Path
import numpy as np
from test_claims import number,price_at_debt
from continuous_reference import polynomial_optimum
from gaussian_y import max_value_expectations
ROOT=Path(__file__).resolve().parents[2]
p=argparse.ArgumentParser();p.add_argument('--runs',type=Path,default=ROOT/'results/current_branch_claims/nested/raw');p.add_argument('--output',type=Path,default=ROOT/'results/current_branch_claims/debt_grid_audit');a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
for economy in ['bm','mp']:
 d=a.runs/economy;s=(d/'source.f90').read_text()
 b=np.loadtxt(d/'graphs_b_grid_dss.txt');y=np.loadtxt(d/'graphs_y_grid_dss.txt');h=np.loadtxt(d/'graphs_p_vol_grid_dss.txt');z=np.loadtxt(d/'graphs_p_grid_dss.txt',usecols=0).reshape(len(h),-1)[0]
 continuous='subroutine continuous_debt(n,grid' in s
 if continuous:
  bounds=np.loadtxt(d/'graphs_bounds_dss.txt',max_rows=1);b=np.linspace(bounds[0],bounds[1],len(b))
 shape=(len(h),len(z),len(y),len(b));nb=len(b)
 records=np.loadtxt(d/'graphs_v_dss.txt').reshape(*shape,3)
 val=records[...,0].copy();saved_repay=records[...,1].copy();aut=records[:,:,:,0,2].copy();del records
 q=np.loadtxt(d/'graphs_q_dss.txt').reshape(shape)
 choice=np.loadtxt(d/'graphs_b_next_dss.txt',dtype=int).reshape(shape)-1
 default=np.loadtxt(d/'graphs_default_dss.txt').reshape(shape)>.5
 if continuous:
  saved_bnext=np.loadtxt(d/'graphs_b0_next_dss.txt',usecols=0).reshape(shape)
 ty=np.loadtxt(d/'graphs_trans_matrix_y.txt').reshape(len(y),len(y));th=np.loadtxt(d/'graphs_trans_matrix_p_vol.txt').reshape(len(h),len(h));tp=np.loadtxt(d/'graphs_trans_matrix_p.txt',usecols=0).reshape(len(h),len(z),len(z))
 def finish_expectation(ey):
  ep=np.empty_like(ey)
  for k in range(len(h)):ep[k]=(tp[k]@ey[k].reshape(len(z),-1)).reshape(len(z),len(y),-1)
  return np.einsum('kl,lpib->kpib',th,ep,optimize=True)
 def expected(v):
  if v.ndim==3:v=v[...,None]
  return finish_expectation(np.einsum('ij,vpjb->vpib',ty,v,optimize=True))
 continuous_y='call repayment_hat_weights' in s
 if continuous_y:
  ey,eya=max_value_expectations(saved_repay,aut,y,number(s,'rho'),number(s,'std_eps'))
  ev=finish_expectation(ey);ea=finish_expectation(eya[...,None])[...,0]
 else:
  ev=expected(val);ea=expected(aut)[...,0]
 beta=number(s,'beta');alpha=number(s,'alpha');theta=number(s,'theta');scale=number(s,'scale_y');delta=number(s,'delta');r=number(s,'rstar');coupon=(r+delta)/(1+r);prob=number(s,'prob_excl_end');d0=number(s,'d0');d1=number(s,'d1')
 assert theta==.5 and number(s,'sigma')==2 and 'parameter (oil_disruption = 0d+0)' in s
 # Exact resources at the optimal interior oil input, from the CES first-order condition.
 assert np.exp(z[0])>alpha**2
 resources=(1-alpha)**2*scale*np.exp(y)[None,:]*np.exp(z)[:,None]/(np.exp(z)[:,None]-alpha**2)
 tfp_default=scale*(np.exp(y)-np.maximum(0,d0*np.exp(y)+d1*np.exp(2*y)))
 res_default=(1-alpha)**2*tfp_default[None,:]*np.exp(z)[:,None]/(np.exp(z)[:,None]-alpha**2)
 ba=-1/np.maximum(res_default[None,:,:],1e-10)+beta*(prob*ev[:,:,:,0]+(1-prob)*ea)
 repay=np.empty_like(val);optimal=np.empty_like(choice)
 best_choice_gap=np.empty_like(val)
 for k in range(len(h)):
  for start in range(0,len(z),8):
   stop=min(start+8,len(z))
   c=resources[None,start:stop,:,None,None]-b[None,None,None,:,None]*coupon+q[k:k+1,start:stop,:,None,:]*(b[None,None,None,None,:]-(1-delta)*b[None,None,None,:,None])
   objective=-1/np.maximum(c,1e-10)+beta*ev[k:k+1,start:stop,:,None,:]
   repay[k,start:stop]=np.max(objective,axis=-1)[0]
   optimal[k,start:stop]=np.argmax(objective,axis=-1)[0]
   stored=np.take_along_axis(objective[0],choice[k,start:stop,...,None],axis=-1)[...,0]
   best_choice_gap[k,start:stop]=repay[k,start:stop]-stored
 bv=np.maximum(repay,ba[...,None]);bdefault=ba[...,None]>repay
 policy_report={}
 if continuous:
  chosen_q=price_at_debt(q,saved_bnext,b);chosen_ev=price_at_debt(ev,saved_bnext,b)
  chosen_c=resources[None,:,: ,None]-b[None,None,None,:]*coupon+chosen_q*(saved_bnext-(1-delta)*b[None,None,None,:])
  chosen_value=-1/np.maximum(chosen_c,1e-10)+beta*chosen_ev
  policy_bellman=np.maximum(chosen_value,ba[...,None])
  paid=np.loadtxt(d/'graphs_q_paid_dss.txt').reshape(shape)
  policy_report=dict(full_policy_evaluation_residual_max=float(np.max(abs(policy_bellman-val))),full_repayment_policy_evaluation_residual_max=float(np.max(abs(chosen_value-saved_repay))),full_coarse_choice_lower_bound_violation_max=float(np.max(bv-val)),full_price_at_continuous_choice_identity_error=float(np.max(abs(chosen_q[~default]-paid[~default]))),full_default_decision_regret_max=float(np.max(np.where(default,np.maximum(chosen_value-ba[...,None],0),np.maximum(ba[...,None]-chosen_value,0)))))
 selected=[]
 for factor in [.8,1,1.2]:
  ip=int(np.argmin(abs(z-(.12+np.log(factor)))));selected.extend([ip,int(np.argmin(abs(z-(z[ip]+np.log1p(.1)))))])
 selected=sorted(set(selected));fine=np.linspace(b[0],b[-1],(nb-1)*20+1)
 rows=[]
 for k in [0,2,4]:
  for ip in selected:
   for iy in [int(np.argmin(abs(y-t))) for t in [-.07,0,.07]]:
    qi=np.interp(fine,b,q[k,ip,iy]);ei=np.interp(fine,b,ev[k,ip,iy])
    gross=((1-alpha)*np.sqrt(scale*np.exp(y[iy]))+alpha*(alpha*(1-alpha)*np.sqrt(scale*np.exp(y[iy]))/(np.exp(z[ip])-alpha**2)))**2
    for ratio in [.256,.35,.563]:
     ib=int(np.argmin(abs(b/(4*gross)-ratio)))
     cf=resources[ip,iy]-b[ib]*coupon+qi*(fine-(1-delta)*b[ib])
     vf=-1/np.maximum(cf,1e-10)+beta*ei
     jf=int(np.argmax(vf));coarse=int(optimal[k,ip,iy,ib]);loss=float(vf[jf]-repay[k,ip,iy,ib])
     rows.append(dict(volatility_index=k+1,price=float(np.exp(z[ip])),log_endowment=float(y[iy]),current_debt=float(b[ib]),debt_to_annual_gross_output=float(b[ib]/(4*gross)),coarse_optimal_next_debt=float(b[coarse]),interpolated_optimal_next_debt=float(fine[jf]),next_debt_difference=float(fine[jf]-b[coarse]),repayment_value_gain=loss,coarse_default=bool(bdefault[k,ip,iy,ib]),interpolated_default=bool(ba[k,ip,iy]>vf[jf])))
     if continuous:
      exact_b,exact_v,exact_q=polynomial_optimum(b,q[k,ip,iy],ev[k,ip,iy],resources[ip,iy],b[ib],beta,delta,coupon)
      rows[-1].update(polynomial_optimal_next_debt=exact_b,polynomial_repayment_value=exact_v,stored_next_debt=float(saved_bnext[k,ip,iy,ib]),independent_policy_value_regret=float(exact_v-chosen_value[k,ip,iy,ib]),independent_bellman_residual=float(max(exact_v,ba[k,ip,iy])-val[k,ip,iy,ib]))
 errors=abs(bv-val)
 report=dict(economy=economy,source_runs=str(a.runs.resolve()),status=(d/'solve_status.txt').read_text().strip(),bellman_residual_max=float(errors.max()),bellman_residual_median=float(np.median(errors)),repayment_residual_max=float(np.max(abs(repay-saved_repay))),autarky_residual_max=float(np.max(abs(ba-aut))),default_disagreements=int(np.sum(bdefault!=default)),repayment_choice_value_loss_max=float(np.max(best_choice_gap[~default])),debt_grid_spacing=float(np.diff(b).mean()),off_grid_selected_states=len(rows),off_grid_max_repayment_value_gain=max(r['repayment_value_gain'] for r in rows),off_grid_fraction_different_next_debt=float(np.mean([abs(r['next_debt_difference'])>1e-8 for r in rows])),off_grid_default_changes=sum(r['coarse_default']!=r['interpolated_default'] for r in rows),off_grid_is_equilibrium_solution=False)
 if continuous:
  report['coarse_only_residuals_are_not_continuous_bellman_residuals']=True
  for key in ['bellman_residual_max','bellman_residual_median','repayment_residual_max','default_disagreements','repayment_choice_value_loss_max']:
   report['coarse_grid_comparison_'+key]=report.pop(key)
  report.update(policy_report)
  report['selected_max_polynomial_policy_value_regret']=max(r['independent_policy_value_regret']for r in rows)
  report['selected_max_absolute_polynomial_bellman_residual']=max(abs(r['independent_bellman_residual'])for r in rows)
 (a.output/(economy+'_bellman_and_debt_grid.json')).write_text(json.dumps(report,indent=2)+'\n')
 with (a.output/(economy+'_interpolated_choice_audit.csv')).open('w',newline='') as f:w=csv.DictWriter(f,fieldnames=rows[0]);w.writeheader();w.writerows(rows)
 print(json.dumps(report),flush=True)
