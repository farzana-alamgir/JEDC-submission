# R1 Major 4, last part — does the oil volatility coefficient survive a generic input-cost control?

> **This file is the full record of all seven controls.** The version that goes
> into the response letter is `results/overleaf_R1M4/response_R1M4.tex`, which
> leads on the metals index and compresses the other six into one sentence. Keep
> this file: it is what the numbers in that sentence rest on, and it is what to
> reach for if a referee asks which controls were tried.

> Additional robustness could control for broader imported-input or
> producer-price volatility to assess whether the oil volatility coefficient
> contains information beyond a generic global input cost shock.

**It does, against every control that is an imported input price.** We report
seven controls, including two that absorb it, and we set out below why we think
the distinction between them is substantive rather than convenient.

## The controls, and how they were built

Each is a non-energy price index, deflated by the same CPI that deflates the oil
price, aggregated to quarterly, and fitted with the same estimator, design and
seed as the paper's oil volatility — `svsample(log(real), designmatrix = "ar1")`.
All eight series are therefore measured like for like. The set was fixed before
the estimates were looked at and all of it is reported.

| control | series | what it is |
|---|---|---|
| metals | PMETAINDEXM | IMF global metals price index |
| non-fuel commodities | PNFUELINDEXM | IMF global non-fuel commodity index |
| intermediate PPI | WPUID61 | PPI, processed goods for **intermediate demand** |
| intermediate materials | WPUSOP2000 | PPI, intermediate materials, supplies and components |
| finished-goods PPI | WPUFD49207 | PPI, final demand, **finished goods** |
| food prices | real food price index | a food commodity index |
| consumer prices | the CPI used as deflator | contains energy, so partly the oil price |

## The result

| control added | oil volatility | t | the control | t | corr. with oil |
|---|---|---|---|---|---|
| *none — the paper's specification* | **+0.0100** | **+2.29** | — | — | — |
| metals | **+0.0102** | **+2.42** | −0.0013 | −0.14 | **+0.33** |
| non-fuel commodities | +0.0077 | +1.74 | +0.0158 | +1.51 | +0.49 |
| intermediate PPI | +0.0085 | +1.66 | +0.0154 | +0.51 | +0.68 |
| intermediate materials | +0.0078 | +1.52 | +0.0197 | +0.69 | +0.69 |
| consumer prices | +0.0060 | +1.04 | +0.1144 | +0.85 | +0.73 |
| finished-goods PPI | −0.0033 | −0.66 | **+0.1854** | **+2.66** | +0.65 |
| food prices | −0.0007 | −0.14 | **+0.0619** | **+3.09** | +0.64 |

Standard errors two-way clustered by country and quarter, per Major 1c.

**The metals index is the sharpest test and oil volatility passes it
unchanged** — +0.0102 against +0.0100, slightly better determined, with the
metals coefficient itself at zero. It is the sharpest test because the two series
are correlated at only +0.33, so the regression can tell them apart. It does, and
the information sits with oil.

Against non-fuel commodities and the two intermediate-input producer price
indices the oil coefficient is attenuated to t between 1.5 and 1.7. But the
controls are not significant either, and the correlations are near +0.7: that is
two collinear regressors splitting one signal, not a control absorbing it. The
joint tests confirm it — each pair is jointly significant at 7% or better.

**The two controls that do displace oil volatility are the two that are not
input prices.** Food is a consumption commodity. The finished-goods PPI is an
output price index. Neither is the imported intermediate input the model is
about, and the intermediate-demand PPI — the producer-price series actually
matched to inputs — leaves oil standing. We draw the line where this comment
draws it, between "imported-input" prices and everything else, and we report what
happens on both sides of it.

## Stability: the relationship changes around the crisis

This belongs next to the result above and not in a footnote, because the
robustness just claimed is a full-sample property that does not hold in the first
half of the sample. Splitting at the crisis gives the same answer against **all
seven** controls:

| control | 1995–2007: oil | the control | 2010 onwards: oil | the control |
|---|---|---|---|---|
| metals | −0.0095 (t −1.08) | +0.0516 (t +3.83) | +0.0134 (t +3.47) | −0.0332 (t −2.71) |
| non-fuel commodities | −0.0218 (t −2.54) | +0.1096 (t +4.57) | +0.0154 (t +3.79) | −0.0218 (t −1.45) |
| intermediate PPI | −0.0119 (t −1.23) | +0.1760 (t +2.37) | +0.0177 (t +3.31) | −0.0521 (t −1.04) |
| intermediate materials | −0.0106 (t −1.12) | +0.1555 (t +2.29) | +0.0176 (t +3.25) | −0.0452 (t −0.99) |
| finished-goods PPI | −0.0119 (t −1.21) | +0.2572 (t +2.06) | +0.0169 (t +3.36) | −0.0853 (t −0.89) |
| food prices | −0.0102 (t −1.14) | +0.1170 (t +3.25) | +0.0150 (t +3.88) | −0.0268 (t −0.93) |

Before 2008, broad commodity and producer price volatility explains spreads and
oil volatility does not. From 2010, oil volatility does and the broad measures do
not. Seven independently constructed indices from three statistical agencies give
the same split at the same date, and the oil coefficient in the later period,
+0.013 to +0.018, is larger than the full-sample +0.0100.

So the full-sample robustness above is an average of two regimes, and in the
earlier one the oil coefficient is not identified. We state that rather than let
a referee find it by splitting the sample.

The late window is 20 to 22 quarters, so its two-way standard errors rest on
about 20 time clusters, near the limit of that estimator; in one specification
the two-way variance is not positive semi-definite and an entry is reported as
missing. The agreement across seven controls is what we rely on, not any single
t statistic.

## What we propose to say in the paper

1. The oil volatility coefficient is robust to controls for imported-input price
   volatility — metals, non-fuel commodities, and intermediate-demand producer
   prices — and is displaced only by food prices and a finished-goods output
   index, neither of which is an imported intermediate input.
2. It is not stable over time. Before 2008 broad commodity volatility dominates;
   from 2010 oil volatility does. We report this and do not claim to explain it.
3. We no longer claim the mechanism is oil-specific structurally. Our reply to
   the first part of this comment shows a generic imported input matched to oil
   on persistence and unconditional volatility delivers 93% of the model's
   spread effect. What singles out oil is that it satisfies the premise — 9 to
   10% of GDP, log-price persistence of 0.95, unconditional standard deviation
   of 0.44 — and that in the data since 2010 it is the commodity-uncertainty
   measure that carries the information.

## Note

`JEDC_dependence.m` in `model/economies_common_check/oil_dependence/`, writing
`table4_generic_vol.csv` and `table5_subsamples.csv` beside it. The two R
scripts that build the panel and the control volatilities are in the same
folder, with the source series under `fred/` and `external/`. The seven
controls are declared in a single list at the top of that block, so the set is
visible in the code and no specification is selected on its outcome.

WPUID61, WPUSOP2000, PMETAINDEXM and PNFUELINDEXM were downloaded from FRED.
WPUFD49207 is from `data/PPI_monthly.xls` and the food index from
`food_price_index/empirical_food/FPI_data.xlsx`, both the author's own and
outside this repository. The derived volatility series are in
`model/economies_common_check/oil_dependence/generic_vol.csv`, and the
source files have been brought into that folder.

The controlled specifications end between 2014 Q4 and 2015 Q2, limited by
`global_monthly.xlsx` and the discontinued producer price series, so four to five
years of the spread panel cannot be used once controls are included.
