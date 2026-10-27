"""Compare Fortran global optimizer against independent quartic polynomial roots."""
from pathlib import Path
import subprocess,json
import numpy as np
ROOT=Path(__file__).resolve().parents[2];out=ROOT/'results/current_branch_claims/continuous_optimizer_check';out.mkdir(exist_ok=True)
driver='''program check
implicit none
integer::n,t,nt
 double precision::res,bc,bet,del,coup,bs,vs,qs
 double precision,allocatable::g(:),q(:),ev(:)
read(*,*)nt
do t=1,nt
read(*,*)n,res,bc,bet,del,coup
allocate(g(n),q(n),ev(n))
read(*,*)g
read(*,*)q
read(*,*)ev
call continuous_debt(n,g,q,ev,res,bc,bet,del,coup,bs,vs,qs)
write(*,'(3ES25.16)')bs,vs,qs
deallocate(g,q,ev)
end do
end program check
'''
(out/'driver.f90').write_text(driver)
subprocess.run(['gfortran','-O3','-fcheck=all','-ffree-line-length-none',str(ROOT/'model/claim_tests/continuous_debt.f90'),'driver.f90','-o','check'],cwd=out,check=True)
rng=np.random.default_rng(48291);cases=[]
for i in range(400):
 n=100 if i<20 else 12;g=np.linspace(0,20,n);res=rng.uniform(.1,12);bc=rng.uniform(0,20);bet=.96;delta=.03;coupon=.04
 q=np.clip(1-g/20+rng.normal(0,.06,n),0,1)
 ev=-3-.03*g+rng.normal(0,.02,n)
 if i%5==0:q=np.full(n,rng.uniform(.05,1))
 if i%11==0:ev=np.full(n,-3.)
 cases.append((g,q,ev,res,bc,bet,delta,coupon))
lines=[str(len(cases))]
for g,q,ev,res,bc,bet,delta,coupon in cases:
 lines.append(f'{len(g)} {res:.17g} {bc:.17g} {bet} {delta} {coupon}')
 lines.extend(' '.join(f'{x:.17g}' for x in row) for row in [g,q,ev])
r=subprocess.run([str(out/'check')],input='\n'.join(lines)+'\n',capture_output=True,text=True,check=True);answers=np.array([list(map(float,s.split())) for s in r.stdout.splitlines()])
errors=[];coarse_gains=[];reconstruction=[]
for case,(bs,vs,qs) in zip(cases,answers):
 g,q,ev,res,bc,bet,delta,coupon=case
 c=res-bc*coupon+q*(g-(1-delta)*bc);coarse=np.max(-1/np.maximum(c,1e-10)+bet*ev)
 best=coarse
 for j in range(len(g)-1):
  w=g[j+1]-g[j];C=(q[j+1]-q[j])/w;B=q[j]+C*(g[j]-(1-delta)*bc);A=res-bc*coupon+q[j]*(g[j]-(1-delta)*bc);es=(ev[j+1]-ev[j])/w
  coeff=np.zeros(5);square=np.polynomial.polynomial.polymul([A,B,C],[A,B,C]);coeff[:len(square)]=bet*es*square;coeff[:2]+=[B,2*C]
  roots=np.polynomial.polynomial.polyroots(coeff) if np.any(coeff) else []
  floor=np.polynomial.polynomial.polyroots([A-1e-10,B,C]) if (B!=0 or C!=0) else []
  for z in [*roots,*floor]:
   if abs(z.imag)>1e-6 or z.real<0 or z.real>w:continue
   x=z.real;cc=A+B*x+C*x*x;value=-1/max(cc,1e-10)+bet*(ev[j]+es*x);best=max(best,value)
 qtest=np.interp(bs,g,q);etest=np.interp(bs,g,ev);ctest=res-bc*coupon+qtest*(bs-(1-delta)*bc);vtest=-1/max(ctest,1e-10)+bet*etest
 errors.append(abs(vs-best));coarse_gains.append(vs-coarse);reconstruction.append(abs(vs-vtest))
 assert abs(vs-best)<max(1e-9,1e-14*abs(best)),(vs,best,case,bs)
 assert abs(vs-vtest)<max(1e-9,1e-14*abs(vs))
 assert vs>=coarse-max(1e-9,1e-14*abs(coarse))
report=dict(cases=len(cases),reference='Independent NumPy polynomial roots of the quartic first-order equation, floor crossings and endpoints',seed=48291,max_objective_discrepancy=float(max(errors)),max_reconstructed_objective_discrepancy=float(max(reconstruction)),max_gain_over_coarse_choices=float(max(coarse_gains)),passed=True)
(out/'validation.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
