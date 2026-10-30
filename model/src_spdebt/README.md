# Common-grid model, recalibrated — Fortran and MATLAB

The common-grid value-added specification with `beta` and `d1` recalibrated.
Same model as `JEDC_common_grid_final/`; only two parameters differ, and `d0`
stays at its submitted value. Fits all four Table 3 moments better and puts
FIGURE7's welfare back inside the paper's claimed range.

## Calibration

| parameter | value | |
|---|---|---|
| `theta` | −2.33333333 | `sigma_oil = 1/(1−theta) = 0.30` |
| `alpha` | 0.000307 | **not** the oil share; the share is `alpha^sigma * p^(1−sigma)` and comes out at 8.92% |
| `beta` | **0.9746** | was 0.972 |
| `d0` | −0.246 | unchanged from the submission |
| `d1` | **0.4731** | was 0.46 |
| `va_default_cost` | `.true.` | default penalty based on value added, not the endowment |
| `use_common_p_grid` | `.true.` | one grid for all volatility states |
| `kappa_risk` | `0` | risk-neutral pricing, as in the submitted model |
| grid | `p_num = 277`, `p_vol_num = 5` | converged: a `p_num = 549` solve agrees within 0.5% on every moment |

Nothing else changed. Diff any of these sources against the corresponding
`JEDC_common_grid_final/oil_prod_CES_*.f90` and only the `beta` and `d1` lines
differ.

## Fit

| moment | target | **this version** | previous (`beta` 0.972, `d1` 0.46) |
|---|---|---|---|
| mean spread (annual, %) | 4.1 | **4.0900** | 4.9336 |
| sd(spread) | 2.0 | 3.6250 | 4.0252 |
| debt/GDP (%) | 34.0 | **34.055** | 33.389 |
| oil/GDP (%) | 9.0 | **8.916** | 8.662 |

Better on all four. Per-moment miss: spread 0.2%, debt 0.2%, oil share 0.9%,
sd 81%.

`sd(spread)` is the one unresolved miss. It is not a search failure: with `d0`
held at −0.246 no combination of `beta` and `d1` brings `sd/spread` below
0.886 against a data target of 0.488, and pushing further lowers sd only by
dragging spread down faster. Reaching sd ≈ 2.3 requires `d0` to go **positive**
(+0.0135), which makes `max(0, d0*yt + d1*yt**2)` positive everywhere instead
of kinked. See `results/VERSION_COMPARISON.md` §6.

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

Benchmark, intermediate and mean-preserving take about 40 minutes each in
parallel; basic is seconds (one price node). Each writes roughly 1.7 GB.

| file | economy |
|---|---|
| `oil_prod_CES_benchmark.f90` | full stochastic volatility |
| `oil_prod_CES_intermediate.f90` | constant volatility at the variance-matching level |
| `oil_prod_CES_mean_preserving.f90` | volatility acts only through dispersion |
| `oil_prod_CES_basic.f90` | constant price |

The basic economy is pinned at `p_grid = 0.316427`, unchanged from the previous
version. That pin has to equal the benchmark's ergodic mean log price, and
`beta` and `d1` do not enter the price process: simulated E[p] is 1.372100 at
`beta` = 0.972, 0.9746 and 0.9847 alike, identical to six decimals.

## Figures

One self-contained MATLAB file, no dependencies, **unchanged** from the
previous version — it reads whatever run folders you point it at and hardcodes
no calibration values:

    >> ALL_FIGURES_common_grid

It expects `run_benchmark`, `run_intermediate` and `run_basic` beside it (edit
the three paths at the top otherwise) and writes all ten `FIGURE*.jpg`.

**Run it in its own directory.** It rewrites `oil_*.mat` and every
`FIGURE*.jpg` wherever it runs, so running it inside another version's folder
overwrites that version's figures.

`MOMENTS.m` prints the four Table 3 moments for a single run folder; set
`RUNDIR` at the top.

## Results

| channel | bp | 95% CI | previous |
|---|---|---|---|
| oil price risk (full − basic) | **+218.9** | ±6.5 | +286.0 ±7.5 |
| time-varying volatility (full − intermediate) | +6.3 | ±8.7 | +7.3 ±10.1 |
| mean-preserving (full − mp) | +3.3 | ±8.9 | +3.2 ±10.3 |

The headline channel is 23% smaller than at the previous calibration, because
it is `benchmark − basic` and this calibration sits at a lower spread level
throughout. As a share of the mean spread it is 54% against 58% before, so the
mechanism is unchanged and only the level moves. The two volatility channels
straddle zero in both calibrations and should not be leaned on.

Welfare, consumption equivalent across the 21 output states at mean debt:

| | this version | previous |
|---|---|---|
| removing all oil price risk — mean | **+0.177%** | +0.129% |
| — peak | **+0.220%** | +0.192% |
| — minimum | **+0.040%** | −0.083% |
| removing time-varying volatility — mean | −0.008% | +0.012% |

Two improvements here. FIGURE7's peak clears the paper's claimed +0.2% floor,
which the previous calibration missed at +0.19% — the one figure recorded as
falling short. And removing oil price risk is now a welfare *gain* at every
output state; previously it was a loss at the three lowest.

The full → intermediate sign flips, but both values are negligible and the
corresponding spread channel is indistinguishable from zero in both
calibrations, so the sign is not a robust feature either way.

Figure claims, re-measured:

| | this version | previous |
|---|---|---|
| FIGURE3 ratio high/low (median) | 1.111 | 1.124 |
| FIGURE3 high ≥ mid ≥ low | **21 of 21** | 20 of 20 |
| FIGURE3 undefined cells | **0 of 63** | 3 of 63 |
| FIGURE2 levels (full, inter, basic) | 4.0995, 4.0838, 2.1225 | 4.6577, 4.6502, 2.5654 |
| FIGURE4d spread across volatility | 1.925% | 1.925% |

FIGURE2 keeps the Full > Intermediate > Basic ordering with Full essentially on
its 4.1 target. FIGURE3 is cleaner than before — monotone at every output state
with no undefined cells. FIGURE4d is identical, as it must be: it depends only
on the price process.

## Provenance

These four sources are byte-identical to the `src.f90` in the run directories
that produced the numbers above — `model/runs_bd1/spdebt` for the benchmark and
`model/runs_spdebt/{intermediate,mean_preserving,basic}` for the rest. They were
generated by `model/bd1_grid.sh` and `model/spdebt_economies.sh` from the master
`model/oil_prod_CES.f90`; edit the master and regenerate rather than editing
these.

The full comparison against the shipped version and the submitted paper is in
`results/VERSION_COMPARISON.md`.
