# Figures from the corrected model

Generated from the three economies re-solved on the corrected oil-price process.
**Do not compare these to `../FIGURE*.jpg` as like-for-like**: both the price-process
implementation and the calibration changed. See `../../REVISION_NOTES.md`.

## Configuration

All three share the same physical log-price grid (`sd(log p) = 0.645766`, range
[0.0852, 14.925], 225 nodes) and the same average innovation variance, so they differ
only in what is switched off.

| economy | p_num | p_vol_num | distinguishing parameters | sweeps |
|---|---|---|---|---|
| full (benchmark) | 225 | 5 | `mean_p_vol = -2.166`, `eta = 0.3323` | 127 |
| intermediate | 225 | 5 | `mean_p_vol = -1.961632`, `eta = 1e-8` -> volatility constant at sqrt(E[v]) = 0.140629 | 131 |
| basic | 1 | 1 | `mean_p = 0.328507` -> price fixed at 1.388892 | 128 |

Common: `theta = -1.5` (sigma = 0.4, estimated), `alpha = 1.652632e-4` (oil share 3.74%),
`rho_p = 0.976`, `rho_p_vol = 0.678`, `use_common_p_grid = .true.`.

Two deliberate choices, both responding to Report 2's Major 2:

- The **intermediate** economy fixes volatility at `sqrt(E[v])`, the benchmark's *average
  innovation variance*, not at `exp(mean_p_vol)`. That keeps the average amount of price
  risk the same and isolates the time-*variation* in volatility.
- The **basic** economy fixes the price at `E[p] = 1.388892`, the benchmark's *mean* price
  level. The submitted version used `exp(p_bar) = 1.1275`, the **median**, which is exactly
  the referee's complaint that the ladder mixes "less risk" with "cheaper oil".

## Status

Present: FIGURE3, 4a, 4b, 4c, 4d, 5, 6a, 6b -- all drawn from the benchmark workspace alone.

Absent: **FIGURE2 and FIGURE7**, which are drawn after `oil_intermediate.mat` and
`oil_basic.mat` are loaded (script lines 744/811). At `p_num = 225` those workspaces are
~430 MB each and loading two of them alongside the benchmark stalls MATLAB. The fix is to
save only the variables those two figures need rather than the whole workspace.

## Reproducing

The plotting pipeline is validated: run on the `submitted-baseline` outputs it reproduces
all ten published figures **pixel-identically** (maxdiff 0.0). Two changes were needed for
the corrected runs, both verified not to alter output:

1. ASCII `load` replaced by a `textscan` reader (`fl__`). MATLAB's `load` on the 193 MB
   policy dumps that `p_num = 225` produces took hours; this takes minutes. Re-validated
   against the baseline: still pixel-identical.
2. One slice, `spread2(:,11,4)` -> `squeeze(spread2(:,11,4,1))`, because the corrected
   intermediate economy carries `p_vol_num = 5` with volatility held constant rather than
   `p_vol_num = 1`. All five states are identical by construction, so state 1 is the
   economy's single volatility level.
