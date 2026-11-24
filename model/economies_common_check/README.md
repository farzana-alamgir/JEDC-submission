# The four economies, solved independently — the set of record

This folder holds the four economies that produce the paper's figures and the
R2 M1 / R1 M2 decomposition. It was solved from scratch, by hand, one economy
at a time, rather than through `economies_common/run_all.sh`. It is the set
the figures and tables in the repository now come from.

`economies_common/` is kept as the earlier reference run. Nothing should be
quoted from it.

## Calibration

`beta = 0.971528`, `alpha = 5.779464e-5`, `theta = -3.0` (so
`sigma_oil = 1/(1-theta) = 0.25`), `rho_p = 0.9475`, `rho_p_vol = 0.7382`,
`mean_p = 0.12`, `mean_p_vol = -4.012`, `eta = 0.2889`. Common price grid,
277 nodes.

## The four sources

One file per economy, no configuration switches. Byte-identical to the
corresponding file in `economies_common/`.

| directory | differs from benchmark |
|---|---|
| `benchmark/` | — (full stochastic volatility) |
| `intermediate/` | `std_u_vol = 0`, `p_vol_num = 1` — constant volatility |
| `basic/` | `std_u_p = 0, std_u_vol = 0`, `p_num = 1, p_vol_num = 1` — constant price |
| `mean_preserving/` | one line, 1267: the drift `mp_drift` written inline |

`mean_preserving` differs from `benchmark` by exactly one line:

```fortran
! benchmark
mp_drift = 0d+0
! mean_preserving
mp_drift = -0.5d+0*((std_u_p*exp(p_vol_grid(i)/2d+0))**2 - mean_innov_var)
```

It cancels the `v_k/2` Jensen lift in `E[p'] = exp(cond. mean of log p' + v_k/2)`,
so the mean-preserving economy carries the benchmark's volatility dispersion
with the benchmark's expected price held fixed.

## How it was run

Per economy, from inside that economy's directory:

```bash
gfortran -O3 -march=native -o oil_prod_CES oil_prod_CES_<economy>.f90
./oil_prod_CES > fort.6 2>&1
```

The directory and the `.f90` filename both change per economy. About 35
minutes each on the 277-node common grid.

## Verification against the reference run

All **140** solver output files (35 per economy, four economies) are
**byte-identical** to `economies_common/`. The decomposition tables reproduce
to every digit. The solve is deterministic and this folder reproduces it
exactly.

Eight of the ten rendered figures are byte-identical too. `FIGURE2` and
`FIGURE7` differ, and the figures here are the ones that ship — see below.

## Figures

Rendered by `ALL_FIGURES_common_grid.m` in this directory. The ten `.jpg`
files here are the figures of record; they have been copied to
`model/figs_spdebt/` and `model/` where they are tracked.

**FIGURE7** here is the correct one. Both welfare curves are positive and
properly nested — full-to-basic (0.455% down to 0.339%) above
full-to-intermediate (0.221% down to 0.190%) across the whole output range,
which is what removing strictly more risk has to deliver. In
`economies_common/FIGURE7.jpg` the full-to-intermediate line is pinned flat at
roughly 0.007%, a debt-node artifact.

**FIGURE2** here separates the full and intermediate spread schedules
cleanly; in `economies_common/` they sit nearly on top of each other. The
underlying data are byte-identical, so the difference is entirely in the
plotting script.

**FIGURE6 is unresolved.** The default-threshold panel runs opposite to the
claim in the submitted paper: the threshold shifts *left* at high oil prices
in both volatility states, and the debt slope is 0.92 everywhere rather than
the claimed 0.16 / 0.70. The new direction is the economically sensible one
for an oil importer. Either report the reversal to the referee or drop the
figure — and if it is dropped, the "debt slope 0.16 / 0.70" sentence has to go
with it.

## Moments

| economy | default (annual) | spread | sd spread | debt/GDP | oil/GDP |
|---|---|---|---|---|---|
| full SV (`benchmark`) | 3.345% | 407.9 bp | 299.4 | 34.30 | 9.24 |
| mean-preserving SV | 3.258% | 395.9 bp | 293.6 | 34.10 | 9.26 |
| constant volatility (`intermediate`) | 3.232% | 394.6 bp | 292.9 | 33.94 | 9.28 |
| constant price (`basic`) | 1.666% | 207.3 bp | 161.5 | 36.81 | 10.26 |

Debt/GDP is annualised and taken over value added, `0.25*b/(out-oil)`.

Full tables, including the channel decomposition and the horizon check, in
`results/decomposition_spdebt/`, regenerated from this folder by
`model/analysis/decomposition.py`.

## What is not tracked

The solver output (`graphs_*.txt`, `transition_matrix_p.txt`), the compiled
binary and the `.mod` files are gitignored — about 6 GB. The sources,
`p_grid.txt`, `param_calib.txt`, `fort.6` and the figures are tracked.
Re-solve with the commands above to regenerate the rest.
