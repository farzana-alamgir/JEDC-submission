"""Check analytic cutoff integration against independent 64-point Gaussian quadrature."""
from pathlib import Path
import json,math,subprocess
import numpy as np
from gaussian_y import repayment_weights,weight_tables
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'results/current_branch_claims/continuous_y_check';out.mkdir(exist_ok=True)
driver='''program check
use continuous_y_quadrature
implicit none
integer,parameter::n=21,nb=4,np=3,nh=2
integer::ic
double precision::grid(n),vr(nb,n,np,nh),va(n,np,nh),all(n,n),wl(n,n-1),wr(n,n-1),lower(n),upper(n),w(nb,n,n,np,nh),sigma
read(*,*)grid
read(*,*)vr
read(*,*)va
do ic=1,3
read(*,*)sigma
call gaussian_weight_tables(n,grid,.9d0,sigma,0d0,all,wl,wr,lower,upper)
call repayment_hat_weights(nb,n,np,nh,grid,.9d0,sigma,0d0,vr,va,all,wl,wr,lower,upper,w)
write(*,'(ES26.16E3)')all
write(*,'(ES26.16E3)')w
end do
end program check
'''
(out/'driver.f90').write_text(driver);subprocess.run(['gfortran','-O3','-fopenmp','-fcheck=all','-ffree-line-length-none',str(ROOT/'model/claim_tests/continuous_y_quadrature.f90'),'driver.f90','-o','check'],cwd=out,check=True)
rng=np.random.default_rng(9181);n,nb,np_,nh=21,4,3,2;grid=np.linspace(-.2753,.2753,n);va=-4+rng.normal(0,.1,(n,np_,nh));vr=va[None,:,:,:]+rng.normal(0,.3,(nb,n,np_,nh));vr[0]=va+1;vr[1]=va-1;signals=rng.normal(0,1,(nb,n,np_,nh));sigmas=[.03,.005,.1];lines=[]
for arr in [grid,vr,va]:lines.extend(f'{x:.17g}'for x in arr.ravel(order='F'))
lines.extend(map(str,sigmas));result=subprocess.run([str(out/'check')],input='\n'.join(lines)+'\n',text=True,capture_output=True,check=True);values=np.array(list(map(float,result.stdout.split())));offset=0;nodes,quadweights=np.polynomial.legendre.leggauss(64);reports=[]
for sigma in sigmas:
 all=values[offset:offset+n*n].reshape((n,n),order='F');offset+=n*n
 size=nb*n*n*np_*nh;w=values[offset:offset+size].reshape((nb,n,n,np_,nh),order='F');offset+=size
 assert np.max(abs(all.sum(axis=1)-1))<1e-13 and np.min(w)>=0 and np.max(w-all[None,:,:,None,None])<1e-14
 errpay=0.;errval=0.;python_error=0.
 tables=weight_tables(grid,.9,sigma)
 assert np.max(abs(tables[0]-all))<1e-13
 for p in range(np_):
  for h in range(nh):
   python_error=max(python_error,float(np.max(abs(repayment_weights(vr[:,:,p,h],va[:,p,h],grid,.9,sigma,tables)-w[:,:,:,p,h]))))
 assert python_error<1e-13
 for b in range(nb):
  for p in range(np_):
   for h in range(nh):
    gap=vr[b,:,p,h]-va[:,p,h];breaks=list(grid)
    for j in range(n-1):
     if gap[j]*gap[j+1]<0:breaks.append(grid[j]-gap[j]*(grid[j+1]-grid[j])/(gap[j+1]-gap[j]))
    breaks=sorted(breaks)
    for iy,y in enumerate(grid):
     mu=.9*y;lower=.5*math.erfc(-(grid[0]-mu)/(sigma*np.sqrt(2)));upper=.5*math.erfc((grid[-1]-mu)/(sigma*np.sqrt(2)))
     pay=lower*signals[b,0,p,h]*(gap[0]>=0)+upper*signals[b,-1,p,h]*(gap[-1]>=0)
     val=lower*max(vr[b,0,p,h],va[0,p,h])+upper*max(vr[b,-1,p,h],va[-1,p,h])
     for lo,hi in zip(breaks[:-1],breaks[1:]):
      x=.5*(hi-lo)*nodes+.5*(hi+lo);density=np.exp(-.5*((x-mu)/sigma)**2)/(sigma*np.sqrt(2*np.pi));qv=np.interp(x,grid,signals[b,:,p,h]);rv=np.interp(x,grid,vr[b,:,p,h]);av=np.interp(x,grid,va[:,p,h]);mass=.5*(hi-lo)*quadweights*density
      pay+=float(np.sum(mass*qv*(rv>=av)));val+=float(np.sum(mass*np.maximum(rv,av)))
     analyticpay=float(w[b,iy,:,p,h]@signals[b,:,p,h]);analyticval=float(w[b,iy,:,p,h]@vr[b,:,p,h]+(all[iy]-w[b,iy,:,p,h])@va[:,p,h]);errpay=max(errpay,abs(pay-analyticpay));errval=max(errval,abs(val-analyticval))
 assert errpay<1e-11 and errval<1e-11,(sigma,errpay,errval)
 reports.append(dict(sigma=sigma,max_payoff_expectation_discrepancy=errpay,max_max_value_expectation_discrepancy=errval,independent_python_weight_discrepancy=python_error,row_sum_error=float(np.max(abs(all.sum(axis=1)-1)))))
report=dict(passed=True,reference='Independent 64-point Gauss-Legendre integration, split at all repayment/default crossings; constant tail convention',panels_per_case=nb*np_*nh,current_y_nodes=n,cases=reports)
(out/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
