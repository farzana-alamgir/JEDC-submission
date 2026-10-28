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

| comparison | CEV | paper |
|---|---|---|
| full → basic (remove all oil price risk) | **+0.202%** | +0.2% to +1.1% |
| full → basic, matched E[p] | **+0.516%** | |
| full → intermediate (remove time-varying vol) | **+0.245%** | |

All positive and all inside the claimed range. FIGURE7 shows both curves at
+0.21% to +0.26%, rising in output. At `sigma_oil = 2` these were −2.78% /
−3.03% / +0.15%.

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
| [4] welfare | +0.2% to +1.1% | **+0.20% to +0.52%** | −2.78% |

**[1] still does not hold.** The ratio is 0.79 — below 1 at all 19 output
points, so low volatility has the *steeper* slope. And on this grid the ratio
is not identified in either direction (see §6 of `SUMMARY_OPTION_A.md`), so
0.79 is not a point estimate either. This claim cannot be supported.

**[2] holds**, with a 3× range across the debt grid.

**[3] remains unmeasurable** at `p_num = 7`: the ±10% price contrast falls
inside a single grid cell in every volatility state.

## Figures

All ten drawn, no blank or sparse panels (`results/figures_final/`).

- **FIGURE7 matches the paper** — both curves positive.
- **FIGURE2 does not separate.** Full, Intermediate and Basic lie on top of
  one another, which is exactly what a +2.1 bp (±4.5) channel should look
  like. At `sigma_oil = 2` Basic sat visibly below. This figure no longer
  carries a message and should either be dropped or re-cast around the
  mean-preserving comparison, which *is* significant at +26.6 bp.
- **FIGURE3** keeps the low-volatility-steepest ordering.

## Honest summary

The low elasticity buys the welfare result and a much better debt/GDP fit, and
costs FIGURE2. The spread-slope state dependence (FIGURE3) is not recoverable
at any elasticity tested and is not identified on the submitted grid. Debt
amplification is robust throughout and is the paper's strongest claim.
