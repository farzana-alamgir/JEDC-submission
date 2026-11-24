# R2 Major 3 — oil imports disrupted during default

> The author should discuss this assumption; even better would be a robustness
> exercise in which default also disrupts oil imports, for example through a
> price wedge or partial exclusion from oil purchases during autarky.

## Running it

```
./run_disruptsweep.sh      # three solves, ~70 min, two at a time
```

`oil_disruption = 0` is `../benchmark` and is not re-solved. While in default or
excluded the country pays `p·(1 + oil_disruption)` for oil, applied in the
source as `p_eff = p + default_grid(i_excl)·log(1 + oil_disruption)`.

| file | what |
|---|---|
| `disruptsweep.sh` | one solve: patch `oil_disruption`, verify, compile, extract, delete the run |
| `run_disruptsweep.sh` | κ = 0.10, 0.25 together, then 0.50; writes `sweep/DONE` |
| `extract_disrupt.awk` | one pass over a panel → one row |
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

Debt/GDP crosses its 34% target at κ = 0.19, where the volatility gap is already
down to +0.36. The calibration can have the debt moment or the state
dependence, not both.

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
