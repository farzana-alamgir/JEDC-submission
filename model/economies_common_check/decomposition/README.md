# R2 Major 1 and R1 Major 2 — the mean-preserving decomposition

> R2: part of what the paper calls an uncertainty effect is a first-moment
> effect, since E[p'] = exp(m + v/2). Subtract ½Var(log p' | σ) from the
> conditional mean so volatility states differ only in dispersion.

> R1: separate the pure dispersion effect from the volatility-induced rise in
> the expected oil price, and recompute the responses of default probabilities,
> spreads and borrowing.

Both referees ask the same thing, and this folder holds the answer. It also
carries two tables written for later comments, because they come from the same
pass over the same four simulation panels and there is no reason to read 956 MB
twice.

## Running it

```
cd ..                                   # model/economies_common_check
matlab -batch "JEDC_decomposition('decomposition','benchmark','mean_preserving','intermediate','basic')"
```

The economies go in the order full, mean-preserving, constant volatility,
constant price. Without arguments the file redraws the figure from the tables
already here, in seconds instead of minutes:

```
matlab -batch "JEDC_decomposition('decomposition')"
```

A full rebuild takes a few minutes, almost all of it reading the four 239 MB
simulation panels.

## What is here, and which comment it serves

| file | what | comment |
|---|---|---|
| `table1_economies.csv` | the four economies side by side, episode-window moments | R2 M1, R1 M2 |
| `table2_by_volatility.csv` | mean spread and mean price by volatility state | R2 M1, R1 M2 |
| `table3_decomposition.csv` | the channels, each with a 95% interval | R2 M1, R1 M2, R1 M4 |
| `table4_default_by_volatility.csv` | annual default probability by volatility state | R2 M1, R1 M2 |
| `table5_horizon.csv` | how far the one-step mean-preserving correction holds | R2 M1 |
| `table6_mean_price.csv` | the average oil price each economy actually pays | R2 M2 |
| `table7_price_process.csv` | persistence and unconditional volatility of the simulated log price | R1 M4 |
| `panelA_expected_price.csv` | E[p \| volatility state], full vs mean-preserving | figure panel (a) |
| `panelCD_debt_policy_full.csv`, `..._meanpres.csv` | the borrowing panels | figure panel (c) |
| `diagnostic_simulated_price_by_vol.csv` | a diagnostic, not a result |  |
| `FIGURE_decomposition.jpg` | panels (a) to (d) |  |

**Two files here are not written by `JEDC_decomposition.m`.**
`panelE_spread_menu.csv` and `FIGURE_spread_menu.jpg` come from
`model/analysis/spread_menu.py` and `model/analysis/FIGURE_spread_menu.m`, which
draw the paper's Figure 2 with the mean-preserving economy added. Their
timestamps are a day earlier than everything else, and a rebuild of the
decomposition leaves them untouched — so if the four economies are ever
re-solved, those two go stale silently. Re-run the spread-menu pair as well, or
delete them.

## Two things worth knowing about the numbers

**The identified channel is small.** Of the 200.7 basis points by which oil price
risk raises the mean spread, 13.4 is attributable to time-varying volatility and
only 1.3 of that is pure dispersion, with a 95% interval of ±6.0 — so the pure
dispersion effect is not distinguishable from zero. R2 M1 says a small
pure-uncertainty effect is an acceptable answer, and that is the answer.

**The constant-volatility economy is a placebo as well as a comparison.** Its
five volatility indices are economically identical, so the range of any moment
across them is the simulation noise floor. `table2_by_volatility.csv` reports it
for exactly that purpose: a channel smaller than that range is not a channel.

## Provenance

`JEDC_decomposition.m` sits one level up, beside `JEDC_elasticity.m`. It is a
port of `model/analysis/decomposition.py`, `moments_fast.py` and
`horizon_check.py`, and its outputs were byte-compared against the Python before
that was retired — `table7_price_process.csv` is the one table with no Python
counterpart, added for R1 M4.

The responses are `results/response_R2M1_R1M2.md` (with
`..._FULL_DETAIL.md` behind it), `results/response_R2M2.md`, and the R1 M4 pair
in `results/overleaf_R1M4/`.
