# R2 Major 3 — oil imports disrupted during default

> The author should discuss this assumption; even better would be a robustness
> exercise in which default also disrupts oil imports, for example through a
> price wedge or partial exclusion from oil purchases during autarky.

## Running it

```
./run_disruptsweep.sh                  # three solves, ~70 min, two at a time
matlab -batch "JEDC_disruption"        # the table, and the basis check
```

`oil_disruption = 0` is `../benchmark` and is not re-solved. While in default or
excluded the country pays `p·(1 + oil_disruption)` for oil, applied in the
source as `p_eff = p + default_grid(i_excl)·log(1 + oil_disruption)`. Its row is
put into `sweep/disrupt.csv` by running the same awk on the baseline panel,

```
awk -v K=0.00 -f extract_disrupt.awk ../benchmark/graphs_data_sim_dss.txt >> sweep/disrupt.csv
```

`JEDC_disruption.m` then rebuilds that row from the panel in MATLAB and compares
the two, which is the check that the sweep's κ = 0 really is the economy of
record; it agrees to 4e-5. The same script prints the baseline on the Table 3
basis — 4.08% and 34.3%, against targets of 4.1% and 34.0% — beside the
whole-simulation figures, so the two bases cannot be confused again.

| file | what |
|---|---|
| `disruptsweep.sh` | one solve: patch `oil_disruption`, verify, compile, extract, delete the run |
| `run_disruptsweep.sh` | κ = 0.10, 0.25 together, then 0.50; writes `sweep/DONE` |
| `extract_disrupt.awk` | one pass over a panel → one row |
| `JEDC_disruption.m` | the table, the κ = 0 check and both measurement bases |
| `table1_disrupt.csv` | the result as the letter reports it |
| `sweep/disrupt.csv` | the result |
| `sweep/sigma030_prior.csv` | the superseded σ_oil = 0.30 runs, same moments |

## The result

| κ | spread | debt/GDP | default %/yr | vol gap |
|---|---|---|---|---|
| 0 | 3.59% | 26.1% | 3.35% | **+0.77** |
| 0.10 | 2.94% | 29.7% | 2.80% | +0.60 |
| 0.25 | 2.01% | 36.7% | 1.81% | +0.22 |
| 0.50 | 1.30% | 48.2% | 1.27% | **−0.00** |

The exercise the referee asks for destroys the paper's central prediction. The
extra cost of defaulting is κ·p·m, which rises with the oil price, so a dearer
barrel both squeezes the importer toward default and raises the penalty for
defaulting. Past κ ≈ 0.2 the penalty wins.

The baseline is the only version that matches the debt target, and it is also
the version with the full state dependence: any positive κ raises debt above
target and shrinks the volatility gap at the same time. There is no κ that buys
the mechanism without costing the debt moment.

### Basis of these columns

All columns are whole-simulation means. They are NOT the Table 3 statistics,
which average over the 100 quarters before each qualifying default episode
(`per_before = 100` in `sim_prod_oil_dec29.m`). On that basis the κ = 0
economy has a mean spread of 4.08% and debt/GDP of 34.3%, against targets of
4.1% and 34.0% — i.e. the baseline matches both. The whole-simulation figures
for the same economy are 3.59% and 26.1%, so a column above must never be read
against a Table 3 target. Verified by running the author's own script on
`benchmark/graphs_data_sim_dss.txt`: it prints `Mean debt/y = 34.2992`.
The κ > 0 panels were not retained, so the episode-window figures for those
rows would need the solves re-run.


## A warning about watchers

An earlier `run_after_kappa.sh` waited for this sweep's turn with
`pgrep -f "kappasweep.sh"`. A separate watcher launched afterwards had that
string inside its own command line, so each matched the other and neither
advanced: nothing ran for eight hours. `run_disruptsweep.sh` now writes
`sweep/DONE` and anything waiting on it should wait for that file, never for a
process name.

## Provenance

The response is `results/response_R2M3.md`. The σ_oil = 0.30 attempt is
`model/runs_oildisrupt/` with `results/OIL_DEPENDENT_DEFAULT_COST.md`; its
figures use episode windows and a different debt basis, so they do not line up
with the table above — `sweep/sigma030_prior.csv` is the comparable version.
