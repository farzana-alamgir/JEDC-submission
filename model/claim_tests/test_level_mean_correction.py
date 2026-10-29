"""Kernel-only experiment: match Gaussian conditional level means on finite support.

This is an alternative discretization audit, NOT a solved economic model. It
relaxes log-moment matching near boundaries; report that tradeoff explicitly.
"""
from pathlib import Path
import hashlib,json
import numpy as np
from test_claims import number
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'results/current_branch_claims';out=base/'level_mean_kernel_audit';out.mkdir(exist_ok=True)
for economy in ['bm','mp']:
 d=base/'nested/raw'/economy;src=(d/'source.f90').read_text();hs=np.loadtxt(d/'graphs_p_vol_grid_dss.txt');z=np.loadtxt(d/'graphs_p_grid_dss.txt',usecols=0).reshape(len(hs),-1)[0];old=np.loadtxt(d/'graphs_trans_matrix_p.txt',usecols=0).reshape(len(hs),len(z),len(z));th=np.loadtxt(d/'graphs_trans_matrix_p_vol.txt').reshape(len(hs),len(hs));oldpi=np.load(base/'boundary_audit'/(economy+'_stationary_price_volatility.npz'))['stationary']
 muh=number(src,'mean_p_vol');eta=number(src,'eta');rh=number(src,'rho_p_vol');rho=number(src,'rho_p');mu=number(src,'mean_p');h=muh+np.linspace(-2,2,len(hs))*eta/np.sqrt(1-rh**2);assert max(abs(h-hs))<5e-9
 variance=np.exp(h);v0=np.exp(muh+.5*eta**2/(1-rh**2));target_log=(1-rho)*mu+rho*z[None,:]+(-.5*(variance-v0) if economy=='mp' else np.zeros(len(h)))[:,None];target=np.exp(target_log+.5*variance[:,None]);prices=np.exp(z)
 corrected=old.copy();residual=0.;changed=0
 for v in range(len(h)):
  for i in range(len(z)):
   x=(prices-target[v,i])/target[v,i];row=old[v,i];logrow=np.full(len(z),-np.inf);positive=row>0;logrow[positive]=np.log(row[positive])
   def tilted(lam):
    lw=logrow+lam*x;lw-=np.max(lw);q=np.exp(lw);q/=q.sum();return q,float(q@x)
   q,r=tilted(0.)
   if abs(r)>2e-14:
    lo=-1.;hi=1.
    for _ in range(50):
     if tilted(lo)[1]<=0 and tilted(hi)[1]>=0:break
     lo*=2;hi*=2
    else:raise RuntimeError('Target outside positive-probability support')
    for _ in range(100):
     mid=.5*(lo+hi);q,r=tilted(mid)
     if abs(r)<2e-14:break
     if r>0:hi=mid
     else:lo=mid
    changed+=1
   corrected[v,i]=q;residual=max(residual,abs(r))
 m=corrected@z;varlog=corrected@(z*z)-m*m;mean=corrected@prices;varlevel=corrected@(prices*prices)-mean*mean
 expected=th@mean;mean_range=np.ptp(expected,axis=0)/np.mean(expected,axis=0)
 tv=.5*np.sum(abs(corrected-old),axis=2);interior=(z>=mu+np.log(.8))&(z<=mu+np.log(1.5));weights=th.T@oldpi
 report=dict(economy=economy,equilibrium_solved=False,alternative_discretization_only=True,mean_preserving=(economy=='mp'),changed_rows=changed,max_relative_level_mean_error=float(np.max(abs(mean/target-1))),max_conditional_level_mean_range_across_current_vol_relative=float(np.max(mean_range)),max_interior_row_total_variation=float(np.max(tv[:,interior])),max_row_total_variation=float(np.max(tv)),old_stationary_weighted_row_total_variation=float(np.sum(weights*tv)),max_absolute_log_mean_error=float(np.max(abs(m-target_log))),max_relative_log_variance_error=float(np.max(abs(varlog/variance[:,None]-1))),old_stationary_weighted_absolute_relative_log_variance_error=float(np.sum(weights*abs(varlog/variance[:,None]-1))),variance_order_violations_across_future_vol=int(np.sum(np.diff(varlevel,axis=0)<-1e-12)),minimum_price=float(prices[0]),oil_interior_price_threshold=.09)
 path=out/(economy+'_alternative_kernel.npz')
 if path.exists():
  saved=np.load(path)
  assert np.max(abs(saved['kernel']-corrected))<1e-13,'Use a new output version for a changed kernel'
 else:
  np.savez_compressed(path,kernel=corrected,z=z,h=h)
 (out/(economy+'_audit.json')).write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report),flush=True)
metadata=dict(branch_source_sha256=json.loads((base/'nested/bm_manifest.json').read_text())['source_sha256'],kernels={e:hashlib.sha256((out/(e+'_alternative_kernel.npz')).read_bytes()).hexdigest()for e in ['bm','mp']})
(out/'kernel_provenance.json').write_text(json.dumps(metadata,indent=2)+'\n')
