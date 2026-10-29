"""After terminal files close, test the audited level-mean kernels and larger price updates."""
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import os,subprocess,sys,time
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'results/current_branch_claims';env=os.environ.copy();env.update(VECLIB_MAXIMUM_THREADS='1',OMP_NUM_THREADS='3',OPENBLAS_NUM_THREADS='1')
def run(e):
 d=base/'continuous_parallel/raw'/e
 while True:
  log=d/'fort.6'
  if (d/'solve_status.txt').exists() and log.exists() and 'Hours ' in log.read_text()[-2000:]:break
  time.sleep(3)
 print('Starting audited-kernel follow-up:',e,flush=True)
 cmd=[sys.executable,str(ROOT/'model/claim_tests/solve_adaptive_nested.py'),e,'--relative-values','--continuous-debt','--parallel-controls','--max-iterations','600','--tolerance','1e-7','--price-relaxation','.5','--level-mean-kernels',str(base/'level_mean_kernel_audit'),'--warm-runs',str(base/'continuous_parallel/raw'),'--output-root',str(base/'level_corrected_continuous')]
 subprocess.run(cmd,cwd=ROOT,env=env,check=True)
 print('Finished audited-kernel follow-up:',e,flush=True)
with ThreadPoolExecutor(max_workers=2) as pool:
 list(pool.map(run,['bm','mp']))
