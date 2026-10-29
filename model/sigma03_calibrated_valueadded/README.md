# Version 6 — value-added default cost, sigma_oil = 0.30

Self-contained, ready-to-compile sources, one per economy, with every
calibrated parameter baked in. Nothing to edit.

    gfortran -O3 -march=native -o solver oil_prod_CES_bm.f90
    ./solver

About 50 seconds per economy, writing ~190 MB of `graphs_*.txt` into the
working directory — run each in its own folder.

## Calibration

| parameter | value | note |
|---|---|---|
| `theta` | −2.33333333 | `sigma_oil = 1/(1−theta) = 0.30` |
| `alpha` | 0.000307 | **not** the oil share; the share is `alpha^sigma * p^(1−sigma)` and comes out at 8.73% |
| `beta` | 0.972 | |
| `d0` | −0.246 | unchanged from the submission |
| `d1` | 0.46 | |
| `va_default_cost` | `.true.` | the one modelling change — see below |
| `kappa_risk` | `0` | **risk-neutral pricing, exactly as in the submitted model** |
| grid | `p_num = 7`, per-state Rouwenhorst | the submitted grid construction |

Fit: mean spread 4.41 (target 4.1), sd 2.91 (2.0), debt/GDP 33.69 (34.0),
oil/GDP 8.73% (9.0%). Simulated oil price volatility 14.63% against 14.47% in
the data.

## What differs from the submitted model

Exactly two things.

**1. The default penalty base.** The submitted penalty is

    max(0, d0*EXP(y) + d1*EXP(y)**2)

a function of the ENDOWMENT alone, so the oil price never enters the default
decision except through the consumption level common to both branches. With
`rho_p = 0.98` an oil price shock is nearly permanent and shifts the value of
repaying and of defaulting almost equally, so the default margin barely moves
— which is why oil channels came out at a few basis points.

With `va_default_cost = .true.` the base is normalised VALUE ADDED,
`(Y − p*m)/scale_y`, evaluated at the NO-DEFAULT TFP. Value added shrinks when
oil is expensive, so a higher oil price lowers the absolute cost of defaulting.
Evaluating it at the undamaged TFP is what keeps this a two-pass calculation
rather than a fixed point, and matches how default costs are normally
described: a share of the output the country would otherwise have produced.
Implemented as `va_norm()` and `defloss()` in `module param`.

**2. The oil elasticity**, `theta` 0.5 → −2.33333333, with `alpha`, `beta` and
`d1` recalibrated to Table 3.

Everything else is identical: Eaton–Gersovitz structure, long-term debt
(`delta = 0.03`), CES production, the stochastic-volatility oil process, CRRA
`sigma = 2`, and risk-neutral bond pricing. `va_default_cost = .false.`
reproduces the previous baseline byte-identically.

## The six economies

| file | what it is |
|---|---|
| `oil_prod_CES_bm.f90` | **benchmark** — full stochastic volatility |
| `oil_prod_CES_mp.f90` | mean-preserving: volatility acts only through dispersion |
| `oil_prod_CES_intermediate.f90` | constant volatility at the variance-matching level |
| `oil_prod_CES_basic.f90` | constant price, pinned at the theoretical ergodic mean |
| `oil_prod_CES_intermediate_matched.f90` | as `intermediate`, `mean_p` shifted so simulated `E[p]` equals the benchmark's |
| `oil_prod_CES_basic_matched.f90` | as `basic`, pinned at the benchmark's simulated `E[p]` |

**Use the `_matched` pair for any welfare or spread decomposition.** The
unmatched versions face oil 1.7% and 3.0% dearer than the benchmark, which is
enough to invert the welfare ranking at `sigma_oil = 0.30`. All matched
economies are verified at `E[p] = 1.3339`.

## Headline results

| | value |
|---|---|
| oil price risk (full − basic, matched) | **+206.5 bp** |
| spread response to a 20% oil price move | **43 bp** (4 bp under the submitted penalty) |
| debt amplification | **112 → 286 bp** across the debt grid |
| welfare, remove all oil price risk | **+0.732%** (claimed range +0.2% to +1.1%) |
| welfare, remove time-varying volatility | +0.175% |

## Figures

MATLAB, in `model/figures_pipeline/`:

    cd model/figures_pipeline
    CONTRAST_MODE=fraction bash run_all_va_final.sh

That stages each run directory in turn and runs `script_intermediate.m`,
`script_basic.m`, then `script_bm.m`, writing all ten `FIGURE*.jpg`.
`script_bm.m` draws every figure and loads the other two workspaces for
FIGURE2 and FIGURE7, which is why it must run last. Edit the `stage` lines if
your solved directories are not under `model/runs_va_final/`.

Supporting files: `fastload.m` (textscan reader for the large ASCII dumps),
`ink_optionA.m` (blank-panel detector), `run_all_va_final.sh` (driver).

Reference output: `results/figures_valueadded/`, tagged
`figures-valueadded-kappa0`.

## Provenance

Generated from the single master source `model/oil_prod_CES.f90` by
`model/solve_va_final.sh`. **Edit the master, not these** — the economies are
kept in sync there by compile-time switch rather than by forking. Regenerate
after any master change.
