"""Adaptive fixed-price Bellman iteration, with optional uniform-value correction."""
import argparse, difflib, hashlib, json, subprocess
from pathlib import Path
from solve_current_branch import prepare, replace_once, ROOT
p=argparse.ArgumentParser()
p.add_argument('economy',choices=['bm','mp'])
p.add_argument('--max-iterations',type=int,default=1200)
p.add_argument('--output-root',type=Path,default=ROOT/'results/current_branch_claims/adaptive_nested')
p.add_argument('--warm-runs',type=Path,default=ROOT/'results/current_branch_claims/nested/raw')
p.add_argument('--relative-values',action='store_true')
p.add_argument('--fixed-price-validation',action='store_true')
p.add_argument('--continuous-debt',action='store_true')
p.add_argument('--parallel-controls',action='store_true',help='Compute independent continuous-control problems with OpenMP')
p.add_argument('--price-relaxation',type=float,default=.1)
p.add_argument('--tolerance',type=float,default=1e-6)
p.add_argument('--level-mean-kernels',type=Path,help='Directory of audited alternative finite-support kernels')
p.add_argument('--policy-pricing',action='store_true',help='Solve the long-bond linear system for fixed borrowing/default policies')
p.add_argument('--continuous-y',action='store_true',help='Integrate repayment cutoffs between Gaussian endowment nodes')
p.add_argument('--howard-evaluations',type=int,default=0)
p.add_argument('--stall-window',type=int,default=0,help='Save and stop after this many pricing updates without a 5 percent best-residual improvement')
a=p.parse_args()
a.output_root=a.output_root.resolve()
a.warm_runs=a.warm_runs.resolve()
if a.howard_evaluations:
 assert a.continuous_y and not a.relative_values
assert 0<=a.price_relaxation<1
d=prepare(a.economy,a.max_iterations,a.tolerance,True,a.output_root,a.warm_runs,a.price_relaxation)
s=(d/'source.f90').read_text()
s=replace_once(s,'INTEGER :: changes_d, changes_b','INTEGER :: changes_d, changes_b, inner_steps=0, outer_steps=0\nlogical :: update_prices=.true.\nDOUBLE PRECISION :: previous_bellman=1d0, inner_tolerance=1d-6, value_shift')
trigger='(counter == 1)' if a.fixed_price_validation else '(counter == 1 .or. previous_bellman < inner_tolerance .or. inner_steps >= 200)'
s=replace_once(s,'   old_d = default_decision',f'   update_prices = {trigger}\n   if (update_prices) then\n      outer_steps=outer_steps+1\n      inner_steps=0\n   end if\n   inner_steps=inner_steps+1\n   old_d = default_decision')
# precompute still computes expectations each sweep; freeze only price schedule.
weight=f'{a.price_relaxation:.12e}'.replace('e','d')
update=f'q_fun_matrix=(1d0-{weight})*q_schedule_old+{weight}*q_fun_matrix'
s=replace_once(s,update, 'if (update_prices) then\n'+update+'\nelse\nq_fun_matrix=q_schedule_old\nend if')
# update_prices must be module-visible, not local.
s=s.replace('logical :: update_prices=.true.\n','')
s=replace_once(s,'DOUBLE PRECISION :: q_schedule_old','logical :: update_prices=.true.\nDOUBLE PRECISION :: q_schedule_old')
s=replace_once(s,'   changes_d = count(default_decision /= old_d)','   previous_bellman=deviation\n   inner_tolerance=max(1d-10,min(1d-6,1d-3*raw_schedule_residual))\n   changes_d = count(default_decision /= old_d)')
# Frozen-price sweeps need value expectations only. Recompute lender prices
# before accepting convergence; the frozen-sweep diagnostic retains the last
# measured outer residual, not a fresh measurement.
s=replace_once(s,'! --- Bond price: the same contraction applied to the survival-weighted payoff ---','if (update_prices) then\n! --- Bond price: the same contraction applied to the survival-weighted payoff ---')
s=replace_once(s,'! Same default-free recursion, factored over y\', p\', h\'.','end if\n! Same default-free recursion, factored over y\', p\', h\'.')
s=replace_once(s,'end if\n! Same default-free recursion', 'end if\ncoup_const=(rstar+delta)/(1d0+rstar)\n! Same default-free recursion')
s=replace_once(s,'raw_schedule_residual=maxval(abs(q_fun_matrix-q_schedule_old))','if (update_prices) raw_schedule_residual=maxval(abs(q_fun_matrix-q_schedule_old))')
s=s.replace('changes_b == 0 .and. raw_schedule_residual < criteria','changes_b == 0 .and. raw_schedule_residual < criteria .and. update_prices')
if a.relative_values:
 s=replace_once(s,'inner_tolerance=1d-6, value_shift','inner_tolerance=1d-6, value_shift, bellman_bound')
 s=replace_once(s,'    !UPDATE VALUES OF MATRICES', '''    ! A common additive shift preserves every policy comparison at fixed prices.
    ! B(V+c)=B(V)+beta*c. Remove the anchor's uniform value-error component.
    value_shift=v_matrix_new(1,11,275,3)-v_matrix(1,11,275,3)
    bellman_bound=beta*max(maxval(abs(v_matrix_new-v_matrix-value_shift)), &
                         maxval(abs(v1_matrix_new-v1_matrix-value_shift)))
    open(719,file='bellman_bound.csv',position='append')
    write(719,*)counter,bellman_bound
    close(719)
    value_shift=beta/(1d0-beta)*(v_matrix_new(1,11,275,3)-v_matrix(1,11,275,3))
    v_matrix_new=v_matrix_new+value_shift
    v0_matrix_new=v0_matrix_new+value_shift
    v1_matrix_new=v1_matrix_new+value_shift
    !UPDATE VALUES OF MATRICES''')
 s=s.replace('changes_b == 0 .and. raw_schedule_residual < criteria','changes_b == 0 .and. bellman_bound < criteria .and. raw_schedule_residual < criteria')
if a.continuous_debt:
 s=replace_once(s,'logical :: update_prices=.true.\nDOUBLE PRECISION :: q_schedule_old','DOUBLE PRECISION :: continuous_b_choice,continuous_q_choice\nlogical :: update_prices=.true.\nDOUBLE PRECISION :: q_schedule_old')
 s=replace_once(s,'DOUBLE PRECISION :: previous_bellman=1d0, inner_tolerance=1d-6, value_shift','DOUBLE PRECISION :: previous_bellman=1d0, inner_tolerance=1d-6, value_shift, continuous_change\nDOUBLE PRECISION :: old_continuous_b(b_num,y_num,p_num,p_vol_num)')
 s=replace_once(s,'   old_b = b_next_matrix','   old_b = b_next_matrix\n   old_continuous_b=b0_next_matrix')
 start=s.index('subroutine optimize(index_opt, v_value)')
 end=s.index('end subroutine optimize',start)+len('end subroutine optimize')
 s=s[:start]+'''subroutine optimize(index_opt,v_value)
use param
integer::index_opt,index_vector(1)
double precision::v_value,resources_opt,tfp_opt,price_opt
tfp_opt=scale_y*exp(y_initial)
price_opt=exp(p_initial)
if(theta/=0.5d0.or.sigma/=2d0)error stop 'Continuous optimizer requires theta=.5 and utility gamma=2'
if(price_opt<=alpha**2)error stop 'No finite oil-input optimum'
resources_opt=(1d0-alpha)**2*tfp_opt*price_opt/(price_opt-alpha**2)
call continuous_debt(b_num,b_grid,q_vector,exp_v_vector,resources_opt,b_initial,beta,delta,coupon, &
continuous_b_choice,v_value,continuous_q_choice)
index_vector=minloc(abs(b_grid-continuous_b_choice));index_opt=index_vector(1)
i_b_next=b_num
end subroutine optimize'''+s[end:]
 s=replace_once(s,'b0_next_matrix(i_b, i_y, i_p, i_p_vol) = b_grid(i_b_optimal0)','b0_next_matrix(i_b, i_y, i_p, i_p_vol) = continuous_b_choice')
 s=replace_once(s,'(b_grid(i_b_optimal0)-&\n               (1d+0 - delta)*b_initial)* q_fun_matrix(i_b_optimal0, i_y,i_p,i_p_vol)', '(continuous_b_choice-&\n               (1d+0 - delta)*b_initial)* continuous_q_choice')
 s=replace_once(s,'q_paid_matrix_new(i_b, i_y,i_p, i_p_vol) =  q_fun_matrix(i_b_optimal0, i_y,i_p, i_p_vol)','q_paid_matrix_new(i_b, i_y,i_p, i_p_vol) = continuous_q_choice')
 s=replace_once(s,'   previous_bellman=deviation','   continuous_change=maxval(abs(b0_next_matrix-old_continuous_b),mask=default_decision==1)\n   open(717,file="continuous_debt_change.csv",position="append")\n   write(717,*)counter,continuous_change\n   close(717)\n   previous_bellman=deviation')
 s=s.replace('changes_b == 0 .and.','changes_b == 0 .and. continuous_change < criteria .and.')
 s=replace_once(s,'call iterate\n','''do i_p_vol=1,p_vol_num
do i_p=1,p_num
do i_y=1,y_num
do i_b=1,b_num
b0_next_matrix(i_b,i_y,i_p,i_p_vol)=b_grid(b_next_matrix(i_b,i_y,i_p,i_p_vol))
end do
end do
end do
end do
call iterate
''')
 s+='\n'+(ROOT/'model/claim_tests/continuous_debt.f90').read_text()
 if a.parallel_controls:
  s=replace_once(s,'DOUBLE PRECISION, EXTERNAL:: q_fun, objective_function, q_def_free_fun','DOUBLE PRECISION, EXTERNAL:: q_fun, objective_function, q_def_free_fun\nSAVE')
  s=replace_once(s,'DOUBLE PRECISION :: continuous_b_choice,continuous_q_choice','DOUBLE PRECISION :: continuous_b_choice,continuous_q_choice\nINTEGER :: continuous_ip,continuous_iv\nDOUBLE PRECISION :: control_b(b_num,y_num,p_num,p_vol_num),control_v(b_num,y_num,p_num,p_vol_num),control_q(b_num,y_num,p_num,p_vol_num)')
  s=replace_once(s,'call precompute_expectations\n','call precompute_expectations\ncall build_continuous_controls\n')
  s=replace_once(s,'      p_initial=p_grid(i_p,i_p_vol)','      p_initial=p_grid(i_p,i_p_vol)\n      continuous_ip=i_p\n      continuous_iv=i_p_vol')
  s=replace_once(s,'''call continuous_debt(b_num,b_grid,q_vector,exp_v_vector,resources_opt,b_initial,beta,delta,coupon, &
continuous_b_choice,v_value,continuous_q_choice)''','''continuous_b_choice=control_b(i_b_global,i_y_global,continuous_ip,continuous_iv)
v_value=control_v(i_b_global,i_y_global,continuous_ip,continuous_iv)
continuous_q_choice=control_q(i_b_global,i_y_global,continuous_ip,continuous_iv)''')
  s+='''
subroutine build_continuous_controls
use param
implicit none
integer::iv,ip,iy,ib
double precision::price_local,resources_local
!$omp parallel do collapse(3) default(shared) private(iv,ip,iy,ib,price_local,resources_local) schedule(static)
do iv=1,p_vol_num
do ip=1,p_num
do iy=1,y_num
 price_local=exp(p_grid(ip,iv))
 resources_local=(1d0-alpha)**2*scale_y*exp(y_grid(iy))*price_local/(price_local-alpha**2)
 do ib=1,b_num
  call continuous_debt(b_num,b_grid,q_fun_matrix(:,iy,ip,iv),exp_v_matrix(:,iy,ip,iv), &
  resources_local,b_grid(ib),beta,delta,coupon,control_b(ib,iy,ip,iv),control_v(ib,iy,ip,iv),control_q(ib,iy,ip,iv))
 end do
end do
end do
end do
!$omp end parallel do
end subroutine build_continuous_controls
'''
s=replace_once(s,"   close(714)","   close(714)\n   open(715,file='nested_history.csv',position='append')\n   write(715,*) counter,outer_steps,inner_steps,update_prices,deviation,raw_schedule_residual\n   close(715)\n   open(716,file='switching_states.txt',status='replace')\n   do i_p_vol=1,p_vol_num\n   do i_p=1,p_num\n   do i_y=1,y_num\n   do i_b=1,b_num\n      if (default_decision(i_b,i_y,i_p,i_p_vol) /= old_d(i_b,i_y,i_p,i_p_vol)) &\n      write(716,*) i_b,i_y,i_p,i_p_vol,b_grid(i_b),y_grid(i_y),p_grid(i_p,i_p_vol), &\n      v0_matrix_new(i_b,i_y,i_p,i_p_vol)-v1_matrix_new(i_y,i_p,i_p_vol), &\n      old_d(i_b,i_y,i_p,i_p_vol),default_decision(i_b,i_y,i_p,i_p_vol)\n   end do\n   end do\n   end do\n   end do\n   close(716)")
if a.policy_pricing:
 import shutil
 assert a.continuous_debt
 shutil.copyfile(a.warm_runs/a.economy/'graphs_b0_next_dss.txt',d/'graphs_b0_next_dss.txt')
 s=replace_once(s,"      open (713, FILE='graphs_q_dss.txt')", "      open (713, FILE='graphs_q_dss.txt')\n      open (720, FILE='graphs_b0_next_dss.txt')")
 s=replace_once(s,'               READ(713, *) q_schedule_old(i_b,i_y,i_p,i_p_vol)', '               READ(713, *) q_schedule_old(i_b,i_y,i_p,i_p_vol)\n               READ(720,*) b0_next_matrix(i_b,i_y,i_p,i_p_vol)')
 s=replace_once(s,'   close(713)','   close(713)\n   close(720)')
 initial='''do i_p_vol=1,p_vol_num
do i_p=1,p_num
do i_y=1,y_num
do i_b=1,b_num
b0_next_matrix(i_b,i_y,i_p,i_p_vol)=b_grid(b_next_matrix(i_b,i_y,i_p,i_p_vol))
end do
end do
end do
end do
call iterate'''
 s=replace_once(s,initial,'call iterate')
 s=replace_once(s,'\nSUBROUTINE precompute_expectations\n','\nSUBROUTINE precompute_expectations\nUSE fixed_policy_pricing, only:solve_fixed_policy_prices\n')
 s=replace_once(s,'logical :: update_prices=.true.','DOUBLE PRECISION :: policy_inner_residual\nINTEGER :: policy_price_iterations\nLOGICAL :: policy_price_success=.false.\nlogical :: update_prices=.true.')
 s=replace_once(s,'if (update_prices) then\n! --- Bond price:', 'if (.false.) then\n! --- Bond price:')
 s=replace_once(s,'if (update_prices) raw_schedule_residual=maxval(abs(q_fun_matrix-q_schedule_old))','''if(update_prices)then
 call solve_fixed_policy_prices(b_num,y_num,p_num,p_vol_num,b_grid,b0_next_matrix,default_decision, &
 trans_matrix,trans_matrix_p,trans_matrix_p_vol,q_schedule_old,coup_const,exp(-rstar),1d0-delta,1d-10, &
 q_fun_matrix,raw_schedule_residual,policy_inner_residual,policy_price_iterations,policy_price_success)
 open(721,file='fixed_policy_pricing.csv',position='append')
 write(721,*)counter,policy_price_iterations,raw_schedule_residual,policy_inner_residual,policy_price_success
 close(721)
end if''')
 s=s.replace('.and. update_prices)', '.and. policy_price_success .and. update_prices)')
 s=(ROOT/'model/claim_tests/fixed_policy_pricing.f90').read_text()+'\n'+s
if a.continuous_y:
 assert a.policy_pricing and a.continuous_debt
 s=replace_once(s,'logical :: update_prices=.true.','DOUBLE PRECISION, ALLOCATABLE :: repay_y_weights(:,:,:,:,:)\nDOUBLE PRECISION :: y_hat(y_num,y_num),y_wleft(y_num,y_num-1),y_wright(y_num,y_num-1),y_lower(y_num),y_upper(y_num)\nlogical :: update_prices=.true.')
 s=replace_once(s,'USE fixed_policy_pricing, only:solve_fixed_policy_prices','USE fixed_policy_pricing, only:solve_fixed_policy_prices\nUSE continuous_y_quadrature, only:gaussian_weight_tables,repayment_hat_weights')
 marker='! --- Step 1: contract over next-period endowment ---'
 s=replace_once(s,marker,'''if(.not.allocated(repay_y_weights))then
 allocate(repay_y_weights(b_num,y_num,y_num,p_num,p_vol_num))
 call gaussian_weight_tables(y_num,y_grid,rho,std_eps,0d0,y_hat,y_wleft,y_wright,y_lower,y_upper)
 open(722,file='y_gaussian_hat_weights.txt',status='replace')
 do iy=1,y_num
  write(722,*)y_hat(iy,:)
 end do
 close(722)
end if
call repayment_hat_weights(b_num,y_num,p_num,p_vol_num,y_grid,rho,std_eps,0d0,v0_matrix,v1_matrix, &
y_hat,y_wleft,y_wright,y_lower,y_upper,repay_y_weights)
'''+marker)
 start=s.index(marker);end=s.index('! --- Step 2:',start)
 section=s[start:end]
 section=replace_once(section,'w = trans_matrix(iy, iyn)','w = y_hat(iy, iyn)')
 section=replace_once(section,'+ w * v_matrix(:, iyn, ipn, ivn)', '''+ repay_y_weights(:,iy,iyn,ipn,ivn)*v0_matrix(:,iyn,ipn,ivn) &
                 + (w-repay_y_weights(:,iy,iyn,ipn,ivn))*v1_matrix(iyn,ipn,ivn)''')
 s=s[:start]+section+s[end:]
 s=replace_once(s,'q_fun_matrix,raw_schedule_residual,policy_inner_residual,policy_price_iterations,policy_price_success)', 'q_fun_matrix,raw_schedule_residual,policy_inner_residual,policy_price_iterations,policy_price_success,repay_y_weights)')
 s=replace_once(s,'   previous_bellman=deviation','   deviation=max(deviation,maxval(abs(v0_matrix_new-v0_matrix)),maxval(abs(v1_matrix_new-v1_matrix)))\n   previous_bellman=deviation')
 if a.relative_values:
  s=replace_once(s,'bellman_bound=beta*max(maxval(abs(v_matrix_new-v_matrix-value_shift)), &', 'bellman_bound=beta*max(maxval(abs(v_matrix_new-v_matrix-value_shift)),maxval(abs(v0_matrix_new-v0_matrix-value_shift)), &')
 s=(ROOT/'model/claim_tests/continuous_y_quadrature.f90').read_text()+'\n'+s
if a.howard_evaluations:
 s=replace_once(s,'end module fixed_policy_pricing\n','end module fixed_policy_pricing\n'+(ROOT/'model/claim_tests/howard_value_evaluation.f90').read_text()+'\n')
 s=replace_once(s,'subroutine iterate\nUSE param\n','subroutine iterate\nUSE param\nUSE howard_value_evaluation,only:evaluate_policy_values\nUSE continuous_y_quadrature,only:repayment_hat_weights\n')
 marker='   continuous_change=maxval(abs(b0_next_matrix-old_continuous_b),mask=default_decision==1)'
 s=replace_once(s,marker,f'''   call repayment_hat_weights(b_num,y_num,p_num,p_vol_num,y_grid,rho,std_eps,0d0,v0_matrix_new,v1_matrix_new, &
   y_hat,y_wleft,y_wright,y_lower,y_upper,repay_y_weights)
   call evaluate_policy_values(b_num,y_num,p_num,p_vol_num,{a.howard_evaluations},b_grid,b0_next_matrix,default_decision, &
   y_hat,trans_matrix_p,trans_matrix_p_vol,repay_y_weights,c0_matrix,c1_matrix,beta,prob_excl_end, &
   v0_matrix_new,v1_matrix_new,v_matrix_new)
   deviation=maxval(abs(v_matrix_new-v_matrix))
   dev_matrix=abs(v_matrix_new-v_matrix)
'''+marker)
if a.stall_window:
 assert a.policy_pricing
 s=replace_once(s,'logical :: update_prices=.true.','DOUBLE PRECISION :: best_pricing_residual=huge(1d0)\nINTEGER :: stale_pricing_updates=0\nLOGICAL :: numerical_stalled=.false.\nlogical :: update_prices=.true.')
 s=replace_once(s,' close(721)',''' close(721)
 if(raw_schedule_residual<.95d0*best_pricing_residual)then
  best_pricing_residual=raw_schedule_residual
  stale_pricing_updates=0
 else
  stale_pricing_updates=stale_pricing_updates+1
 end if
 if(stale_pricing_updates>='''+str(a.stall_window)+''' .and. raw_schedule_residual>1d-5)numerical_stalled=.true.
 if(.not.policy_price_success)numerical_stalled=.true.
 open(723,file='pricing_progress.csv',position='append')
 write(723,*)counter,raw_schedule_residual,best_pricing_residual,stale_pricing_updates,numerical_stalled
 close(723)''')
 s=replace_once(s,f'.or. counter >= {a.max_iterations}) then',f'.or. counter >= {a.max_iterations} .or. numerical_stalled) then')
 s=replace_once(s,"         write(712,*) 'NOT_CONVERGED_ITERATION_LIMIT'", "         if(numerical_stalled)then\n         write(712,*) 'NOT_CONVERGED_STALLED_PRICING'\n         else\n         write(712,*) 'NOT_CONVERGED_ITERATION_LIMIT'\n         end if")
kernel_provenance=None
if a.level_mean_kernels:
 import numpy as np
 kernel_path=a.level_mean_kernels.resolve()/(a.economy+'_alternative_kernel.npz')
 metadata_path=a.level_mean_kernels.resolve()/'kernel_provenance.json'
 if metadata_path.exists():
  metadata=json.loads(metadata_path.read_text())
  assert metadata['branch_source_sha256']==hashlib.sha256((ROOT/'model/oil_prod_CES.f90').read_bytes()).hexdigest(),'Kernel calibration differs from current source'
  assert metadata['kernels'][a.economy]==hashlib.sha256(kernel_path.read_bytes()).hexdigest(),'Kernel file changed after audit'
 data=np.load(kernel_path);kernel=data['kernel']
 assert kernel.shape==(5,549,549) and np.all(kernel>=0) and np.max(abs(kernel.sum(axis=2)-1))<1e-12
 np.savetxt(d/'level_mean_kernel.txt',kernel.reshape(-1,549),fmt='%.17e')
 marker='std_u_p*exp(p_vol_grid(i)/2d+0), trans_matrix_p(:,:,i), mp_drift)'
 s=replace_once(s,marker,marker+'''
         ! Audited finite-support level-moment correction, computed externally.
         if(i==1)open(718,file='level_mean_kernel.txt',status='old')
         do j=1,p_num
            read(718,*)trans_matrix_p(j,:,i)
         end do
         if(i==p_vol_num)close(718)
''')
 kernel_provenance=dict(path=str(kernel_path),sha256=hashlib.sha256(kernel_path.read_bytes()).hexdigest(),discretization='Finite-support exponential tilt matching conditional level means; log moments change near boundaries')
(d/'source.f90').write_text(s)
original=(ROOT/'model/oil_prod_CES.f90').read_text()
(a.output_root/(a.economy+'_instrumentation.diff')).write_text(''.join(difflib.unified_diff(original.splitlines(True),s.splitlines(True),fromfile='current_branch',tofile=a.economy+'_nested')))
m=json.loads((a.output_root/(a.economy+'_manifest.json')).read_text())
m.update(instrumented_source_sha256=hashlib.sha256(s.encode()).hexdigest(),method='adaptive_nested_fixed_price_bellman',inner_tolerance='max(1e-10,min(1e-6,0.001*last_outer_pricing_residual))',inner_cap=200,price_update_relaxation=a.price_relaxation,uniform_value_correction=a.relative_values,fixed_price_validation=a.fixed_price_validation,continuous_interpolated_debt=a.continuous_debt,pricing_residual_timing='fresh at outer updates; retained on frozen sweeps')
m['post_shift_bellman_residual_bound_checked']=a.relative_values
m['continuous_policy_change_checked']=a.continuous_debt
m['fixed_policy_lender_system_solved']=a.policy_pricing
m['continuous_gaussian_y_cutoff_integration']=a.continuous_y
m['howard_evaluation_steps_per_policy_improvement']=a.howard_evaluations
m['pricing_stall_window']=a.stall_window
if kernel_provenance:
 m['alternative_transition_discretization']=kernel_provenance
if a.parallel_controls:
 assert a.continuous_debt
 m['compiler_flags'].append('-fopenmp')
 m['parallel_independent_controls']=True
(a.output_root/(a.economy+'_manifest.json')).write_text(json.dumps(m,indent=2)+'\n')
subprocess.run(['gfortran',*m['compiler_flags'],'source.f90','-o','solve'],cwd=d,check=True)
print('Running',d,flush=True)
with (d/'run.log').open('w') as log:
 r=subprocess.run([str(d/'solve')],cwd=d,stdout=log,stderr=subprocess.STDOUT)
print('Exit',r.returncode,flush=True)
