# R2 Major 6 — regression (1) on model-simulated data

> the author could estimate regression (1) on model-simulated data, with
> volatility in the same units as the empirical measure, so that the model's
> coefficients can be compared with the empirical ones

## Running it

```
cd ../oil_dependence   && matlab -batch "JEDC_dependence"   # the data side, first
cd ../simulated_regression && matlab -batch "JEDC_simreg"   # the model side
```

`JEDC_simreg` reads the empirical coefficients from
`../oil_dependence/table6_timing.csv` rather than carrying typed-in numbers, so
the two halves of the comparison cannot drift apart. It will stop with a clear
message if that file is missing.

It reads the four simulation panels from `../benchmark`, `../mean_preserving`,
`../intermediate` and `../basic` — about four minutes, almost all of it reading
239 MB of text four times.

| file | what |
|---|---|
| `table1_simreg.csv` | the coefficients, per economy and per specification |
| `table2_comparison.csv` | model against data, with the basis-point translation |

## The two things that make the comparison valid

**The units.** The empirical volatility measure is 100 times the posterior mean
standard deviation of the log real oil price, from the stochastic-volatility
model in the paper's own script. The simulation records the log variance state in
column 20, so `100*exp(col20/2)` is the same object. No rescaling: the model runs
8.77 to 20.64 with a mean of 13.79, the data 8.86 to 31.58 with a mean of 12.90.
The model's grid stops short of the data's most volatile quarters, which is one
of the three reasons the reply gives for its smaller volatility coefficient.

**The specification.** Regression (1) uses the *previous* quarter's price change
— `op_diff` is `diff(lag(log_real_price, 1))` — and controls for the change in
debt to GDP, `dy_diff`, which is the first difference of commercial public and
publicly guaranteed external debt as a percent of GDP. Both are matched here. The
simulated debt ratio divides by four times quarterly output so it is on an
annual-GDP basis: 26.1% on average against 0 to 25.3% for the data series. The
aggregates still differ — the model's `b` is all external debt — so this makes
the specifications comparable, not the series.

## What it reports, and why each row is there

Four specifications per economy: the two timings of the price change, each with
and without the debt control. The letter quotes the lagged-with-debt row, because
that is the paper's own specification. The others are not padding:

- **the contemporaneous row** shows the model's spread does respond to the oil
  price, by +1.03 on impact, which is what stops the +0.0007 on the lagged change
  from reading as no transmission at all;
- **the no-debt rows** show where the model's −0.0726 came from before debt was
  controlled: the spread responds on impact and retraces as the price
  mean-reverts and debt adjusts.

The constant-volatility and constant-price economies appear with empty cells
where a regressor has no variation. That is a check rather than a result — a
volatility coefficient cannot be estimated in an economy whose volatility is
constant — and if those cells ever fill in, something is wrong.

## Clustering

Each of the 500 independent simulated histories plays the role a country plays in
the panel, so the specification carries history fixed effects with standard
errors clustered by history. There is no analogue of clustering by quarter: in
the data the oil price is one global series shared across the cross-section at
each date, which is what makes two-way clustering necessary (R1 Major 1c),
whereas each simulated history draws its own path. That is also why the simulated
coefficients are estimated far more precisely than the empirical ones.

## The response

`results/response_R2M6.md` is the long record; the letter is
`results/overleaf_R2M6/response_R2M6.tex`.
