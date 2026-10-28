# Calibrated model at sigma_oil = 0.30

Joint (beta, d0, d1) search at the low oil elasticity, 53 parameter triples.
Runs in `model/runs_final/`, figures in `results/figures_final/`, search log in
`results/calib_sigma03.csv`.

## Parameters

| | submitted | **calibrated** |
|---|---|---|
| `theta` | 0.5 | **−2.33333333** |
| `sigma_oil = 1/(1−theta)` | 2.0 | **0.30** |
| `alpha` | 0.3 | **0.000188992** |
| `beta` | 0.96 | **0.964** |
| `d0` | −0.246 | −0.246 *(unchanged)* |
| `d1` | 0.3847 | **0.37** |

`beta` is the dominant lever: 0.96 → 0.97 moves the spread 5.17 → 2.97 and
debt 34.7 → 31.7 at fixed `d0`, `d1`. `d1` trades spread against debt. `d0`
did not need to move from its submitted value.

## Fit

| moment | target | **calibrated** | sigma=2 (Option A) |
|---|---|---|---|
| mean spread (annual, %) | 4.1 | **3.99** | 4.21 |
| sd(spread) | 2.0 | **2.25** | 2.33 |
| debt/GDP (%) | 34.0 | **33.41** | 42.74 |
| oil share of GDP (%) | 9.0 | **8.73** | 9.95 |

Better than the sigma=2 calibration on three of four, and dramatically so on
debt/GDP (33.4 against 42.7, target 34.0). The one persistent miss is
sd(spread), 12% high — the model's spread is more volatile relative to its
mean than the data's at every point searched (the lowest sd/spread ratio found
was 0.516 against the data's 0.488), so this is a property of the model, not a
search failure.

Methodology note: the search scored with `analysis/moments_fast.py`, which
reproduces `sim_prod_oil_dec29.m` **exactly** on all four moments but in 2
seconds rather than 90. That script does not report unconditional means — it
averages over the 100 quarters *preceding* each qualifying default episode
(`per_before = 100`, `per_after = -1`, episodes separated by >101 periods, no
exclusion 101 quarters earlier). An unconditional mean differs by ~0.3pp,
which is enough to miss the target.

## Welfare — the paper's claim holds

**Report the level-matched column.** The comparison economies must be pinned
at the benchmark's *simulated* mean price, not at the theoretical one.

| comparison | as-built | **level-matched** | paper |
|---|---|---|---|
| full → intermediate (remove time-varying vol) | +0.245% | **+0.302%** | |
| full → basic (remove all oil price risk) | +0.202% | **+0.516%** | +0.2% to +1.1% |

All positive and inside the claimed range. At `sigma_oil = 2` these were
+0.15% and −2.78%.

### Why the as-built column is misleading

As built, `full → intermediate` (+0.245%) exceeds `full → basic` (+0.202%),
i.e. removing *part* of the risk appears to beat removing *all* of it. That is
an artifact, not a result.

`basic` pins log p at the **theoretical** ergodic mean,
`exp(mean_p + 0.5*Var(log p)/(1-rho_p^2)) = 1.3735`. But Rouwenhorst matches
log-moments, not level moments, so the benchmark's **simulated** mean price is
1.3339. The comparison economies therefore face dearer oil than the benchmark:

| economy | E[p] | vs bm | welfare cost of the gap |
|---|---|---|---|
| bm | 1.3339 | — | — |
| intermediate | 1.3562 | +1.67% | 0.058pp |
| basic | 1.3735 | +2.97% | 0.314pp |

At `sigma_oil = 0.30` oil is complementary, so the country cannot substitute
away from a higher price level and the gap is costly. `basic` has the larger
gap and so loses more, which inverted the ranking. Re-pinning both at 1.3339
(`basic_matched`, `intermediate_matched`) restores the correct, nested
ordering: +0.516% for all risk, of which +0.302% is the time-varying part and
+0.214% the residual constant-volatility dispersion.

The same correction matters for the spread decomposition (§ below), where it
moved the oil-price-risk channel from +23.3 to +7.1 bp at `sigma_oil = 2`.

## Spread decomposition — small, and the Jensen channel dominates

Standard errors are across default episodes; a channel is a difference of two
means, so the CI is on that difference.

| channel | bp | 95% CI | |
|---|---|---|---|
| oil price risk (vs matched E[p]) | −8.4 | ±4.6 | significant, **negative** |
| oil price risk (vs standard basic) | +2.1 | ±4.5 | not distinguishable from 0 |
| time-varying volatility | +5.6 | ±5.2 | marginal |
| **mean-preserving (first-moment/Jensen)** | **+26.6** | **±5.2** | **significant** |

The economically meaningful spread channel at `sigma_oil < 1` is the
**first-moment** one: higher volatility raises `E[p']` by Jensen, the country
cannot substitute away from dearer expected oil, default risk rises, and the
spread rises 26.6 bp. Removing the dispersion while holding `E[p']` fixed (the
mean-preserving economy) is what strips that out.

Note the tension to be explicit about in the paper: oil price risk is
**welfare-costly** (+0.20%) while its *pure dispersion* effect on the spread is
small and slightly negative. These are not contradictory — welfare is a
value-function comparison, the spread is a default-probability comparison —
but the paper should not claim both run through the same channel.

## The four claims

| claim | paper | **calibrated** | sigma=2 |
|---|---|---|---|
| [1] spread-slope state dependence | 3.0 | **0.79** | 0.64 |
| [2] debt amplification | larger when indebted | **confirmed**, 14.6→43.7 bp | confirmed, 19→198 bp |
| [3] debt slope by vol state | 0.16/0.25/0.70 | not measurable | not measurable |
| [4] welfare | +0.2% to +1.1% | **+0.30% / +0.52%** (level-matched) | −2.78% |

**[1] still does not hold.** The ratio is 0.79 — below 1 at all 19 output
points, so low volatility has the *steeper* slope. And on this grid the ratio
is not identified in either direction (see §6 of `SUMMARY_OPTION_A.md`), so
0.79 is not a point estimate either. This claim cannot be supported.

**[2] holds**, with a 3× range across the debt grid.

**[3] remains unmeasurable** at `p_num = 7`: the ±10% price contrast falls
inside a single grid cell in every volatility state.

## Figures — audit

Use **`results/figures_final_matched/`**: the level-matched set, drawn with
`intermediate_matched` and `basic_matched`. `results/figures_final/` is the
same calibration with the unmatched comparison economies and carries the
inverted welfare ranking described above.

All ten drawn, no blank or sparse panels.

### Usable

| figure | what it shows |
|---|---|
| **5** | debt amplification: High > Mean > Low Debt slope. The paper's strongest claim. |
| **7** | welfare: Basic +0.53%, Intermediate +0.31%, both positive and correctly nested. |
| **4a, 4b, 4c** | spread rising in the oil price, monotone and smooth. |
| **6a, 6b** | debt policy functions; low oil price borrows more, clean default thresholds. |

### Problematic

**FIGURE2 — contradicts the paper.** The Basic schedule now sits *above* Full
and Intermediate, i.e. removing oil price risk *raises* the spread schedule.
That is consistent with the measured channel (−8.4 ± 4.6 bp) but is the
opposite of the paper's claim. Drop it, or re-cast it around the
mean-preserving comparison, which is significant and correctly signed at
+26.6 ± 5.2 bp.

**FIGURE3 — not identified, and ordered against the claim.** Low volatility is
steepest (ratio 0.79 against a claimed 3.0). See §6 of
`SUMMARY_OPTION_A.md`: on per-state grids the slope is a chord whose span is
set by that state's node spacing, so the ratio is not identified in either
direction.

**FIGURE4d — a grid artifact.** It conditions on fixed node indices 2/4/6, and
on per-state grids those are different physical prices in each volatility
state:

| curve | state 1 | state 5 | ratio |
|---|---|---|---|
| "low price" (node 2) | 0.6675 | 0.2078 | 3.21x |
| "mean price" (node 4) | 1.1275 | 1.1275 | **1.00x** |
| "high price" (node 6) | 1.9045 | 6.1190 | 3.21x |

The flat middle curve is the control: node 4 is the only node identical across
states, and it is the only curve that does not move. The outer curves diverge
because the conditioning price moves with volatility, not because `E[p']`
responds to it. Fixing this needs the same matched-price interpolation applied
to FIGURE3/FIGURE5, on `transition_matrix_joint`.

### Presentational fixes applied

FIGURE3 and FIGURE5 had hardcoded y-limits (0.09 and 0.35) set at the
submitted calibration. At `sigma_oil = 0.30` the slopes run an order of
magnitude smaller and both panels were crushed onto the axis. Both now
autoscale, capped at the submitted limit so they never zoom out past the
published scale. FIGURE7's legend moved off the upper curve.

## Honest summary

The low elasticity buys the welfare result and a much better debt/GDP fit, and
costs FIGURE2. The spread-slope state dependence (FIGURE3) is not recoverable
at any elasticity tested and is not identified on the submitted grid. Debt
amplification is robust throughout and is the paper's strongest claim.
