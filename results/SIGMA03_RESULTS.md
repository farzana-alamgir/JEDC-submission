# All economies solved at sigma_oil = 0.30

`theta = -2.33333333`, `alpha = 0.000188992`, everything else as in Option A
(per-state Rouwenhorst grid, `p_num = 7`, `d1 = 0.3847`, CRRA `sigma = 2`).

Runs in `model/runs_sigma03/` (bm, mp, intermediate, basic, basic_matched),
figures in `results/figures_sigma03/`.

---

## 1. The welfare claim is recovered

| comparison | CEV | paper |
|---|---|---|
| full → basic (remove all oil price risk) | **+0.193%** | +0.2% to +1.1% |
| full → basic, matched E[p] | **+0.489%** | |
| full → intermediate (remove time-varying vol) | **+0.038%** | |

**All three are positive**, so oil price uncertainty is costly in this
calibration, which is the paper's claim. FIGURE7 now shows both curves above
zero (+0.21% and +0.04%) against the submitted figure's shape. At
`sigma_oil = 2` the same quantities were −2.78% / −3.03% / +0.15%.

## 2. A side benefit: feasibility is clean

Zero infeasible price nodes. At `sigma_oil = 0.30` the CES ceiling is 39.4,
far above the grid maximum of 14.25, so none of the masking that `sigma = 2`
required applies here — masked and unmasked mean output are identical
(9.4933). The 31 NaN-ed simulated rows are gone too.

## 3. Moments are OFF target, because d0/d1/beta were not recalibrated

| moment | target | sigma 0.30 | sigma 2.00 |
|---|---|---|---|
| mean spread | 4.1 | 4.72 | 4.21 |
| sd(spread) | 2.0 | 2.43 | 2.33 |
| debt/GDP | 34.0 | 39.59 | 42.74 |
| oil/GDP | 9.0 | 8.67 | 9.95 |
| default rate | — | 1.75% | 1.63% |

A `d1` line search does **not** fix this — it trades the spread against debt:

| d1 | spread | sd | debt/GDP |
|---|---|---|---|
| 0.3847 | 4.72 | 2.43 | 39.6 |
| 0.400 | 4.36 | 2.21 | 45.3 |
| 0.405 | 4.45 | 2.64 | 47.4 |
| 0.410 | 4.27 | 2.37 | 49.2 |
| 0.450 | 0.33 | 0.45 | — (collapses) |

Debt deteriorates faster than the spread improves, and the spread is not
monotone across 0.40–0.41, so those differences are at the simulation noise
level (~±0.1). **A joint (beta, d0, d1) recalibration is required before these
moments can be reported.** `d1` above 0.42 collapses the model.

## 4. Decomposition

| channel | sigma 0.30 | sigma 2.00 |
|---|---|---|
| oil price risk (full − basic, matched E[p]) | +25.2 bp | +7.1 bp |
| time-varying volatility (full − intermediate) | −13.7 bp | −25.3 bp |
| mean-preserving (full − mp) | +34.2 bp | −1.5 bp |

The mean-preserving channel becomes large and positive: at `sigma_oil < 1` the
first-moment (Jensen) effect of volatility on `E[p']` matters, because the
country cannot substitute away from dearer expected oil. Read these with the
caveat in §3 — the economies are not on their calibration targets.

## 5. The four claims

| claim | paper | sigma 0.30 | sigma 2.00 |
|---|---|---|---|
| [1] spread-slope state dependence | 3.0 | **0.82** | 0.64 |
| [2] debt amplification | larger when indebted | **confirmed**, 10.2→21.2 bp | confirmed, 19→198 bp |
| [3] debt slope by vol state | 0.16/0.25/0.70 | not measurable | not measurable |
| [4] welfare | +0.2% to +1.1% | **+0.19% to +0.49%** | −2.78% |

**[1] does not flip.** Lowering the elasticity moves the ratio from 0.64 to
0.82 — toward 1, but still below it, and below 1 at all 21 output points. The
ordering in FIGURE3 is unchanged: low volatility steepest. The identification
problem of §6 in `SUMMARY_OPTION_A.md` still applies, so 0.82 should not be
read as a point estimate either.

**[2] survives but weakens sharply**, from a 10× range across the debt grid at
`sigma_oil = 2` to a 2× range here.

---

## 6. What the figures look like

All ten drawn, no blank or sparse panels.

- **FIGURE7 gains the paper's result** — both welfare curves are now positive.
- **FIGURE2 loses its message.** At `sigma_oil = 2` the Basic schedule sat
  clearly below Full and Intermediate; here all three overlap, consistent with
  a +25 bp channel being invisible on a 1.5–5% axis.
- **FIGURE3 is unchanged in ordering**, and its slope level drops by an order
  of magnitude (0.001–0.005 against 0.002–0.09). The hardcoded `ylim([0 0.09])`
  crushed all three curves onto the axis, so FIGURE3 now autoscales in both
  contrast modes, capped at the submitted 0.09 so it never zooms out further
  than the published figure.

**The trade is real: `sigma_oil = 0.30` buys FIGURE7 and costs FIGURE2.**
Neither elasticity delivers both, because the two figures report different
things — FIGURE7 the sign of the welfare effect, which is governed by the
Waugh convexity and so by the elasticity, and FIGURE2 the size of the spread
level effect, which is larger when oil is a bigger share of marginal cost.
