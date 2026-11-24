# R2, Major 6 — the magnitude of the model's spread response

> The effect in the model is much smaller than that in the data [...] A
> discussion of what determines this magnitude in the model would help the
> reader interpret the result. Also, the author could estimate regression (1) on
> model-simulated data, with volatility in the same units as the empirical
> measure, so that the model's coefficients can be compared with the empirical
> ones.

We have done the exercise, and it does not show the model falling short by the
margin the comparison implies. Two things turn out to matter: the units, which
work out cleanly, and the timing of the price change, which does not.

## The units work without rescaling

The empirical volatility measure is 100 times the posterior mean standard
deviation of the log real oil price, from the stochastic-volatility model in our
own estimation code. The simulation records the log variance state, so
100·exp(state/2) is the same object. No rescaling is needed:

| | min | mean | max |
|---|---|---|---|
| data, the paper's volatility series | 8.86 | 12.90 | 31.58 |
| model, 100·exp(state/2) | 8.77 | 13.79 | 20.64 |

The one asymmetry is at the top. The data reach 31.6 and the model's grid stops
at 20.6, so the model never experiences a quarter as volatile as 2008 Q4. That
is relevant below.

## The timing of the price change, which the comparison has to respect

Regression (1) deliberately uses the *lagged* price change, and this needs
stating in the text because a reader will otherwise assume the contemporaneous
one. In our estimation code the variable is built as

```
lag_price = lag(log_real_price, 1)
op_diff   = c(NA, diff(lag_price))
```

so `op_diff` at *t* is log p(*t*−1) − log p(*t*−2) — the price change of the
*previous* quarter — while the dependent variable is the contemporaneous change
in the log spread. Verified against the price series directly, the two agree to
9 × 10⁻¹⁵. The specification is deliberate: using last quarter's price change
avoids the simultaneity between the spread change and the price change inside a
quarter.

The consequence for this comment is that the simulated counterpart has to be
estimated with the same timing, and the choice determines the sign. We report
both, with the lagged row as the comparable one and the contemporaneous row
because the difference between them explains the model's lagged coefficient.

## The comparison

Regression (1) uses the previous quarter's price change and controls for the
change in debt to GDP: `dy_diff` is the first difference of `dy3`, which is
commercial public and publicly guaranteed external debt as a percent of GDP, not
GDP growth as the name suggests. The simulated regression matches both choices —
same timing, same controls, with the simulated debt stock taken over four times
quarterly output so the ratio is on an annual-GDP basis, averaging 26.1% against
0 to 25.3% for the data series.

| | model | data |
|---|---|---|
| oil price volatility | +0.0047 | +0.0100 (t 2.29) |
| oil price change, previous quarter | +0.0007 (t 0.4) | +0.1416 (t 0.93) |
| change in debt / GDP | +0.1338 (t 297) | +0.0027 (t 0.49) |

Standard errors two-way clustered by country and quarter in the data, clustered
by simulated history in the model, where each of the 500 independent histories
plays the role a country plays in the panel.

**On volatility, which is the paper's subject, the model delivers 47% of the
empirical coefficient.** That is a gap worth discussing, but a factor of two is
not the small fraction the comparison in the comment implies.

**On the oil price change the model and the data agree, and they agree on
zero.** The simulated coefficient is +0.0007 with a t of 0.4 and the empirical
one +0.1416 with a two-way t of 0.93. The 6 to 8 basis points in the comment are
computed from the empirical coefficient, whose standard error covers zero, and
the model agrees that this regressor carries no information.

This is not because the model's spread ignores the oil price. Estimated on the
contemporaneous price change instead, the simulated coefficient is +1.03 — about
37 basis points per 10% move at the model's mean spread of 359. The spread
responds on impact and then partially retraces, as the log price mean-reverts at
0.9475 a quarter and debt adjusts, so a regression on the *previous* quarter's
price change recovers nothing. The timing convention, not the absence of
transmission, is what produces the zero.

**On debt the model is far more responsive than the panel**, +0.134 against
+0.0027, and we think the difference is measurement rather than mechanism. In the
model, debt is the state variable and the spread is a function of it, so the
relationship is exact. In the data the regressor is one debt aggregate —
commercial public and publicly guaranteed external debt — reported annually and
carried across the quarters of each year, which is a noisy and slow-moving proxy
for the leverage a lender actually prices. An attenuated coefficient is what that
predicts, and the empirical estimate is indeed indistinguishable from zero. We
report it because debt is a control in both specifications and a reader will ask,
not because we think the model is fifty times too debt-sensitive.

## What governs the magnitude in the model

Three things, in order of how much they bind.

**The size of the shock.** The oil bill is 9 to 10% of GDP and the substitution
elasticity is below one, so the quantity response does not offset the price. A
10% oil price rise is therefore close to a 1% of GDP resource loss. The model
turns that into an 11% rise in the spread on impact, about 40 basis points. The
transmission is not weak; the shock is small relative to the things that usually
move sovereign spreads.

**Where the volatility grid stops.** The model's volatility tops out at 20.6 in
the empirical units against 31.6 in the data. The states that would generate the
largest spread responses are not in the model's support, which is a direct and
quantifiable reason its volatility coefficient is the smaller of the two.

**Risk-neutral lenders.** Spreads in the model are pure expected-default
compensation, with no term for the price of risk. Referee 1's Major 5 asks about
exactly this, and our reply there reports what happens when an exogenous
stochastic discount factor is switched on. That is the most promising route to
closing the remaining gap on the volatility channel, and we say so rather than
leaving the reader to wonder.

## What we propose to say

1. Report regression (1) estimated on simulated data, in the empirical
   volatility units, alongside the empirical estimates — timing for timing.
2. State in the text which object the introduction's spread slopes are. They are
   read off the model's spread schedule and are not the same quantity as a
   regression coefficient on a lagged log price change in a panel, and
   presenting the two side by side invited this comment.
3. Keep the comparison on the volatility channel, where both estimates are
   identified and the model delivers roughly half to four-fifths of the data,
   and drop the price-channel comparison, where the empirical coefficient is not
   distinguishable from zero and changes sign with the timing convention.
4. State the timing of the oil price regressor in the text, and why: regression
   (1) relates the spread change to the *previous* quarter's price change, which
   avoids within-quarter simultaneity. Without that sentence a reader will assume
   the contemporaneous change, and the coefficient has the opposite sign under
   that reading.

## Note

The simulated regression is `JEDC_simreg.m` in
`model/economies_common_check/simulated_regression/`, writing
`table1_simreg.csv` and `table2_comparison.csv`. It reads its empirical
counterparts from `../oil_dependence/table6_timing.csv` rather than carrying
typed-in numbers, so the two halves cannot drift apart; run `JEDC_dependence`
first.

Each of the 500 independent simulated histories plays the role a country plays
in the panel, so the specification carries history fixed effects and standard
errors clustered by history. There is no analogue of clustering by quarter: in
the data the oil price is one global series shared across the cross-section at
each date, which is what makes two-way clustering necessary, whereas each
simulated history draws its own path. That is also why the simulated
coefficients are estimated far more precisely than the empirical ones.

The constant-volatility and constant-price economies appear in
`table1_simreg.csv` with empty cells where a regressor has no variation, which
is a check rather than a result: a volatility coefficient cannot be estimated in
an economy whose volatility is constant.
