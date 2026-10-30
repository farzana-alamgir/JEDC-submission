# The shipped common-grid version against the paper, and a better calibration

Extends `VERSIONS_SUMMARY.md`, which stops at version 6 on the per-state grid
(`p_num = 7`). The version actually shipped in `JEDC_common_grid_final/` is
that specification moved onto the common grid at `p_num = 277`, and the move
changed enough to be worth recording separately.

Everything in §2–§6 was measured from solved runs with
`model/analysis/moments_fast.py` and `ALL_FIGURES_common_grid.m`. Everything in
§7 is quoted from the existing notes and was **not** re-verified here.

## 1. The three versions

| | submitted paper | shipped (`common_grid_final`) | `spdebt` |
|---|---|---|---|
| `theta` / `sigma_oil` | 0.5 / 2.0 | −2.33333333 / 0.30 | −2.33333333 / 0.30 |
| `alpha` | 0.3 | 0.000307 | 0.000307 |
| `beta` | 0.96 | 0.972 | **0.9746** |
| `d0` | −0.246 | −0.246 | −0.246 |
| `d1` | 0.37 | 0.46 | **0.4731** |
| `va_default_cost` | — (endowment) | `.true.` | `.true.` |
| `kappa_risk` | — | 0 | 0 |
| price grid | per-state Rouwenhorst, `p_num=7` | common, `p_num=277` | common, `p_num=277` |
| oil price volatility | 1.86%/qtr (`exp(h)` bug) | 14.63% (data 14.47%) | 14.63% |

`spdebt` differs from the shipped version in `beta` and `d1` only. `d0` stays
at the submitted −0.246.

## 2. Table 3 fit

| moment | target | submitted\* | shipped | **spdebt** |
|---|---|---|---|---|
| mean spread (annual, %) | 4.1 | 4.1 | 4.9336 | **4.0900** |
| sd(spread) | 2.0 | 2.0 | 4.0252 | 3.6250 |
| debt/GDP (%) | 34.0 | 34.0 | 33.389 | **34.055** |
| oil/GDP (%) | 9.0 | 9.0 | 8.662 | **8.916** |
| | | | | |
| absolute miss, summed | — | — | 127% | **83%** |

\* The submitted column is the paper's *target*, not an independent result —
see `VERSIONS_SUMMARY.md` §2. Only the shipped and `spdebt` columns are
like-for-like.

`spdebt` improves every moment at once. Per-moment miss: spread 0.2%, debt
0.2%, oil share 0.9%, sd 81.3%.

## 3. Channels

Differences of two mean spreads, in basis points, with 95% intervals from the
per-episode standard errors.

| channel | shipped | **spdebt** |
|---|---|---|
| oil price risk (full − basic) | +286.0 ±7.5 | **+218.9 ±6.5** |
| time-varying volatility (full − intermediate) | +7.3 ±10.1 | +6.3 ±8.7 |
| mean-preserving (full − mp) | +3.2 ±10.3 | +3.3 ±8.9 |

The headline channel falls 23%. As a share of the mean spread it is nearly
unchanged — 58% shipped against 54% at `spdebt` — so what moves is the level,
not the mechanism. The two volatility channels straddle zero in both
calibrations and should not be leaned on.

## 4. Welfare

Consumption equivalent, %, across the 21 output states at mean debt.

| | shipped | **spdebt** |
|---|---|---|
| remove all oil price risk — mean | +0.1289 | **+0.1767** |
| — peak | +0.1922 | **+0.2203** |
| — minimum | **−0.0827** | **+0.0400** |
| remove time-varying volatility — mean | +0.0121 | −0.0080 |

Two things here. The peak is the number comparable to the README's "+0.19% in
the figure": at `spdebt` it clears the paper's claimed +0.2% floor, so FIGURE7
stops being the one figure falling short. And the shipped calibration makes
removing oil price risk a welfare *loss* at the three lowest output states;
`spdebt` is positive at all 21.

The full → intermediate sign flips. Both values are negligible and the
corresponding spread channel is statistically indistinguishable from zero in
both calibrations, so the sign is not a robust feature either way.

## 5. Figures

The three claims `JEDC_common_grid_final/README.md` makes, re-measured.

| | shipped | **spdebt** |
|---|---|---|
| FIGURE3 ratio high/low (median) | 1.1235 | 1.1110 |
| FIGURE3 high ≥ mid ≥ low | 20 of 20 | **21 of 21** |
| FIGURE3 NaN cells | 3 of 63 | **0 of 63** |
| FIGURE2 levels (full, inter, basic) | 4.6577, 4.6502, 2.5654 | 4.0995, 4.0838, 2.1225 |
| FIGURE2 ordering holds | 59 of 69 | 63 of 74 |
| FIGURE4d spread across volatility | 1.925% | 1.925% |

All three survive, and FIGURE3 is cleaner at `spdebt` — monotone at every
output state with no undefined cells. FIGURE4d is identical because it depends
only on the price process, which `beta` and `d1` do not touch: the simulated
E[p] is 1.372100 at `beta` = 0.972, 0.9746 and 0.9847 alike.

Note: the FIGURE3 median measured here is 1.1235, against the 1.120 the README
quotes. Same to two decimals; the ratio definitions evidently differ slightly
(here, median of vol-state 4 over vol-state 2).

The full set regenerated at `spdebt` is in `model/figs_spdebt/`;
`JEDC_common_grid_final/` was not touched.

## 6. Why `sd(spread)` cannot be fixed by `beta` and `d1`

Six probes, all at `p_num = 277` (`model/*_probe.sh`, `model/bd1_grid.sh`).

**`beta` and `d1` set spread and debt; `d0` is what moves `sd/spread`.** With
`d0` held at −0.246 the ratio never falls below 0.886 against a data target of
0.488, and lowering sd only drags spread down faster:

| `beta` | `d1` | spread | sd | debt/y | sd/spread |
|---|---|---|---|---|---|
| 0.9720 | 0.4600 | 4.9336 | 4.0252 | 33.39 | 0.816 |
| 0.9746 | 0.4731 | 4.0900 | 3.6250 | 34.06 | 0.886 |
| 0.9760 | 0.5000 | 3.5469 | 3.2962 | 38.17 | 0.929 |
| 0.9785 | 0.4870 | 3.0252 | 3.0790 | 32.24 | 1.018 |
| 0.9847 | 0.5139 | 1.7436 | 2.6324 | 26.06 | 1.510 |

Letting `d0` go **positive** reaches sd 2.2907 at spread 4.2171 (`beta`
0.966767, `d0` +0.013453, `d1` 0.142325 — `model/predpoint_probe.sh`). So the
sd match and a conventional negative default-cost intercept are in direct
conflict. A positive `d0` makes `max(0, d0*yt + d1*yt**2)` positive everywhere
rather than kinked.

`kappa_risk` is not an alternative lever: it raises spread while sd stays flat,
giving d(sd)/d(spread) = −0.04 against the 2.43 required.

## 7. Grid resolution and `sd`

`p_num = 7` understates `sd(spread)` by **38%** under `va_default_cost = .true.`
but by only **4%** with it off:

| | p=7 | p=277 | p=549 |
|---|---|---|---|
| va ON (`runs_va_final/bm` → `bm277` → `bm`) | 2.9141 | 4.0252 | 4.0063 |
| va OFF (`runs_final/bm` → `runs_vaoff/sub`) | 2.2465 | 2.3367 | — |

277 is converged: 549 agrees within 0.5% on every moment. Consequences:

- the `p_num = 7` sweeps in `runs_kappa/` and `runs_sdf/` are **va-on** and
  cannot be used for sd — `runs_sdf/k3.0`'s apparent sd/spread of 0.485 is an
  artifact;
- `runs_elasticity/` is **va-off** and is not affected;
- the submitted model's low sd is **not** a grid artifact. Re-solved at p=277
  at its own calibration it gives (4.1144, 2.3367, 32.808), confirming
  `FINAL_CALIBRATION.md`'s conclusion that the sd miss is a property of the
  model rather than a search failure.

The two specifications cannot be compared at a shared parameter vector.
Switching va off while holding `beta` = 0.972 and `d1` = 0.46 collapses the
model — spread 0.9462, debt/y 58.5, only 462 qualifying default episodes.

## 8. Quoted from existing notes, not re-verified here

From `VERSIONS_SUMMARY.md` and `PAPER_PREDICTIONS.md`:

- the `exp(h)` volatility bug, 1.86%/qtr against 14.47% in the data;
- FIGURE3's published 3.0 is a measurement artifact — per-state price intervals
  divided by a single vol-3 denominator — and there was never a true 3×;
- FIGURE4d's published +17% to +58% is the grid nodes at a fixed price index,
  with the true Jensen lift about +1.94%. The 1.925% measured in §5 is an
  independent corroboration;
- FIGURE7's welfare sign was wrong in the submitted script: a negative value
  function in the denominator, plus a spurious `scale_y` factor;
- FIGURE7's legend labels are swapped in the published figure.

## 9. What is now stale elsewhere

`VERSIONS_SUMMARY.md` §3 records version 6's welfare at **+0.732%** and its oil
price risk channel at **+206.5 bp**, and §7 recommends that version. Those are
`p_num = 7` numbers. The same specification on the common grid — what was
shipped — gives **+0.129%** and **+286.0 bp**. The welfare gain therefore fell
by roughly 0.6 pp when the version was moved to the common grid, which took
FIGURE7 from comfortably inside the paper's claimed +0.2% to +1.1% range to
just below it. That is recovered at `spdebt` (peak +0.2203%).

`PAPER_PREDICTIONS.md` lists FIGURE6a/6b as never checked in this revision,
while `JEDC_common_grid_final/README.md` counts them among the nine supporting
figures. One of the two is out of date; not resolved here.

## 10. Reproducing

```
model/cal_probe.sh          beta, d0, d1 one at a time          -> runs_cal/
model/predpoint_probe.sh    the Jacobian's predicted point      -> runs_pred/
model/kappa_probe.sh        kappa_risk at -0.5, 0.5, 1.0, 2.0   -> runs_kcal/
model/vaoff_probe.sh        submitted spec at p=277             -> runs_vaoff/
model/bd1_grid.sh           beta x d1 with d0 fixed             -> runs_bd1/
model/spdebt_economies.sh   the other three economies           -> runs_spdebt/
```

Moments: `python3 model/analysis/moments_fast.py <run dirs>`. The benchmark at
the `spdebt` calibration is `model/runs_bd1/spdebt`, not a separate directory.

Welfare and the figure quantities come from `model/analysis/welfare_report.m`
and `model/analysis/claims_report.m`. Each runs `ALL_FIGURES_common_grid.m`
and then prints what §4 and §5 report, so each needs a working directory
holding a copy of that script beside three run folders named `run_benchmark`,
`run_intermediate` and `run_basic` — symlinks are fine. `model/figs_shipped/`
and `model/figs_spdebt/` are those working directories; both are gitignored,
because running the script rewrites `oil_*.mat` and all ten `FIGURE*.jpg` in
whatever directory it is run from. **Never run it inside
`JEDC_common_grid_final/`**, which would overwrite the shipped deliverable.

The four Fortran sources that produced the `spdebt` numbers are kept verbatim
in `model/src_spdebt/`, byte-identical to the `src.f90` in each run directory.
The run directories themselves are regenerable and gitignored.
