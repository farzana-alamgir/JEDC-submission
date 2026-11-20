# Common-grid model, re-estimated price process, σ_oil = 0.25 — Fortran and MATLAB

The common-grid value-added specification with the oil price process
**estimated from the data**, the CES elasticity set to **0.25**, and `beta`
and `d1` recalibrated to the same targets at those values.

The price process was estimated on 1995Q1–2019Q4 (100 quarters of real WTI,
monthly averaged into quarters and deflated by quarterly CPI) — the same
series as `empirical/oil_qtrly.xlsx`. Previously `rho_p`, `rho_p_vol`,
`mean_p_vol` and `eta` were set by assertion, which left
`sd(dlog oil price)` — a *targeted* Table 3 moment — missing by 1.85
percentage points.

## Calibration

| parameter | value | |
|---|---|---|
| `theta` | **−3.0** | `sigma_oil = 1/(1−theta) = 0.25`; was −2.33333333 (σ = 0.30) |
| `alpha` | **5.779464d-5** | **not** the oil share; the share is `alpha^sigma * p^(1−sigma)` and comes out at 9.24% |
| `beta` | **0.971528** | was 0.970654 |
| `d0` | −0.246 | unchanged from the submission |
| `d1` | **0.468175** | was 0.468505 |
| `va_default_cost` | `.true.` | default penalty based on value added, not the endowment |
| `use_common_p_grid` | `.true.` | one grid for all volatility states |
| `kappa_risk` | `0` | risk-neutral pricing, as in the submitted model |
| grid | `p_num = 277`, `p_vol_num = 5` | converged: a `p_num = 549` solve agrees within 0.5% on every moment |

`alpha` is re-solved whenever `theta` moves, to hold the oil share near its
9% target. With σ < 1 an interior oil optimum requires prices below
`alpha^(-sigma/(1-sigma))`, which is **25.86** here against a grid maximum of
5.27 — a comfortable margin, and no run reports an interior-optimum failure.

### Oil price process

| parameter | calibrated | **estimated** | |
|---|---|---|---|
| `rho_p` | 0.98 | **0.9475** | AR(1) on log real price, se 0.030 |
| `mean_p_vol` | −4.33 | **−4.012** | mean conditional sd 13.45%, not 11.47% |
| `rho_p_vol` | 0.66 | **0.7382** | GARCH(1,1) persistence, mapped to `h` |
| `eta` | 0.44 | **0.2889** | sd(`h`) 0.428, not 0.586 |

`mean_p` stays at 0.12: it is the price normalisation, not an estimate. The
price process does **not** depend on the elasticity, so none of these moved
with the change to σ.

## Fit

| moment | target | **σ = 0.25** | σ = 0.30 |
|---|---|---|---|
| mean spread (annual, %) | 4.1 | **4.0793** | 4.1798 |
| sd(spread) | 2.0 | **2.9937** | 3.1148 |
| debt/GDP (%) | 34.0 | **34.299** | 33.250 |
| oil/GDP (%) | 9.0 | 9.24 | 9.27 |
| sd(dlog oil price) (%) | 14.47 | 14.323 | 14.323 |

σ = 0.25 fits better than σ = 0.30 on three of the five moments and ties on
the two that depend only on the price process. The debt/GDP improvement is
the substantive one: σ = 0.30 missed by 0.75 points, which is outside the
±0.60 tolerance used when recalibrating across elasticities.

`sd(spread)` remains the largest miss at every elasticity tried. It is not a
search failure: with `d0` held at −0.246 no combination of `beta` and `d1`
brings `sd/spread` below 0.886 against a data target of 0.488, and pushing
further lowers sd only by dragging spread down faster. Reaching sd ≈ 2.3
requires `d0` to go **positive** (+0.0135), which makes `max(0, d0*yt +
d1*yt**2)` positive everywhere instead of kinked. See
`results/VERSION_COMPARISON.md` §6.

## Choice of elasticity

**This is a judgement call, not something the model pins down.** Because
`beta` and `d1` are recalibrated at each elasticity to hit the spread and
debt targets, every σ in the table below fits those targets about equally
well. The elasticity therefore has to be defended from outside the model —
on estimates of the short-run price elasticity of oil demand — and the
sensitivity reported. It is reported here.

| σ | spread | debt/GDP | level channel | time-varying vol | *of which* dispersion | *of which* exp. price | welfare (full→basic) |
|---|---|---|---|---|---|---|---|
| 0.20 | 4.1788 | 33.82 | +188.4 | +3.6 | +8.6 | −5.0 | +0.359% |
| **0.25** | **4.0793** | **34.30** | **+200.7** | **+13.4** | **+1.3** | **+12.1** | **+0.468%** |
| 0.30 | 4.1798 | 33.25 | +188.4 | −2.5 | +6.0 | −8.4 | +0.117% |
| 0.35 | 4.1326 | 33.87 | +185.4 | −6.0 | −6.2 | +0.2 | +0.273% |
| 0.40 | 4.0953 | 34.20 | +223.7 | +1.2 | **−22.1** | **+23.3** | +0.205% |
| 0.50 | 3.9581 | 34.36 | +181.3 | −15.7 | −1.1 | −14.6 | +0.078% |

Channels in basis points of mean annual spread. Targets are 4.10 and 34.0.
Produced by `model/elasticity_sweep/recalsweep.sh`, which re-runs the Newton
calibration of (`beta`, `d1`) at each elasticity before measuring anything.

Three things to read off it, and the third matters most:

1. **The level channel is robust.** Removing oil price risk entirely is worth
   181 to 224 basis points at every elasticity. This is the paper's result,
   and it does not depend on σ.
2. **Welfare is not monotone in σ** and σ = 0.25 is near its peak. Any claim
   about the size of the welfare gain is a claim about the elasticity as much
   as about oil risk, and should be stated with this table beside it.
3. **The dispersion / expected-price split is not robust, while the total it
   sums to stays small.** Dispersion reads +8.6, +1.3, +6.0, −6.2, −22.1,
   −1.1 bp across the six elasticities, with no monotone relation to σ and a
   range of 31 bp. Against a 95% interval of roughly ±6 bp, four of the six
   are indistinguishable from zero, but σ = 0.35 and especially σ = 0.40 are
   not. The clearest case is σ = 0.40, where the two components are **−22.1
   and +23.3** and cancel almost exactly to a total of +1.2 bp. Two large,
   offsetting, oppositely signed components summing to nothing is not a
   decomposition anyone should quote.

   The reason is in `results/LETTER_CHECK.md` and the horizon table: at
   ρ_p = 0.9475 the one-step mean-preserving correction overshoots at the
   horizons where long-term debt is priced (residual/effect = −1.35 at 20
   quarters), so the corrected economy is not a clean counterfactual. That is
   a property of the estimated price process and does not change with σ.
   **The time-varying-volatility result is therefore not recoverable by
   choosing an elasticity.** At σ = 0.25 the +13.4 bp total is +12.1
   expected-price and +1.3 dispersion — i.e. almost entirely the component
   R2 (Major 1) and R1 (Major 2) asked to have removed.

The ±6 bp intervals quoted here are measured at σ = 0.25 by
`model/analysis/decomposition.py`; the other elasticities' channels are point
estimates from `model/elasticity_sweep/results.txt` without their own
intervals.

## Running it

Four economies, each in its **own folder** — they all write the same output
filenames, so sharing a directory silently overwrites.

    mkdir -p run_benchmark run_intermediate run_mean_preserving run_basic
    for e in benchmark intermediate mean_preserving basic; do
      ( cd run_$e \
        && gfortran -O3 -march=native ../oil_prod_CES_$e.f90 -o oil_prod_CES \
        && ./oil_prod_CES > fort.6 2>&1 \
        && echo "$e done" ) &
    done
    wait

Benchmark, intermediate and mean-preserving take about 35 minutes each in
parallel; basic is seconds (one price node). Each writes roughly 1.7 GB.

| file | economy |
|---|---|
| `oil_prod_CES_benchmark.f90` | full stochastic volatility |
| `oil_prod_CES_intermediate.f90` | constant volatility at the variance-matching level |
| `oil_prod_CES_mean_preserving.f90` | volatility acts only through dispersion |
| `oil_prod_CES_basic.f90` | constant price |

The basic economy's price pin is the **formula**,
`p_grid = mean_p + 0.5*mean_innov_var/(1 - rho_p**2)`, rather than the
hardcoded `0.316427`. That literal was the log of the ergodic mean price under
the *old* process; under the estimated one the value is 0.217000. Left unfixed
it would have made the level channel measure a price difference between the
two economies rather than the effect of price risk.

The pin is the **log of the benchmark's ergodic mean price level**, not the
mean of its log price — the two differ by `var(log p)/2`, which is 0.097 here
(E[log p] is 0.1205). Setting it the other way would give the constant-price
economy a systematically cheaper oil bill. Verified against the simulation:
the pin gives a price of 1.242344 and the benchmark's simulated mean price
level is 1.242941, agreeing to 0.05%.

Neither `beta`, `d1` nor the elasticity enters the price process, so the pin
does not move with the recalibration.

## Figures

One self-contained MATLAB file, no dependencies — it reads whatever run
folders you point it at and hardcodes no calibration values:

    >> ALL_FIGURES_common_grid

It expects `run_benchmark`, `run_intermediate` and `run_basic` beside it (edit
the three paths at the top otherwise) and writes all ten `FIGURE*.jpg`.

**Run it in its own directory.** It rewrites `oil_*.mat` and every
`FIGURE*.jpg` wherever it runs, so running it inside another version's folder
overwrites that version's figures.

`MOMENTS.m` prints the five Table 3 moments for a single run folder; set
`RUNDIR` at the top.

## Results

| channel | bp | previous (σ = 0.30) |
|---|---|---|
| oil price risk (full − basic) | **+200.7** | +188.4 |
| time-varying volatility (full − intermediate) | +13.4 | −2.5 |
| of which dispersion (mean-preserving − intermediate) | +1.3 | +6.0 |
| of which expected price (full − mean-preserving) | +12.1 | −8.4 |

The headline channel is 6.5% larger than at σ = 0.30 and is 49% of the mean
spread. The volatility channels should not be leaned on: see point 3 under
*Choice of elasticity*.

Welfare, consumption equivalent across the 21 output states at mean debt
(debt node 44, CRRA σ = 2):

| | **σ = 0.25** | σ = 0.30 |
|---|---|---|
| removing all oil price risk — mean | **+0.468%** | +0.177% |
| — peak | **+0.555%** | +0.220% |
| — minimum | **+0.338%** | +0.040% |
| removing time-varying volatility — mean | +0.0055% | −0.008% |

The welfare claim in the paper (+0.2% to +1.1%) holds at **every one of the
21 output states** at this elasticity; at σ = 0.30 the mean fell below the
stated floor and only the peak cleared it. Note what this measures: removing
*all* oil price risk, which is the level channel. Removing time-varying
volatility alone is worth +0.006%, i.e. nothing, as it was at σ = 0.30.

The welfare numbers are evaluated at a **fixed debt node** (44) in every
economy. Because the economies sit at different average debt levels — the
constant-price economy borrows to 36.8% against the benchmark's 34.3% — that
node is not the same point in each one's distribution. This is the likely
source of the non-monotonicity in the sensitivity table, and it is unresolved.

Figure claims, re-measured:

| | **σ = 0.25** | σ = 0.30 |
|---|---|---|
| FIGURE2 mean spreads (full, inter, basic) | 4.0793, 3.9458, 2.0728 | 4.1798, 4.2043, 2.2960 |
| FIGURE4d expected *oil price* range across volatility states | 1.925% | 1.925% |

FIGURE3 depends on which price contrast the slopes are measured over, so both
are reported. `CONTRAST_MODE = 'price'` is the **final set**; `'fraction'` is
a robustness cut.

| FIGURE3, σ = 0.25 | `price` (final) | `fraction` (robustness) |
|---|---|---|
| contrast | 1.0120 → 1.2562 (1.24×) | 0.4034 → 3.1510 (7.81×) |
| ratio high/low at median output | **1.1347** | 1.1958 |
| ratio high/low, mean over states | 1.1714 | 1.1756 |
| high ≥ mid ≥ low | **21 of 21** | 14 of 14 |
| output states with a defined slope | **21 of 21** | **14 of 21** |
| slopes low/mid/high at median (bp) | 94.2 / 100.0 / 106.8 | 84.4 / 91.6 / 100.9 |

The case for `price` is the last two rows, not the ratio: the two contrasts
give nearly the same ratio here, but the wide one leaves seven of twenty-one
output states with no defined slope, because a 7.8× price swing runs off the
usable part of the grid. The narrow contrast is also the one the submitted
figures used (1.0119 → 1.2564, dp 0.2441, against 0.2442 here).

A previously recorded 1.13-versus-4.44 split between these two contrasts does
**not** reproduce at this calibration; that was measured on the 549-node grid
in an earlier configuration. The σ = 0.30 figure quoted 1.111, measured under
`fraction`, so it compares with 1.1958 rather than with 1.1347.

FIGURE2 recovers the Full > Intermediate > Basic ordering, which σ = 0.30 did
not: there the full economy's mean spread sat *below* the constant-volatility
one. On the plotted schedules the two curves are within a line width of each
other and cross at high debt in both versions — at σ = 0.30 the crossing falls
below the calibrated debt level, at σ = 0.25 just above it. FIGURE4d is
unchanged, as it must be: it depends only on the price process.

FIGURE3 slopes use a denominator common to all three volatility states. The
submitted figure used a per-state denominator, which inflated the gap by about
3.2×.

## Provenance

These four sources are byte-identical to the `src.f90` in the run directories
that produced every number above. Verified with `cmp`, not by inspection.

## Outstanding

Done in the move to σ = 0.25: the four sources, the ten figures, the
decomposition and horizon outputs under `results/decomposition_spdebt/`, the
95% simulation intervals, the R2 Major 1 / R1 Major 2 letter, and all six
elasticities in the sensitivity table.

Still **not** done:

- **The fixed-debt-node issue in the welfare comparison**, described under
  *Results*. All CEV figures here evaluate at debt node 44 in economies that
  sit at different average debt. Until that is addressed, the welfare
  comparison *across elasticities* is suspect, and the non-monotonicity in the
  sensitivity table may be an artifact rather than a result. The within-economy
  comparison at a fixed elasticity is unaffected.
- **The fixed-state spread comparison** the letter previously reported (37 and
  51 bp). `model/analysis/referee_mean_preserving_spdebt.py` requires numpy,
  which is not installed in the current environment, and its saved outputs
  under `results/referee_mean_preserving_spdebt/` date from 2026-11-01 and are
  at the old calibration. The letter now relies on the by-volatility table
  instead, which answers the same question with a larger sample.
- **`results/ELASTICITY_SWEEP.md`** is superseded — it reports the per-state
  grid — and should be replaced by `model/elasticity_sweep/`.
- The remaining referee comments beyond R2 M1 / R1 M2.
