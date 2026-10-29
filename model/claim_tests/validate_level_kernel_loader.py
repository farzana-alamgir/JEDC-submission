"""Verify generated Fortran loads the audited kernel before building saved transitions."""
from pathlib import Path
import hashlib,json,subprocess
import numpy as np
from solve_current_branch import ROOT,replace_once
base=ROOT/'results/current_branch_claims';out=base/'level_mean_kernel_audit';d=out/'raw/loader_mp';d.mkdir(parents=True,exist_ok=False)
original=(ROOT/'model/oil_prod_CES.f90').read_text();source=original[:original.index('end module param')+len('end module param')];start=original.index('subroutine compute_grid\n');end=original.index('end subroutine compute_grid',start)+len('end subroutine compute_grid');source+='\n'+original[start:end]+ '\nprogram loader_check\nuse param\ncall compute_grid\nend program loader_check\n';source=replace_once(source,'mean_preserving = .false., p_width_sd','mean_preserving = .true., p_width_sd')
marker='std_u_p*exp(p_vol_grid(i)/2d+0), trans_matrix_p(:,:,i), mp_drift)';source=replace_once(source,marker,marker+'''
if(i==1)open(718,file='level_mean_kernel.txt',status='old')
do j=1,p_num
read(718,*)trans_matrix_p(j,:,i)
end do
if(i==p_vol_num)close(718)
''');(d/'source.f90').write_text(source);kernel=np.load(out/'mp_alternative_kernel.npz')['kernel'];np.savetxt(d/'level_mean_kernel.txt',kernel.reshape(-1,549),fmt='%.17e');subprocess.run(['gfortran','-O3','-ffree-line-length-none','source.f90','-o','check'],cwd=d,check=True)
with (d/'run.log').open('w')as f:subprocess.run([str(d/'check')],cwd=d,stdout=f,stderr=subprocess.STDOUT,check=True)
actual=np.loadtxt(d/'graphs_trans_matrix_p.txt',usecols=0).reshape(kernel.shape);error=float(np.max(abs(actual-kernel)));assert error<1e-15
report=dict(max_kernel_loading_error=error,passed=True,actual_kernel_sha256=hashlib.sha256(actual.tobytes()).hexdigest(),source_sha256=hashlib.sha256(source.encode()).hexdigest());(out/'fortran_loader_validation.json').write_text(json.dumps(report,indent=2)+'\n');print(report)
