# Figures 2–7 on the corrected model

Regenerated from three economies solved on a **common** price grid (277 nodes, ±3 sd) at
the **submitted** calibration and elasticity. Your published figures in `model/` are
untouched; these are a parallel set for comparison.

| `.mat` | economy | notes |
|---|---|---|
| `oil_bm` | full stochastic volatility | |
| `oil_intermediate` | constant volatility | σ fixed at √E[v] = 0.018555, the benchmark's *average* innovation sd |
| `oil_basic` | constant price | p fixed at **E[p] = 1.1324**, the mean — not the median 1.1275 (R2 Major 2) |

All three share one physical price grid and the same average innovation variance, so the
ladder no longer confounds "less risk" with "cheaper oil".

## What changed versus the published figures

Every figure differs (mean pixel difference 1.8–7.9). The differences come from the model,
not the plotting:

- **the price index now means the same price in every volatility state.** Previously each
  state had its own grid, so a volatility shock rescaled the price *level*. This is what
  made Figure 3's slope ratio a measurement artifact (see `RESPONSE_TO_REFEREES.md` Part B).
- **two simulation bugs fixed**: all 500 panels previously shared one oil-price path, and
  default-period consumption was read at the wrong debt index.
- **the comparison economies are matched** on grid, average risk, and average price level.

Figure 3 changes most (meandiff 7.9), which is expected: it is the figure the grid defect
most directly affected.

## Plotting fixes (all verified output-neutral)

Two independent checks confirm these are output-neutral: (i) on `submitted-baseline`
inputs the pipeline reproduces all ten published figures **pixel-identically**; and (ii) on
an identical corrected-model solve (`p_num = 25`), the original script from the
`submitted-baseline` tag and the fixed script produce **all ten figures pixel-identically**
(maxdiff 0.0). The second check is what caught the `value_full` defect noted below.

1. ASCII `load` replaced by a `textscan` reader. MATLAB's `load` is not the bottleneck it
   appeared to be (2 s for a 219 MB file), but the reader is kept for robustness.
2. **Six arrays preallocated** — `spread_matrix`, `spread_matrix_rw`, `yield_long`,
   `yield_rf`, `yield_rf_new`, `tm_p` were assigned inside a 2.9-million-iteration loop
   without being created first, so MATLAB grew and copied them on every pass.
   `value_full` and `value_full_debt` are deliberately **not** preallocated: they are
   assigned after this workspace is saved and cleared, so creating them early writes zeros
   into `oil_*.mat`, which reload as `1×y_num` rows and turn the welfare gain into a
   `y_num×y_num` broadcast of `-Inf`. That corrupted FIGURE7 in an earlier pass.
3. **`i_matrix` hoisted out of the loop nest.** `i_matrix = 1./q_matrix` plus a
   logical-indexed NaN assignment — over the whole b×y×p×v array — ran inside the
   *innermost* loop, i.e. ~8e12 element operations. This was the dominant cost.
4. **`mean_output1/2/3` made dimension-agnostic** (`mean(X(:))`). The nested-`mean` forms
   collapsed only as many dimensions as the original economies happened to have.

Together these took a single economy from "did not finish in 2.5 hours" to **~25 seconds**.

5. **Price-node indices made relative to the grid.** The "low price" / "high price"
   contrast used in Figures 3, 6a and 6b (and in `dprice`) was hardcoded to nodes 2 and 6.
   Those bracket the grid only at `p_num = 7`; at `p_num = 277` they sit at **0.4% and
   1.8%** of the grid, both deep in the left tail, so the contrast collapses and the
   low-vs-high comparison becomes meaningless. Now defined by relative position
   (16.7% and 83.3%), which reduces to exactly 2 and 6 when `p_num = 7` -- verified, the
   baseline figures stay pixel-identical -- and gives nodes **47 and 231** at `p_num = 277`.

One substantive edit, not output-neutral and documented in the script: FIGURE2's
intermediate series is indexed `squeeze(spread2(:,11,4,1))`. The corrected
constant-volatility economy carries `p_vol_num = 5` with all states identical (rather than
`p_vol_num = 1`), so index 1 is its single volatility level.
