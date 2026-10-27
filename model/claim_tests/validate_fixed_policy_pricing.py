"""Compare matrix-free long-bond pricing with independently assembled dense systems."""
from pathlib import Path
import json,subprocess
import numpy as np
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'results/current_branch_claims/fixed_policy_price_check';out.mkdir(exist_ok=True)
driver='''program check
use fixed_policy_pricing
implicit none
integer::nt,ic,nb,ny,np,nh,iterations
integer,allocatable::decision(:,:,:,:)
double precision,allocatable::grid(:),policy(:,:,:,:),ty(:,:),tp(:,:,:),th(:,:),q0(:,:,:,:),q(:,:,:,:),weights(:,:,:,:,:)
double precision::coupon,discount,surviving,tol,r0,rf
logical::ok,has_weights
read(*,*)nt
do ic=1,nt
read(*,*)nb,ny,np,nh,coupon,discount,surviving,tol,has_weights
allocate(grid(nb),policy(nb,ny,np,nh),decision(nb,ny,np,nh),ty(ny,ny),tp(np,np,nh),th(nh,nh),q0(nb,ny,np,nh),q(nb,ny,np,nh))
read(*,*)grid
read(*,*)policy
read(*,*)decision
read(*,*)ty
read(*,*)tp
read(*,*)th
read(*,*)q0
if(has_weights)then
allocate(weights(nb,ny,ny,np,nh))
read(*,*)weights
call solve_fixed_policy_prices(nb,ny,np,nh,grid,policy,decision,ty,tp,th,q0,coupon,discount,surviving,tol,q,r0,rf,iterations,ok,weights)
deallocate(weights)
else
call solve_fixed_policy_prices(nb,ny,np,nh,grid,policy,decision,ty,tp,th,q0,coupon,discount,surviving,tol,q,r0,rf,iterations,ok)
end if
write(*,*)iterations,r0,rf,ok
write(*,'(ES25.16)')q
deallocate(grid,policy,decision,ty,tp,th,q0,q)
end do
end program check
'''
(out/'driver.f90').write_text(driver);subprocess.run(['gfortran','-O3','-fcheck=all','-ffree-line-length-none',str(ROOT/'model/claim_tests/fixed_policy_pricing.f90'),'driver.f90','-framework','Accelerate','-o','check'],cwd=out,check=True)
rng=np.random.default_rng(6612);nb,ny,np_,nh=4,3,7,3;shape=(nb,ny,np_,nh);n=np.prod(shape);coupon=.04/1.01;discount=np.exp(-.01);surviving=.97;cases=[];lines=['11']
for case in range(11):
 grid=np.linspace(0,20,nb);policy=rng.uniform(0,20,shape);policy[0,0,0,0]=0;policy[-1,-1,-1,-1]=20
 decision=np.where(rng.random(shape)<.8,1,2)
 if case==0:decision[:]=1
 if case==1:decision[:]=2
 ty=rng.random((ny,ny));ty/=ty.sum(axis=1,keepdims=True)
 tp=rng.random((np_,np_,nh));tp/=tp.sum(axis=1,keepdims=True)
 th=rng.random((nh,nh));th/=th.sum(axis=1,keepdims=True);q0=rng.random(shape)
 if case>=7:
  ty=.9*np.eye(ny)+.1*ty;th=.9*np.eye(nh)+.1*th
  for hh in range(nh):tp[:,:,hh]=.98*np.eye(np_)+.02*tp[:,:,hh]
 if case==8:decision[:]=1
 weights=None
 if case>=9:
  weights=rng.random((nb,ny,ny,np_,nh))*ty[None,:,:,None,None]
  decision[:]=2  # Explicit weights must override nodal default flags.
 cases.append((grid,policy,decision,ty,tp,th,q0,weights))
 lines.append(f'{nb} {ny} {np_} {nh} {coupon:.17g} {discount:.17g} {surviving} 1e-11 '+('T'if weights is not None else'F'))
 for arr in [grid,policy,decision,ty,tp,th,q0]:lines.extend(f'{x:.17g}' for x in arr.ravel(order='F'))
 if weights is not None:lines.extend(f'{x:.17g}'for x in weights.ravel(order='F'))
r=subprocess.run([str(out/'check')],input='\n'.join(lines)+'\n',text=True,capture_output=True,check=True);output=r.stdout.splitlines();offset=0;reports=[]
for case,(grid,policy,decision,ty,tp,th,q0,weights) in enumerate(cases):
 header=output[offset].split();offset+=1;computed=np.array([float(x)for x in output[offset:offset+n]]);offset+=n;assert header[-1]=='T',header
 L=np.zeros((n,n));rhs=np.zeros(n)
 for b in range(nb):
  for y in range(ny):
   for p in range(np_):
    for h in range(nh):
     row=np.ravel_multi_index((b,y,p,h),shape,order='F')
     for yy in range(ny):
      for pp in range(np_):
       for hh in range(nh):
        if weights is None and decision[b,yy,pp,hh]!=1:continue
        yw=ty[y,yy]if weights is None else weights[b,y,yy,pp,hh]
        prob=yw*tp[p,pp,hh]*th[h,hh];rhs[row]+=discount*coupon*prob
        left=int(np.clip(np.searchsorted(grid,policy[b,yy,pp,hh],side='right')-1,0,nb-2));w=(policy[b,yy,pp,hh]-grid[left])/(grid[left+1]-grid[left])
        for jj,ww in [(left,1-w),(left+1,w)]:
         col=np.ravel_multi_index((jj,yy,pp,hh),shape,order='F');L[row,col]+=discount*surviving*prob*ww
 expected=np.linalg.solve(np.eye(n)-L,rhs);error=float(np.max(abs(computed-expected)));residual=float(np.max(abs(computed-L@computed-rhs)))
 assert error<1e-9 and residual<1e-11,(case,error,residual)
 reports.append(dict(case=case,iterations=int(header[0]),maximum_solution_error=error,maximum_dense_equation_residual=residual))
report=dict(passed=True,cases=11,states_per_case=int(n),reference='Independently assembled dense zero-profit matrix and NumPy direct solve; includes persistent kernels and continuous-Y repayment weights',tests=reports)
(out/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
