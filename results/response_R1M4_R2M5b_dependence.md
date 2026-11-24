# R1 Major 4 (empirical) and R2 Major 5b — is the effect stronger where oil matters more?

> R1: One natural empirical test would be to examine whether the effect of
> global oil price volatility is stronger in countries with greater oil import
> dependence.

> R2: test whether spreads of more oil-dependent economies respond more strongly
> to oil price volatility, by interacting volatility with the country-level oil
> import share.

We have run the test and it does not support the prediction. We report that, and
we also report that the test is not powerful enough to rule the prediction out.

## The interaction

Added to the paper's preferred specification — controls and country fixed
effects — with the oil import share centred, so the volatility coefficient is
the slope at mean dependence. Standard errors are two-way clustered by country
and quarter throughout, per Major 1c.

| | coefficient | two-way se | t |
|---|---|---|---|
| oil volatility | +0.0100 | 0.0042 | +2.35 |
| volatility × dependence | −0.00015 | 0.00071 | −0.22 |
| adding Δoil price × dependence | −0.00037 | 0.00056 | −0.66 |

The point estimate is essentially zero and, if anything, slightly the wrong
sign. Splitting the countries into thirds of the dependence distribution, which
assumes no functional form at all, gives the same answer:

| third of the dependence distribution | volatility slope | two-way se | t |
|---|---|---|---|
| least dependent (≤ 1.83% of GDP) | +0.0108 | 0.0052 | +2.05 |
| middle (≤ 2.95%) | +0.0106 | 0.0046 | +2.29 |
| most dependent (> 2.95%) | +0.0085 | 0.0043 | +1.98 |

All three slopes are individually significant and they are nearly identical. The
difference between the most and least dependent thirds is −0.0023, against slopes
of about +0.010.

## Why this is a weak test, which we should say

The sample is 35 oil importers whose import shares run from 1.1% to 10.4% of
GDP, and the controlled specifications use 32 of them. The 95% interval on the
interaction implies that the volatility slope could differ across the observed
dependence range by anywhere from −0.0143 to +0.0115, against a main effect of
+0.0100. In other words the data cannot distinguish no heterogeneity from the
effect roughly doubling between the least and most dependent economy in the
sample.

So the honest statement is that we find no support for the cross-sectional
prediction, not that we reject it. We are reluctant to lean on a null result
from a cross-section of 32 countries, and we say so rather than presenting the
absence of an interaction as a finding.

## What it means for the paper

The model's mechanism does scale with the oil share, so this is a prediction the
paper makes and the data do not confirm. Three readings are consistent with what
we see, and we cannot separate them:

- the oil import share is a noisy measure of exposure, since it ignores
  pass-through, energy intensity, hedging and the composition of imports;
- spreads respond to global oil volatility partly through channels common to all
  emerging markets — risk appetite, capital flows — which do not scale with any
  one country's import share;
- the heterogeneity is real but too small to detect across a 9 percentage point
  spread in import shares with 32 countries.

We therefore present the cross-sectional prediction as untested rather than
confirmed, and we do not claim cross-country support for the oil channel that
the data do not provide.

## Note

`JEDC_dependence.m` in `model/economies_common_check/oil_dependence/`, writing
`table2_dependence.csv` and `table3_terciles.csv` beside it. The oil import
shares are the `import_gdp` sheet of `empirical/spread_data.xlsx`, the same
source the paper uses; three country names needed aliasing to merge onto the
panel, and El Salvador's entry is misspelled in that sheet. Dependence is
time-invariant and so absorbed by the country effects, which is why only the
interaction is identified.

The remaining part of R1 Major 4 — a control for broader imported-input or
producer-price volatility — is answered in
`results/response_R1M4_generic_volatility.md`, using the real food price index
from the author's own food-price project. The short version: the oil volatility
coefficient does not survive it.
