# Figures 2–7 on the corrected model

Two variants of the same figures, differing only in which two prices the
"low price" / "high price" contrast uses in Figures 3, 6a and 6b.

| directory | low price | high price | nodes (of 549) |
|---|---|---|---|
| `same_prices/` | **1.0119** | **1.2564** | 222, 328 |
| `same_grid_fraction/` | 0.7760 | 1.6383 | 92, 458 |

The submitted figures contrast **1.0120 and 1.2562** (nodes 2 and 6 of the
7-node vol-3 grid). So `same_prices/` is the like-for-like set: any visual
difference from the published figures is the **model**, not a different axis.
`same_grid_fraction/` keeps the original 16.7% / 83.3% grid positions, which at
549 nodes span a wider and arguably more representative range.

Switch with the `CONTRAST_MODE` environment variable (`price` or `fraction`,
default `fraction`).

## The model behind them

Three economies on a **common** price grid at the **submitted** calibration and
elasticity (α = 0.3, θ = 0.5, ρ_p = 0.98, mean_p_vol = −4.33, η = 0.44):

| `.mat` | economy |
|---|---|
| `oil_bm` | full stochastic volatility |
| `oil_intermediate` | constant volatility, σ = √E[v] = 0.018556 |
| `oil_basic` | constant price at **E[p] = 1.1324**, the mean, not the median 1.1275 (R2 Major 2) |

Grid: 549 nodes spanning ±6 sd, prices **[0.644, 1.973]**. That deliberately
matches the reach of the submitted per-state grids, **[0.668, 1.902]** — the old
highest-volatility grid extended to 5.6 unconditional SDs, so a narrower common
grid would truncate the price range and change every figure for the wrong reason.
Resolution ratio is 2.0 in the lowest-volatility state.

## Plotting fixes

Each is verified output-neutral two ways: on `submitted-baseline` inputs the
pipeline reproduces all ten published figures **pixel-identically**; and on an
identical corrected solve, the original script from the `submitted-baseline` tag
and the fixed script agree pixel-identically.

1. ASCII `load` replaced by a `textscan` reader.
2. **Six arrays preallocated** (`spread_matrix`, `spread_matrix_rw`,
   `yield_long`, `yield_rf`, `yield_rf_new`, `tm_p`) — they were assigned inside
   a multi-million-iteration loop without being created first.
   `value_full`/`value_full_debt` are deliberately **not** preallocated: they are
   assigned after the workspace is saved and cleared, so creating them early
   wrote zeros into `oil_*.mat`, which reload as rows and turned the welfare gain
   into a `y_num×y_num` broadcast of `−Inf`.
3. **`i_matrix` hoisted out of the loop nest** — `1./q_matrix` plus a
   logical-indexed NaN assignment over the whole array, recomputed on every one
   of ~2.9M iterations. This was the dominant cost.
4. **`mean_output1/2/3` made dimension-agnostic** (`mean(X(:))`).
5. **Three commented-out `for i_p_vol` loops restored** in the welfare blocks.
   With `p_vol_num = 1` they were harmless; at 5 they returned about a fifth of
   the intended value and the welfare gain read −930%.
6. **Price-node contrast made relative to the grid** (see above), defined after
   the clear/reload so it is never written into `oil_*.mat`.

Together these took a single economy from "did not finish in 2.5 hours" to well
under a minute of plotting time.

One substantive edit, documented in the script: FIGURE2's intermediate series is
indexed `squeeze(spread2(:,11,4,1))`, because the corrected constant-volatility
economy carries `p_vol_num = 5` with all states identical rather than
`p_vol_num = 1`.
