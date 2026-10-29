"""Finite-support convex-order check using all stop-loss functions (p-K)+."""
from pathlib import Path
import json
import numpy as np
ROOT=Path(__file__).resolve().parents[2];base=ROOT/'results/current_branch_claims';out=base/'level_mean_kernel_audit'
for label in ['original','level_corrected']:
 d=base/'nested/raw/mp';h=np.loadtxt(d/'graphs_p_vol_grid_dss.txt');z=np.loadtxt(d/'graphs_p_grid_dss.txt',usecols=0).reshape(len(h),-1)[0];prices=np.exp(z);th=np.loadtxt(d/'graphs_trans_matrix_p_vol.txt').reshape(len(h),len(h))
 kernel=(np.loadtxt(d/'graphs_trans_matrix_p.txt',usecols=0).reshape(len(h),len(z),len(z)) if label=='original' else np.load(out/'mp_alternative_kernel.npz')['kernel'])
 report={}
 for timing,p in [('future_volatility',kernel),('current_volatility',np.einsum('kl,lij->kij',th,kernel))]:
  means=p@prices;tailprob=np.cumsum(p[...,::-1],axis=-1)[...,::-1];tailprice=np.cumsum((p*prices)[...,::-1],axis=-1)[...,::-1];stoploss=tailprice-prices*tailprob;difference=np.diff(stoploss,axis=0);normalized=difference/means[:-1,:,None]
  report[timing]=dict(max_relative_mean_range=float(np.max(np.ptp(means,axis=0)/np.mean(means,axis=0))),minimum_normalized_stop_loss_difference=float(np.min(normalized)),state_pairs_with_stop_loss_violations=int(np.sum(np.any(normalized < -1e-10,axis=-1))),total_adjacent_volatility_state_pairs=int(normalized.shape[0]*normalized.shape[1]),convex_order_passed=bool(np.max(np.ptp(means,axis=0)/np.mean(means,axis=0))<1e-10 and np.min(normalized)>-1e-10))
 (out/(label+'_convex_order.json')).write_text(json.dumps(report,indent=2)+'\n');print(label,report,flush=True)
