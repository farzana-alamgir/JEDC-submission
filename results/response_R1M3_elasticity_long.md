# R1, Major 3

*Disciplining the substitution elasticity, and why α moved from 0.2 to 5.8 × 10⁻⁵*

> Provide sensitivity analysis and, if possible, discipline the elasticity using
> evidence on energy demand or imported-input substitution.

We have done this, and it changed the calibration. The elasticity is now
estimated from our own import panel rather than assumed, and the estimate
rejects the value we submitted. Because α and θ are not separately
interpretable under CES, α moved with it — by three orders of magnitude, which
we explain below, since the new value looks alarming until one sees why it is
arithmetically forced.

## 1. α is not a free parameter, and it is not the oil share

The optimal-oil condition gives `m/Y = (α/p)^σ`, so the oil cost share is

```
s(p) = α^σ · p^(1−σ)        σ = 1/(1−θ)
```

α equals the oil share only at σ = 1 (Cobb–Douglas). Everywhere else α is a
scale parameter whose **units depend on σ**, because σ sits in the exponent.
Holding α fixed while changing θ would silently change the oil share, which is
a calibration target. So each elasticity gets its own α, chosen so that
`α^σ · E[p^(1−σ)]` hits the share target under the benchmark's simulated price
distribution.

The consequence, from our own sweep — every row below delivers the **same** oil
share of roughly 9% of GDP:

| σ_oil | θ | α | realised oil/GDP |
|---|---|---|---|
| 0.30 | −2.3333 | 0.000189 | 8.67% |
| 0.50 | −1.0000 | 0.006639 | 8.72% |
| 0.80 | −0.2500 | 0.047532 | 8.91% |
| 1.20 | +0.1667 | 0.136130 | 9.09% |
| 2.00 | +0.5000 | 0.290215 | 9.22% |

α ranges over a factor of 1,500 across this table while the economically
meaningful object is constant. At the adopted σ_oil = 0.25 (θ = −3.0), the
corresponding value is α = 5.779464 × 10⁻⁵, which delivers an oil share of
9.24%. **A tiny α at a low elasticity is required by the algebra, not a sign
that something has gone wrong.** The submitted α = 0.2 was not "more
reasonable"; it was the value consistent with an elasticity we can now reject.

## 2. The elasticity is identified from the oil share's price response

Taking logs of the share equation,

```
d ln s / d ln p = 1 − σ
```

so the comovement of the oil import share with the oil price identifies σ
directly, with no outside calibration required. Our own `import_gdp` panel —
34 oil importers, 1995–2015, 660 observations:

| specification | coefficient | s.e. | implied σ |
|---|---|---|---|
| within country, clustered by year | **+0.6057** | 0.0830 | **0.394** |
| collapsed to a time series | +0.6271 | | 0.373 |
| collapsed, with linear time trend | +0.9575 | | 0.043 |
| first differences within country | +0.8358 | 0.1332 | 0.164 |

All four coefficients are positive. **σ = 2 predicts −1.000**, so the submitted
calibration has the sign of this relationship backwards: it implies oil bills
*fall* as a share of GDP when oil gets more expensive. The 95% interval for the
baseline coefficient is [+0.443, +0.768], giving σ ∈ **[0.232, 0.557]**. Both
σ = 2 and σ = 1 are rejected. Oil and the domestic input are **complements**.

Standard errors cluster on year: the regressor is the global oil price and is
common across the cross-section within a year.

*A caveat we state because it does real work:* the sign flips if oil
**exporters** are retained, so the importer sample definition matters and we
now make it explicit in the text.

## 3. Why σ = 0.25 rather than the 0.394 point estimate

The four specifications give σ = 0.394, 0.373, 0.043 and 0.164, averaging
0.244. We adopt 0.25 as a central value across specifications rather than the
most favourable one, and it lies inside the baseline 95% interval. The level
channel is in any case insensitive to the choice across the plausible range:

| σ | spread | debt/GDP | level channel | time-varying vol | welfare (full→basic) |
|---|---|---|---|---|---|
| 0.20 | 4.1788 | 33.82 | +188.4 | +3.6 | +0.359% |
| **0.25** | **4.0793** | **34.30** | **+200.7** | **+13.4** | **+0.468%** |
| 0.30 | 4.1798 | 33.25 | +188.4 | −2.5 | +0.117% |
| 0.35 | 4.1326 | 33.87 | +185.4 | −6.0 | +0.273% |
| 0.40 | 4.0953 | 34.20 | +223.7 | +1.2 | +0.205% |
| 0.50 | 3.9581 | 34.36 | +181.3 | −15.7 | +0.078% |

β and d₁ are recalibrated at each elasticity to hit the spread and debt
targets, so every row fits those targets about equally well. **Removing oil
price risk is worth 181 to 224 basis points at every elasticity**, and that is
the paper's result. We state plainly that the welfare number is *not* robust in
the same way — it is not monotone in σ and 0.25 sits near its peak — so any
claim about the size of the welfare gain is a claim about the elasticity as
much as about oil risk, and we now report it with this table beside it.

### How the quantities respond

The referee asks specifically how oil imports, the value of oil imports, output,
default probabilities and spreads respond across the range. We have solved the
benchmark economy at each elasticity on the common grid, with α re-pinned and β
and d₁ re-matched as above, and simulated 750,000 quarters at each:

| σ | oil imports | value of oil imports | oil bill / GDP | output | default rate, % p.a. | mean spread, % |
|---|---|---|---|---|---|---|
| 0.20 | 0.8159 | 0.9681 | 10.079 | 9.6654 | 3.481 (0.044) | 3.713 |
| **0.25** | **0.8173** | **0.9593** | **10.079** | **9.5817** | **3.345 (0.043)** | **3.589** |
| 0.30 | 0.8177 | 0.9495 | 10.079 | 9.4872 | 3.469 (0.044) | 3.716 |
| 0.35 | 0.8174 | 0.9391 | 10.080 | 9.3838 | 3.325 (0.043) | 3.664 |
| 0.40 | 0.8159 | 0.9275 | 10.079 | 9.2687 | 3.224 (0.043) | 3.549 |
| 0.50 | 0.8105 | 0.9017 | 10.079 | 9.0104 | 3.201 (0.043) | 3.567 |

Quantities and output are in units of the consumption good; the value of oil
imports is E[p·m], so it is not the product of the two column means. Standard
errors on the default rate are in parentheses. The spreads here are means over
the whole simulation rather than over pre-default episode windows, which is the
convention of the table above — 3.589% against 4.079% at the adopted elasticity
— so the two spread columns are each internally comparable but should not be
read across.

Four features of this table are worth stating.

**The oil bill is 10.08% of GDP in every row.** That is the calibration target,
and it is held by construction: α is chosen at each elasticity so that
α^σ·E[p^(1−σ)] hits it. The simulated share agrees with the target to six
figures at all six elasticities, so the rows differ in the elasticity and not in
how oil-intensive the economy is.

**The quantity of oil imported is essentially invariant** — 0.810 to 0.818, a
range of 0.9%, and not monotone. Over this range the elasticity does not change
how much oil the country buys.

**Output falls 7.3% from σ = 0.20 to σ = 0.50, and the value of the oil bill
falls by the same 7.3%**, since the share is pinned and the price is common
across rows. This is the CES aggregator being
reparameterized rather than a substitution response. With
`Y = [(1−α)A^θ + α·m^θ]^(1/θ)` and θ < 0, a more negative θ at a fixed value
share returns a higher output level for the same endowment: a single endowment
of A = 9.899 reproduces all six simulated output levels to within 0.22%. The
level shift is absorbed by the recalibration of β and d₁, which is why the
credit-risk moments stay comparable across rows.

**The default probability and the spread are flat.** The default rate runs from
3.20% to 3.48% a year and the mean spread from 355 to 372 basis points, with no
monotone pattern in either; the whole 17-basis-point spread range sits on a mean
of about 360, and the largest default-rate gap between any row and the adopted
elasticity is 0.14 percentage points, roughly two standard errors. The paper's
credit-risk results therefore do not turn on where in this range the elasticity
is set — the same conclusion the level channel reaches above by a different
route, and the reason we lead with those results rather than with the welfare
number.

## 4. σ = 2 reverses the paper's own welfare result

This is the argument we find most decisive, and it is internal to the model.
With σ > 1 the economy substitutes away from oil when it is dear, so
`s(p) = α²/p` *falls* as p rises, the oil bill is bounded, and indirect utility
is **convex** in the price. Mean-preserving price variability is then a *gain*,
which is Waugh (1944). With σ < 1 the country cannot substitute, the convexity
reverses, and volatility is a cost.

Consumption equivalent of removing all oil price risk, where positive means
oil price uncertainty is costly — the paper's claim:

| σ_oil | CEV |
|---|---|
| 0.30 | **+0.489%** |
| 0.35 | +0.077% |
| **0.40** | **−0.002%**  ← crossover |
| 0.50 | −0.492% |
| 1.20 | −1.771% |
| **2.00 (as submitted)** | **−2.779%** |

Monotone in σ, crossing zero at 0.40. **At the elasticity we originally
submitted, oil price risk is worth −2.8% of consumption — it is a benefit, not
a cost.** The paper claims +0.2% to +1.1%. The submitted calibration therefore
contradicted the paper's own headline welfare result; the referee's request to
discipline the elasticity turned out to be load-bearing, not a robustness
formality.

(This sweep was solved on the earlier per-state grid, so neither the magnitudes
nor the location of the crossover are directly comparable to §3, which uses the
common grid with β and d₁ recalibrated at each elasticity; there the gain is
still positive, though small, at σ = 0.50. What is structural, and independent
of the grid, is the *sign pattern*: the gain declines as σ rises and turns
negative once oil and the domestic input are substitutable enough, because that
is where indirect utility becomes convex in the price. Within the recalibrated
range the decline is not monotone row by row, so we do not read the shape of
that curve, only its ends. The crossover moves out
as the solution improves — 0.40 on the per-state grid, beyond 0.50 once the
calibration is re-matched — so we quote it as a region, not a number, and the
submitted σ = 2 is far outside it either way.)

## 5. Feasibility, for completeness

An interior oil optimum needs `s(p) < 1` across the price grid:

- σ > 1 needs a **floor** `p > α^(σ/(σ−1))`
- σ < 1 needs a **ceiling** `p < α^(−σ/(1−σ))`

At low elasticities the ceilings are remote, so complementarity is not a
binding constraint. The binding case is the other end: σ = 2.5 requires a price
floor above the grid minimum and is infeasible. This is a further reason the
high-elasticity region is not a comfortable place to calibrate once oil price
volatility is set to its measured value.

## 6. One elasticity for 34 heterogeneous economies

The referee's last point is the one we had not addressed, and the share
equation lets us answer it with the same data. Estimating

```
ln s_ct = a_c + (1 - sigma_c) ln p_t + e_ct
```

country by country gives 34 separate elasticities. The distribution:

| | implied sigma |
|---|---|
| median | 0.38 |
| interquartile range | 0.19 to 0.65 |
| precision-weighted mean | 0.33 |
| weighted by oil import share | 0.31 |
| pooled within-country estimate (§2) | 0.39 |

The pooled estimate is not the product of a few influential countries: it sits
close to the median of the country-level estimates and to both weighted means.
**32 of the 34 are complements**, sigma below one. The two that are not,
Ukraine at 1.73 and Ghana at 2.53, carry standard errors of 0.55 and 1.32, so
neither is separable from the rest. Taken one at a time, 19 of the 34 countries
cannot reject the adopted 0.25; only 3 cannot reject the submitted 2.

Most of the visible spread is sampling error rather than genuine heterogeneity.
The variance of the 34 estimates is 0.349 and their average sampling variance
is 0.219, so the variance of the underlying elasticities is about 0.130 — a
standard deviation of **0.36 rather than the 0.59 the raw estimates suggest**.
Real heterogeneity remains, but it is roughly a third smaller than it appears,
and it is wide enough that we would not defend a single elasticity as
descriptively true of every country. We defend it as the central value of a
distribution whose location is well determined and far from the submitted one.

What matters for the paper is whether the elasticity varies along the dimension
the mechanism runs through, namely oil dependence. It does not:

| | mean sigma |
|---|---|
| most oil-dependent third | 0.268 |
| least oil-dependent third | 0.197 |
| sigma on log mean oil import share | −0.147 (s.e. 0.166), R² 0.02 |

There is no detectable relationship, and the heavily dependent countries — the
ones the paper is about — average 0.27, close to the adopted 0.25. Imposing one
elasticity therefore does not systematically misprice the economies that drive
the result.

Where the dispersion does bite is welfare, and in a direction we should state.
Fifteen of the 34 point estimates lie above 0.50, the top of the range we have
solved, and across that range the welfare gain from removing oil price risk
falls from +0.47% at the adopted elasticity to +0.08% at 0.50 (§3). For those
countries a separately calibrated model would deliver a welfare gain close to
zero, and plausibly negative above 0.50, where we have not solved. The spread
channel does not behave this way: it is 181 to 224 basis points at every
elasticity in the range. This is the same asymmetry as in §3, now visible
across countries rather than across a sweep, and it is a further reason we lead
with the spread channel and report the welfare number with its elasticity
dependence attached.

A limit worth being explicit about: these country estimates are too imprecise
to calibrate 34 economies separately. Five of them come out negative, which the
CES form does not admit, and that is a feature of twenty annual observations
against a single global price series rather than of those countries. We
therefore report the dispersion and what it does and does not change, and do
not propose a heterogeneous-elasticity version of the model.

Country-level estimates are in `empirical/analysis/elasticity_by_country.csv`,
produced by `empirical/elasticity_heterogeneity.py`.

The response table in §3 comes from six benchmark solves on the common grid,
one per elasticity, driven by
`model/economies_common_check/elasticity_sweep/respsweep.sh` and collected in
that folder's `sweep_resp/responses.csv`; the patched source and the solver log
tail are kept beside it for each elasticity, and the tables are written into the
same folder by `model/economies_common_check/JEDC_elasticity.m`. The σ = 0.25 row is the
economy of record, `model/economies_common_check/benchmark`, not a separate
solve.
