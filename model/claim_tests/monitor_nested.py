"""Preserve nonempty switching diagnostics while isolated solvers run."""
from pathlib import Path
import time
root=Path(__file__).resolve().parents[2]/'results/current_branch_claims/nested'
seen={}
for _ in range(3600):
 for economy in ['bm','mp']:
  d=root/'raw'/economy
  path=d/'switching_states.txt'
  if path.exists():
   data=path.read_text()
   if data.strip() and data!=seen.get(economy):
    hist=(d/'nested_history.csv').read_text().splitlines()[-1]
    with (root/(economy+'_switching_examples.txt')).open('a') as f:
     f.write('# '+hist+'\n'+data)
    seen[economy]=data
 if all((root/'raw'/e/'solve_status.txt').exists() for e in ['bm','mp']): break
 time.sleep(.5)
