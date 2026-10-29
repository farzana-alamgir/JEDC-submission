"""Fixed-price inner Bellman iteration; isolated numerical experiment."""
import argparse, difflib, hashlib, json, subprocess
from pathlib import Path
from solve_current_branch import prepare, replace_once, ROOT
p=argparse.ArgumentParser()
p.add_argument('economy',choices=['bm','mp'])
p.add_argument('--max-iterations',type=int,default=1500)
p.add_argument('--output-root',type=Path,default=ROOT/'results/current_branch_claims/nested')
a=p.parse_args()
d=prepare(a.economy,a.max_iterations,1e-6,True,a.output_root,ROOT/'results/current_branch_claims/damped005/raw',.1)
s=(d/'source.f90').read_text()
s=replace_once(s,'INTEGER :: changes_d, changes_b','INTEGER :: changes_d, changes_b, inner_steps=0, outer_steps=0\nlogical :: update_prices=.true.\nDOUBLE PRECISION :: previous_bellman=1d0')
s=replace_once(s,'   old_d = default_decision','   update_prices = (counter == 1 .or. previous_bellman < 1d-9 .or. inner_steps >= 200)\n   if (update_prices) then\n      outer_steps=outer_steps+1\n      inner_steps=0\n   end if\n   inner_steps=inner_steps+1\n   old_d = default_decision')
# precompute still computes expectations each sweep; freeze only price schedule.
s=replace_once(s,'q_fun_matrix=(1d0-1.000000000000d-01)*q_schedule_old+1.000000000000d-01*q_fun_matrix', 'if (update_prices) then\nq_fun_matrix=(1d0-1.000000000000d-01)*q_schedule_old+1.000000000000d-01*q_fun_matrix\nelse\nq_fun_matrix=q_schedule_old\nend if')
# update_prices must be module-visible, not local.
s=s.replace('logical :: update_prices=.true.\n','')
s=replace_once(s,'DOUBLE PRECISION :: q_schedule_old','logical :: update_prices=.true.\nDOUBLE PRECISION :: q_schedule_old')
s=replace_once(s,'   changes_d = count(default_decision /= old_d)','   previous_bellman=deviation\n   changes_d = count(default_decision /= old_d)')
s=replace_once(s,"   close(714)","   close(714)\n   open(715,file='nested_history.csv',position='append')\n   write(715,*) counter,outer_steps,inner_steps,update_prices,deviation,raw_schedule_residual\n   close(715)\n   open(716,file='switching_states.txt',status='replace')\n   do i_p_vol=1,p_vol_num\n   do i_p=1,p_num\n   do i_y=1,y_num\n   do i_b=1,b_num\n      if (default_decision(i_b,i_y,i_p,i_p_vol) /= old_d(i_b,i_y,i_p,i_p_vol)) &\n      write(716,*) i_b,i_y,i_p,i_p_vol,b_grid(i_b),y_grid(i_y),p_grid(i_p,i_p_vol), &\n      v0_matrix_new(i_b,i_y,i_p,i_p_vol)-v1_matrix_new(i_y,i_p,i_p_vol), &\n      old_d(i_b,i_y,i_p,i_p_vol),default_decision(i_b,i_y,i_p,i_p_vol)\n   end do\n   end do\n   end do\n   end do\n   close(716)")
(d/'source.f90').write_text(s)
original=(ROOT/'model/oil_prod_CES.f90').read_text()
(a.output_root/(a.economy+'_instrumentation.diff')).write_text(''.join(difflib.unified_diff(original.splitlines(True),s.splitlines(True),fromfile='current_branch',tofile=a.economy+'_nested')))
m=json.loads((a.output_root/(a.economy+'_manifest.json')).read_text())
m.update(instrumented_source_sha256=hashlib.sha256(s.encode()).hexdigest(),method='nested_fixed_price_bellman',inner_tolerance=1e-9,inner_cap=200,price_update_relaxation=.1)
(a.output_root/(a.economy+'_manifest.json')).write_text(json.dumps(m,indent=2)+'\n')
subprocess.run(['gfortran',*m['compiler_flags'],'source.f90','-o','solve'],cwd=d,check=True)
print('Running',d,flush=True)
with (d/'run.log').open('w') as log:
 r=subprocess.run([str(d/'solve')],cwd=d,stdout=log,stderr=subprocess.STDOUT)
print('Exit',r.returncode,flush=True)
