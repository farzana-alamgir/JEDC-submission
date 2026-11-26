# R1 Major 5 — lender-side risk pricing

> The precautionary-borrowing result assumes risk-neutral lenders. [...] if
> feasible add a robustness exercise with an exogenous SDF or a reduced-form
> global risk premium.

## Running it

```
./run_kappasweep.sh                    # three solves, ~70 min, two at a time
matlab -batch "JEDC_riskpremium"       # the table, including the Sharpe ratios
```

`kappa_risk = 0` is `../benchmark` and is not re-solved. Its row is put into
`sweep/kappa.csv` by running the same awk on the baseline panel directly,

```
awk -v K=0.0 -f extract_kappa.awk ../benchmark/graphs_data_sim_dss.txt >> sweep/kappa.csv
```

which takes about 4 seconds. `JEDC_riskpremium.m` then reads all four rows from
that file; it does not shell out to awk itself.

| file | what |
|---|---|
| `kappasweep.sh` | one solve: patch `kappa_risk`, verify, compile, extract, delete the run |
| `run_kappasweep.sh` | κ = 1, 2 together, then 3 |
| `extract_kappa.awk` | one pass over a panel → one row |
| `JEDC_riskpremium.m` | the table, with the implied maximum Sharpe ratio |
| `table1_kappa.csv` | the result |
| `sweep/` | `kappa.csv`, a patched source and a log tail per κ |

## The result

| κ | spread | debt/GDP | default %/yr | vol gap | Sharpe |
|---|---|---|---|---|---|
| 0 | 3.59% | 26.1% | 3.35% | +0.77 | 0.00 |
| 1.0 | 4.15% | 26.1% | 1.86% | +0.89 | 0.28 |
| 2.0 | 4.67% | 25.1% | 0.92% | +1.03 | 0.56 |
| 3.0 | 5.12% | 23.3% | 0.40% | +1.12 | 0.87 |

Risk pricing strengthens the state dependence. The equity Sharpe benchmark of
0.4 sits at κ = 1.43, where the gap is +0.95 against +0.77 and debt/GDP is 25.6%
against 26.1%.

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


## Two things to know

**κ is disciplined by the Sharpe ratio, not chosen.** For this kernel the
quarterly maximum is √(exp(κ²v) − 1) in a state with conditional innovation
variance v; `JEDC_riskpremium.m` averages that over the five volatility states
at their simulated frequencies and annualises by two. Without that discipline κ
is a free parameter and the exercise proves nothing.

**The default frequency falls**, 3.35% to 0.40% across the range, because
pricing default risk more expensively means less default. The sweep holds every
other parameter at its baseline value, so the κ > 0 economies no longer match
Table 3's default rate. That is deliberate — it isolates the risk-pricing
channel — but it has to be said rather than left for a reader to notice.

## Provenance

The kernel had a bug: the continuous-state lognormal correction does not
normalise on a discrete grid, and E[m]/exp(−r*) ranged from 0 to 2559. It is now
normalised numerically by Z(p, σ′). The fix predates these runs and is recorded
in `results/RISK_PREMIUM_AND_FIGURE3.md`, along with the superseded σ_oil = 0.30
sweep. The response is `results/response_R1M5.md`.
