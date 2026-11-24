# R1 Major 4 (first part) and R2 Major 4 — what is new, and relative to what

*Both referees ask the same thing: the novelty claim is too strong, and the
differentiation from the closest papers is thin.*

> R1: the paper would benefit from sharpening the discussion of what the
> oil-specific production structure adds relative to these existing mechanisms,
> and which quantitative implications arise specifically from introducing oil
> price volatility rather than from stochastic volatility in external
> fundamentals more generally.

> R2: the paper states that "none of the existing research has addressed the
> impact of oil-related volatility shocks within the framework of sovereign
> default literature." This is too strong.

R2 is right and we withdraw the sentence. It is contradicted by our own
reference list, which contains Lopez-Martin et al. (2019), and by our own
footnote 1, which acknowledges Hamann et al. (2018) and Esquivel (2020). Citing
a paper and then claiming the question is unaddressed is not a defensible
position, and the correction costs us nothing, because the accurate gap
statement is still a gap.

## What we now claim

Oil **importers**, with the oil price process **estimated** rather than
assumed — including the stochastic volatility — and the mechanism running
through the **cost** side of production.

## What we do not claim

We should be explicit about what is not new, because three things in the paper
are standard and we were not careful enough to say so.

The stochastic-volatility machinery is standard. Long-duration debt follows
Chatterjee and Eyigungor (2012) and Hatchondo and Martinez (2009). And **state
dependence in volatility and debt is not our finding** — Johri, Khan and
Sosa-Padilla (2022) document it for world interest rate volatility, as Referee 1
notes. Our Figures 3 and 5 show the same qualitative pattern in a different
shock, which is a confirmation, not a discovery.

We also accept the structural point in the second part of Referee 1's comment:
mathematically this is an imported-input mechanism, not an oil mechanism.
Nothing in the CES technology knows that the input is oil. Our reply to that
part quantifies how much of the effect survives replacing oil with a generic
imported input matched on persistence and unconditional volatility.

## Differentiation, paper by paper

**Lopez-Martin et al. (2019)** — a default model with stochastic commodity
revenues and hedging. The commodity is a source of government **revenue**. Here
it is a **cost** of production. That is a difference in the sign of the budget
constraint, not a relabelling: a price rise is a windfall in their setting and a
squeeze in ours, so default risk moves in the opposite direction, and the
welfare consequence of price volatility is opposite in sign as well. The same
applies to Hamann et al. (2018) and Esquivel (2020), which are exporter studies.

**Seoane (2019)** — stochastic volatility in the endowment, with endogenous
default. The volatile object is exogenous income, so there is no optimizing
margin: the country cannot respond to income volatility by buying less income.
In our model the oil price enters through the CES first-order condition, so a
price change moves the imported quantity, the import bill and output at the same
time. Two consequences follow that have no counterpart in an endowment-volatility
model. First, the response is amplified rather than dampened, because our
estimated elasticity is below one: the oil bill **rises** as a share of GDP when
oil is dear, with d ln s / d ln p = +0.61 (s.e. 0.08) in our import panel, so
the quantity margin is too weak to offset the price. Second, and more
importantly:

**Where the volatility effect comes from has the opposite sign.** Because the
log price is conditionally normal, E[p'] = exp(m + v/2), so higher volatility
raises the expected **level** of the oil price. Our decomposition shows this is
where almost the whole effect lives: of the 13.4 basis points attributable to
time-varying volatility, 12.1 is the expected-price channel and only 1.3 is pure
dispersion. The identical convexity in an endowment-volatility model raises
expected **income**. So the channel that carries nearly all of our volatility
effect is, in Seoane's setting, a force of the opposite sign. This is the
sharpest answer we can give to "which quantitative implications arise
specifically from introducing oil price volatility," and it is a cost-side
point, not an oil-side one.

**Johri, Khan and Sosa-Padilla (2022)** — stochastic volatility in the world
interest rate, with long-duration debt. The volatile object is the price at
which debt is discounted, so it acts on the financing side of the budget
constraint and leaves the production side untouched. Oil price volatility acts
on production first and reaches the bond price only through repayment capacity.
The two are not nested, and the paper should say which it is studying rather
than implying the combination is itself the contribution.

## The prediction that is ours

The strength of our mechanism scales with the oil import share, which is
observable and varies a great deal across the economies in question — from
essentially zero to 10.4% of GDP in our panel. Volatility in the endowment or in
the world interest rate predicts no cross-sectional heterogeneity along a trade
share. That gives this paper a test the others do not have, and it is the test
Referee 1 proposes in the next paragraph of the same comment; our reply to that
part reports it.

## Suggested manuscript wording

> Several papers study commodity prices in sovereign default models. Lopez-Martin
> et al. (2019) consider stochastic commodity revenues and hedging, and Hamann
> et al. (2018) and Esquivel (2020) study oil in exporting economies; in all of
> these the commodity is a source of revenue. Seoane (2019) studies stochastic
> volatility in the endowment and Johri, Khan and Sosa-Padilla (2022) stochastic
> volatility in the world interest rate, the latter documenting the state
> dependence in volatility and debt that our Figures 3 and 5 also display. What
> is new here is the combination of oil importers, an oil price process whose
> persistence and stochastic volatility are estimated rather than assumed, and a
> transmission that runs through the cost side of production: because the
> estimated substitution elasticity is below one, the oil bill rises as a share
> of GDP when oil is dear, and because the conditional mean of the price is
> convex in volatility, higher volatility raises the expected level of a cost
> rather than of income. The mechanism is in principle a general imported-input
> mechanism; what makes oil the relevant application is that it is both large
> enough and volatile enough for it to bind.

## Note

The elasticity figure is `table1_elasticity_specs.csv` and the channel split is
`table3_decomposition.csv`, both in
`model/economies_common_check/elasticity_sweep/` and
`model/economies_common_check/decomposition/`. The oil import shares are
`empirical/analysis/analysis_panel.csv`. Nothing here needs a new solve.

R2 Major 4 was missing from `results/REFEREE_COMMENTS_BY_TYPE.md`, which now
lists 21 requests rather than 20. `results/REFEREE_TRACKING.md` and
`results/RESPONSE_TO_REFEREES_v2.md` both already carried it.
