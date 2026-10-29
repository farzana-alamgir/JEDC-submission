# Common-grid model — Fortran and MATLAB

The version used for the final figure set: value-added default cost,
`sigma_oil = 0.30`, solved on **one price grid shared by every volatility
state**. These are the exact sources that produced
`results/figures_common_v6/`.

## Calibration

| parameter | value | |
|---|---|---|
| `theta` | −2.33333333 | `sigma_oil = 1/(1−theta) = 0.30` |
| `alpha` | 0.000307 | **not** the oil share; the share is `alpha^sigma * p^(1−sigma)` and comes out at 8.66% |
| `beta` | 0.972 | |
| `d0` | −0.246 | unchanged from the submission |
| `d1` | 0.46 | |
| `va_default_cost` | `.true.` | default penalty based on value added, not the endowment |
| `use_common_p_grid` | `.true.` | one grid for all volatility states |
| `kappa_risk` | `0` | risk-neutral pricing, as in the submitted model |
| grid | `p_num = 277`, `p_vol_num = 5` | 4.0 nodes per conditional sd in the tightest volatility state |

Fit: mean spread 4.93 (target 4.1), sd 4.03 (2.0), debt/GDP 33.39 (34.0),
oil/GDP 8.66% (9.0%).

## Running it

Four economies, each in its **own folder** — they all write the same output
filenames, so sharing a directory silently overwrites.

    mkdir run_benchmark && cd run_benchmark
    gfortran -O3 -march=native -o solver ../oil_prod_CES_benchmark.f90
    ./solver
    cd ..

Repeat with `run_intermediate`, `run_mean_preserving`, `run_basic` and the
matching source. Times on one core: benchmark, intermediate and
mean-preserving about **35 minutes** each; basic is seconds (one price node).
Each writes roughly 1 GB.

| file | economy |
|---|---|
| `oil_prod_CES_benchmark.f90` | full stochastic volatility |
| `oil_prod_CES_intermediate.f90` | constant volatility at the variance-matching level |
| `oil_prod_CES_mean_preserving.f90` | volatility acts only through dispersion |
| `oil_prod_CES_basic.f90` | constant price |

The basic economy is pinned at `p_grid = 0.316427`, i.e. `log(1.3721)`, the
benchmark's **simulated** ergodic mean price on this grid. That matters: Tauchen
on the common grid gives E[p] = 1.3721 while Rouwenhorst on the per-state grid
gives 1.3339, so a basic economy carried over from the per-state calibration
would face oil 2.8% cheaper than its own benchmark and the comparison would
pick up a price level rather than the absence of risk. All four economies here
agree on E[p] to within 0.06%.

## Figures

One self-contained MATLAB file, no dependencies:

    >> ALL_FIGURES_common_grid

It expects the run folders named `run_benchmark`, `run_intermediate` and
`run_basic` beside it (edit the three paths at the top otherwise), and writes
all ten `FIGURE*.jpg`. `FIG2_MIDDLE_LABEL` sets the legend for FIGURE2's middle
line, so pointing `RUN_MIDDLE` at `run_mean_preserving` draws that comparison
instead.

## Results

| channel | bp | 95% CI |
|---|---|---|
| oil price risk (full − basic) | **+286.0** | ±7.5 |
| time-varying volatility (full − intermediate) | +7.3 | ±10.1 |
| mean-preserving (full − mp) | +3.2 | ±10.3 |

Welfare, consumption equivalent: removing all oil price risk **+0.129%**,
removing time-varying volatility +0.012%.

Nine of the ten figures support the paper. FIGURE2 orders Full > Intermediate
> Basic; FIGURE3 has high volatility steepest with a ratio of 1.12, confirmed
grid-converged against a `p_num = 549` solve (medians 1.120 and 1.119);
FIGURE4d is flat across volatility, as it should be on a shared grid.

The exception is FIGURE7: welfare is +0.19% in the figure, just below the
paper's claimed +0.2% to +1.1%. On the per-state grid it is +0.73%, inside the
range, but there FIGURE2, FIGURE3 and FIGURE4d all fail. No single grid
delivers both — Tauchen loses variance at `rho_p = 0.98`, which is the same
reason the per-state grid reproduces the oil process better (14.63% against
12.61%, data 14.47%).

## Provenance

Copied verbatim from `model/runs_common_v6/{bm277,int_c,mp_c,basic_c}/src.f90`,
the sources that actually ran. They derive from the master
`model/oil_prod_CES.f90` on the `corrected-volatility` branch; edit the master
and regenerate rather than editing these.
