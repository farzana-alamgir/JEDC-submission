# R1, Major 3

*Disciplining the substitution elasticity*

> Provide sensitivity analysis and, if possible, discipline the elasticity using
> evidence on energy demand or imported-input substitution.

We have done this, and it changed the calibration: the elasticity is now
estimated from our own import panel rather than assumed, and the estimate
rejects the value we submitted. The share parameter α moved with it, from 0.2 to
0.000058.

**Why α moved by so much.** α is not the oil share; its units depend on the
elasticity. Holding it fixed while changing the elasticity would quietly change
the oil share of GDP, one of our calibration targets, so each elasticity needs
its own α. Across the six elasticities below, α varies by a factor of 1,800
while the simulated oil bill comes out at 10.08% of GDP in every case.

## What the data say, and why we adopt 0.25

The oil share identifies the elasticity directly: if oil is hard to substitute,
the oil bill takes a *larger* share of GDP when oil is dear; if it is easy to
substitute, the share falls. In our panel of 34 oil importers, 1995–2015, the
share clearly rises with the price. Four specifications — within country,
collapsed to a time series, collapsed with a time trend, and first differences —
all give positive coefficients, implying elasticities of 0.39, 0.37, 0.04 and
0.16, which average 0.244. The baseline coefficient is +0.606 (s.e. 0.083),
putting the elasticity between 0.23 and 0.56. The elasticity of 2 we submitted
implies the opposite sign altogether — oil bills *falling* as a share of GDP as
oil gets dearer — so both 2 and 1 are rejected: oil and the domestic input are
complements. We adopt **0.25** as a central value across specifications rather
than the most favourable one. (The sign flips if oil exporters are left in the
sample, so the importer definition matters, and we now say so in the text.)

## How the model responds across the range

We solved the model at six elasticities, re-matching the discount factor and the
default-cost parameter each time so that every version still hits the spread and
debt targets, then simulated 750,000 quarters at each.

| elasticity | oil imports | value of oil imports | oil bill / GDP | output | default rate, % p.a. | mean spread, % |
|---|---|---|---|---|---|---|
| 0.20 | 0.8159 | 0.9681 | 10.079 | 9.6654 | 3.481 (0.044) | 3.713 |
| **0.25** | **0.8173** | **0.9593** | **10.079** | **9.5817** | **3.345 (0.043)** | **3.589** |
| 0.30 | 0.8177 | 0.9495 | 10.079 | 9.4872 | 3.469 (0.044) | 3.716 |
| 0.35 | 0.8174 | 0.9391 | 10.080 | 9.3838 | 3.325 (0.043) | 3.664 |
| 0.40 | 0.8159 | 0.9275 | 10.079 | 9.2687 | 3.224 (0.043) | 3.549 |
| 0.50 | 0.8105 | 0.9017 | 10.079 | 9.0104 | 3.201 (0.043) | 3.567 |

The quantity of oil imported hardly moves — under 1% across the whole range.
Output is about 7% lower at the top of the range than at the bottom, with the
oil bill falling in step; that is the production function being re-parameterised
at a fixed oil share, not a change in behaviour. The result that matters is the
last two columns: **the default rate and the spread are flat**, 3.20% to 3.48% a
year and 355 to 372 basis points, with no trend in either and the largest gap
from the adopted elasticity about two standard errors. The paper's credit-risk
results do not depend on where in this range the elasticity is set.

The welfare number is not robust in the same way, and we now say so. Removing
all oil price risk is worth +0.47% of consumption at the adopted elasticity but
only +0.08% at 0.50, and it moves around in between, so a claim about its size
is as much a claim about the elasticity as about oil risk. The spread result is
the one we lead with: 181 to 224 basis points throughout.

An elasticity of 2 does worse than widen the error bars — it reverses the
paper's own conclusion. A country that substitutes easily buys less oil when oil
is dear, so its oil bill is capped and price swings become a benefit rather than
a cost (Waugh, 1944). On our earlier solution grid the welfare gain turns
negative above 0.5 and reaches −2.8% of consumption at an elasticity of 2,
against the +0.2% to +1.1% the paper claims. The calibration we submitted
therefore contradicted our own headline result.

## One elasticity for 34 different economies

Estimating the share relationship country by country gives 34 separate
elasticities: median 0.38, interquartile range 0.19 to 0.65. The pooled estimate
is not the work of a few countries — it sits close to the median and to the mean
weighted by oil import share (0.31). Thirty-two of the 34 are complements; 19
cannot reject 0.25, and only 3 cannot reject 2. Much of the visible spread is
measurement error rather than real difference between countries: the variance of
the 34 estimates is 0.349 against an average sampling variance of 0.219, leaving
genuine differences with a standard deviation near **0.36 rather than 0.59**.

What matters for the paper is whether the elasticity differs with oil
dependence, the dimension the mechanism runs through. It does not: the most
oil-dependent third of the sample averages 0.27 and the least 0.20, and
regressing the country estimates on oil dependence gives −0.15 with a standard
error of 0.17. Imposing one elasticity therefore does not systematically
misprice the economies that drive the result. These estimates are in any case
too imprecise to calibrate 34 economies separately — five come out negative — so
we report the dispersion rather than propose a heterogeneous version.

---

Spreads in the table are averages over the whole simulation; elsewhere we
average over the quarters before a default, 3.59% against 4.08% here, so the two
are not comparable. Everything for this comment is in
`model/economies_common_check/`: `JEDC_elasticity.m`, which writes every table,
and the subfolder `elasticity_sweep/` holding the three scripts that solved the
six economies, the run record under `sweep_resp/`, and the tables themselves.
That subfolder's README says what is recomputed and what is not. The six Fortran solves are not re-run;
`sweep_resp/responses.csv` is their record, and the 0.25 row is rebuilt from
`model/economies_common_check/benchmark` and compared, which is the check on the
other five. The longer version of
this reply, with the derivations, the α schedule and the full sweep tables, is
`results/response_R1M3_elasticity_long.md`.
