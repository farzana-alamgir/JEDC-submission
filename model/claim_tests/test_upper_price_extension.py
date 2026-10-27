"""Kernel-only upper-support extension, preserving all original nodes and calibration."""
from pathlib import Path
import subprocess,difflib,json,hashlib
import numpy as np
from solve_current_branch import ROOT,replace_once
original=(ROOT/'model/oil_prod_CES.f90').read_text()
out=ROOT/'results/current_branch_claims/upper_boundary_extension';out.mkdir(exist_ok=True)
for e in ['bm','mp']:
 d=out/'raw'/e;d.mkdir(parents=True,exist_ok=False)
 source=original[:original.index('end module param')+len('end module param')]
 start=original.index('subroutine compute_grid\n');end=original.index('end subroutine compute_grid',start)+len('end subroutine compute_grid')
 source+='\n'+original[start:end]+'''\nprogram kernel_only
use param
call compute_grid
end program kernel_only
'''
 source=replace_once(source,'p_num=549, p_vol_num=5','p_num=613, p_vol_num=5')
 source=replace_once(source,'dble(i-1)/dble(p_num-1)','dble(i-1)/548d0')
 if e=='mp':source=replace_once(source,'mean_preserving = .false., p_width_sd','mean_preserving = .true., p_width_sd')
 (d/'source.f90').write_text(source)
 subprocess.run(['gfortran','-O3','-ffree-line-length-none','source.f90','-o','kernel'],cwd=d,check=True)
 with (d/'run.log').open('w') as f:subprocess.run([str(d/'kernel')],cwd=d,stdout=f,stderr=subprocess.STDOUT,check=True)
 z=np.loadtxt(d/'graphs_p_grid_dss.txt',usecols=0).reshape(5,-1)[0]
 oldz=np.loadtxt(ROOT/'results/current_branch_claims/nested/raw'/e/'graphs_p_grid_dss.txt',usecols=0).reshape(5,-1)[0]
 assert np.max(abs(z[:549]-oldz))<1e-14
 (out/(e+'_manifest.json')).write_text(json.dumps(dict(source_sha256=hashlib.sha256(original.encode()).hexdigest(),instrumented_source_sha256=hashlib.sha256(source.encode()).hexdigest(),kernel_only=True,equilibrium_solved=False,added_upper_nodes=64,old_node_max_difference=float(np.max(abs(z[:549]-oldz))),original_lower_price=float(np.exp(z[0])),extended_upper_price=float(np.exp(z[-1]))),indent=2)+'\n')
 print(e,'extended upper support to',np.exp(z[-1]),flush=True)
