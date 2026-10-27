"""Compact evidence for isolated nested solves; never treats inner convergence as equilibrium."""
import argparse,csv,json,shutil
from pathlib import Path
import numpy as np
parser=argparse.ArgumentParser()
parser.add_argument('--root',type=Path,default=Path(__file__).resolve().parents[2]/'results/current_branch_claims/nested')
root=parser.parse_args().root.resolve()
summaries=[]
for e in ['bm','mp']:
 d=root/'raw'/e
 history=[]
 for line in (d/'nested_history.csv').read_text().splitlines():
  r=line.split();history.append(dict(iteration=int(r[0]),outer=int(r[1]),inner=int(r[2]),price_update=r[3]=='T',value_change=float(r[4]),pricing_residual=float(r[5])))
 with (root/(e+'_outer_steps.csv')).open('w',newline='') as f:
  w=csv.DictWriter(f,fieldnames=history[0].keys());w.writeheader()
  for n,r in enumerate(history):
   if n==len(history)-1 or history[n+1]['outer']!=r['outer']:w.writerow(r)
 for name in ['convergence.csv','pricing_residual.csv','nested_history.csv']:
  shutil.copyfile(d/name,root/(e+'_'+name))
 if (d/'continuous_debt_change.csv').exists():
  shutil.copyfile(d/'continuous_debt_change.csv',root/(e+'_continuous_debt_change.csv'))
 if (d/'bellman_bound.csv').exists():
  shutil.copyfile(d/'bellman_bound.csv',root/(e+'_bellman_bound.csv'))
 if (d/'fixed_policy_pricing.csv').exists():
  shutil.copyfile(d/'fixed_policy_pricing.csv',root/(e+'_fixed_policy_pricing.csv'))
 status=(d/'solve_status.txt').read_text().strip() if (d/'solve_status.txt').exists() else 'RUNNING'
 examples=root/(e+'_switching_examples.txt')
 rows=[list(map(float,s.split())) for s in examples.read_text().splitlines() if s and not s.startswith('#')] if examples.exists() else []
 diagnostics={}
 if rows:
  x=np.array(rows);diagnostics=dict(sampled_switches=len(x),unique_states=len(set(tuple(r[:4]) for r in rows)),absolute_value_gap_median=float(np.median(abs(x[:,7]))),absolute_value_gap_max=float(max(abs(x[:,7]))),price_range=list(np.exp([min(x[:,6]),max(x[:,6])])) )
 summaries.append(dict(economy=e,status=status,**history[-1],switching_examples=diagnostics))
(root/'summary.json').write_text(json.dumps(summaries,indent=2)+'\n')
print(json.dumps(summaries,indent=2))
