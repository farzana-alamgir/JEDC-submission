"""Check fixed-policy government value updates against a dense transition matrix."""
from pathlib import Path
import subprocess,json
import numpy as np
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'results/current_branch_claims/howard_value_check';out.mkdir(exist_ok=True)
driver='''program check
use howard_value_evaluation
implicit none
integer,parameter::nb=3,ny=3,np=4,nh=2
integer::ic,steps,d(nb,ny,np,nh)
double precision::g(nb),policy(nb,ny,np,nh),ty(ny,ny),tp(np,np,nh),th(nh,nh),w(nb,ny,ny,np,nh)
double precision::cr(nb,ny,np,nh),ca(ny,np,nh),vr(nb,ny,np,nh),va(ny,np,nh),value(nb,ny,np,nh)
do ic=1,9
read(*,*)steps
read(*,*)g
read(*,*)policy
read(*,*)d
read(*,*)ty
read(*,*)tp
read(*,*)th
read(*,*)w
read(*,*)cr
read(*,*)ca
read(*,*)vr
read(*,*)va
call evaluate_policy_values(nb,ny,np,nh,steps,g,policy,d,ty,tp,th,w,cr,ca,.96d0,.0833d0,vr,va,value)
write(*,'(ES26.16E3)')vr
write(*,'(ES26.16E3)')va
write(*,'(ES26.16E3)')value
end do
end program check
'''
(out/'driver.f90').write_text(driver);subprocess.run(['gfortran','-O3','-fopenmp','-fcheck=all','-ffree-line-length-none',str(ROOT/'model/claim_tests/fixed_policy_pricing.f90'),str(ROOT/'model/claim_tests/howard_value_evaluation.f90'),'driver.f90','-framework','Accelerate','-o','check'],cwd=out,check=True)
rng=np.random.default_rng(1991);nb,ny,np_,nh=3,3,4,2;shape=(nb,ny,np_,nh);ashape=(ny,np_,nh);nr=np.prod(shape);na=np.prod(ashape);cases=[];lines=[]
for mode in range(3):
 for steps in [1,10,25]:
  g=np.linspace(0,20,nb);policy=rng.uniform(0,20,shape);d=np.where(rng.random(shape)<.6,1,2);ty=rng.random((ny,ny));ty/=ty.sum(axis=1,keepdims=True);tp=rng.random((np_,np_,nh));tp/=tp.sum(axis=1,keepdims=True);th=rng.random((nh,nh));th/=th.sum(axis=1,keepdims=True);w=rng.random((nb,ny,ny,np_,nh))*ty[None,:,:,None,None]
  if mode==0:w[:]=ty[None,:,:,None,None]
  if mode==1:w[:]=0
  cr=rng.uniform(2,10,shape);ca=rng.uniform(2,10,ashape);vr=-rng.uniform(2,5,shape);va=-rng.uniform(2,5,ashape);cases.append((mode,steps,g,policy,d,ty,tp,th,w,cr,ca,vr,va));lines.append(str(steps))
  for arr in [g,policy,d,ty,tp,th,w,cr,ca,vr,va]:lines.extend(f'{x:.17g}'for x in arr.ravel(order='F'))
r=subprocess.run([str(out/'check')],input='\n'.join(lines)+'\n',capture_output=True,text=True,check=True);output=np.array(list(map(float,r.stdout.split())));offset=0;reports=[]
for mode,steps,g,policy,d,ty,tp,th,w,cr,ca,vr,va in cases:
 P=np.zeros((nr+na,nr+na))
 def ridx(b,y,p,h):return np.ravel_multi_index((b,y,p,h),shape,order='F')
 def aidx(y,p,h):return nr+np.ravel_multi_index((y,p,h),ashape,order='F')
 for y in range(ny):
  for p in range(np_):
   for h in range(nh):
    for b in range(nb):
     row=ridx(b,y,p,h);left=int(np.clip(np.searchsorted(g,policy[b,y,p,h],side='right')-1,0,nb-2));t=(policy[b,y,p,h]-g[left])/(g[left+1]-g[left])
     for yy in range(ny):
      for pp in range(np_):
       for hh in range(nh):
        prob=tp[p,pp,hh]*th[h,hh]
        for j,ww in [(left,1-t),(left+1,t)]:
         P[row,ridx(j,yy,pp,hh)]+=ww*prob*w[j,y,yy,pp,hh]
         P[row,aidx(yy,pp,hh)]+=ww*prob*(ty[y,yy]-w[j,y,yy,pp,hh])
    row=aidx(y,p,h)
    for yy in range(ny):
     for pp in range(np_):
      for hh in range(nh):
       prob=tp[p,pp,hh]*th[h,hh];P[row,ridx(0,yy,pp,hh)]+=.0833*prob*w[0,y,yy,pp,hh];P[row,aidx(yy,pp,hh)]+=prob*(ty[y,yy]-.0833*w[0,y,yy,pp,hh])
 assert np.max(abs(P.sum(axis=1)-1))<1e-14
 z=np.r_[vr.ravel(order='F'),va.ravel(order='F')];reward=np.r_[(-1/cr).ravel(order='F'),(-1/ca).ravel(order='F')]
 for _ in range(steps):z=reward+.96*(P@z)
 got=output[offset:offset+nr+na];offset+=nr+na;value=output[offset:offset+nr].reshape(shape,order='F');offset+=nr
 expectedval=np.where(d==1,z[:nr].reshape(shape,order='F'),z[nr:].reshape(ashape,order='F')[None,...]);error=float(np.max(abs(got-z)));verror=float(np.max(abs(value-expectedval)));assert max(error,verror)<1e-11
 reports.append(dict(mode=mode,evaluation_steps=steps,maximum_dense_value_discrepancy=error,maximum_reported_total_value_discrepancy=verror))
report=dict(passed=True,states=int(nr+na),reference='Independent dense fixed-policy transition matrix, including default and exclusion/reentry',cases=reports);(out/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
