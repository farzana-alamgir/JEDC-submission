# R1 Major 4 and R1 Major 1c — the whole chain

Everything for these two comments is in this folder: the scripts that build
the data, the data they build, the source series, the tables, and the
byproducts of the rebuild under `workings/`. The only files read from outside
are the paper's own inputs in `empirical/`.

Two R scripts build the data; one MATLAB file does the econometrics. Run in this
order.

## 1. Rebuild the paper's panel

```
Rscript rebuild_panel.R
```

Runs the data half of `oil_empirical_quarterly_claude.R` — the author's own
script, lines 1 to 590, stopping before the first regression — and writes
`panel_full.csv`. Along the way the paper's script fits the
stochastic-volatility model to the log real oil price and writes
`volatilities.csv`, which is the volatility measure Table 1 uses.

It ends by re-estimating the four Table 1 specifications and checking the oil
price coefficients against 0.188, 0.184, 0.142 and 0.142 — the 0.14 to 0.19
range Referee 2 quotes. If that check fails the rebuild has drifted from the
paper and nothing downstream should be used.

| | |
|---|---|
| needs | `../../../empirical/`: `oil_qtrly.xlsx`, `spread_data.xlsx`, `monthly_domestics.xlsx`, `global_monthly.xlsx`, and the author's own script |
| writes | `panel_full.csv`, `volatilities.csv`, and the script's own byproducts into `workings/` |
| takes | under a minute |

## 2. Build the control volatilities

```
Rscript build_control_volatilities.R
```

Eight non-oil volatility series, each built exactly as the paper builds the oil
one: deflate by the same CPI, average to quarters, then
`svsample(log(real), designmatrix = "ar1")` with seed 123, keeping 100× the
posterior mean standard deviation. Writes `generic_vol.csv`.

| column | series | source |
|---|---|---|
| `met_vol` | IMF global metals index | `fred/PMETAINDEXM.csv` |
| `nfuel_vol` | IMF global non-fuel commodity index | `fred/PNFUELINDEXM.csv` |
| `ippi_vol` | PPI, processed goods for intermediate demand | `fred/WPUID61.csv` |
| `imat_vol` | PPI, intermediate materials, supplies and components | `fred/WPUSOP2000.csv` |
| `ppi_vol` | PPI, final demand, finished goods (WPUFD49207) | `external/PPI_monthly.xls` |
| `fpi_vol` | real food price index | `external/FPI_data.xlsx` |
| `cpi_vol` | the CPI used as deflator | `oil_qtrly.xlsx` |
| `tbill_vol` | the 3-month T-bill | `global_monthly.xlsx` |

The FRED files are cached in `fred/` and re-downloaded only if missing, so the
series are fixed rather than moving under the paper. `external/` holds the two
files that were previously only on the author's Desktop, copied in so the
package does not depend on paths outside the repository.

## 3. The regressions

```
matlab -batch "JEDC_dependence"
```

Writes into this folder:

| file | what | comment |
|---|---|---|
| `table1_clustering.csv` | the four Table 1 specifications, four standard errors each | R1 M1c |
| `table2_dependence.csv` | the oil-dependence interaction | R1 M4, R2 M5b |
| `table3_terciles.csv` | a volatility slope per third of the dependence distribution | R1 M4, R2 M5b |
| `table4_generic_vol.csv` | the oil coefficient against each of the seven controls | R1 M4 |
| `table5_subsamples.csv` | the same race by period, against each control | R1 M4 |

## Where the other R1 M4 numbers come from

The model comparison and the elasticity figure are not in this folder:

| result | code | output |
|---|---|---|
| matched persistence and unconditional volatility; the 93% split | `model/economies_common_check/JEDC_decomposition.m` | `decomposition/table7_price_process.csv`, `table3_decomposition.csv` |
| the share's price response, +0.61 (s.e. 0.08) | `model/economies_common_check/JEDC_elasticity.m` | `elasticity_sweep/table1_elasticity_specs.csv` |

## One thing that is not reproducible from here

`volatilities.csv` comes from an MCMC sampler. `set.seed(123)` fixes it for a
given version of `stochvol` — 3.2.8 as run — but a different version may shift
the series slightly, and with it every coefficient that uses `vol`. The Table 1
check in step 1 is there to catch that.
