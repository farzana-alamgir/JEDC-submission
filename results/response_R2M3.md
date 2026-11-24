# R2, Major 3 — oil imports during default

> In the model, a country in default keeps importing oil at the world price
> with no friction. The only direct cost of default is the endowment loss h(y).
> [...] The author should discuss this assumption; even better would be a
> robustness exercise in which default also disrupts oil imports, for example
> through a price wedge or partial exclusion from oil purchases during autarky.

We have done both. The assumption is discussed below, and the robustness
exercise has been run — it is a parameter in the model already. The result is
negative, and we report it in full because the way it fails says something
about the mechanism.

## The assumption, and what can be said for it

Oil is bought on spot markets, usually by private importers and refiners
rather than by the sovereign, and a sovereign default does not by itself bar a
country's firms from purchasing crude. The channel through which a default
episode disrupts fuel supply is the loss of foreign exchange and of trade
credit — the inability to open letters of credit — rather than exclusion from
the oil market as such. The paper's motivating example works that way: the
2022 fuel crisis was a balance-of-payments and credit event.

That makes the frictionless assumption a defensible simplification rather than
a neutral one, and the referee is right that the paper should say so instead of
passing over it. Mendoza and Yue (2012) make the loss of imported inputs the
core cost of default, so a reader coming from that literature will expect the
channel to be present, and its absence should be a stated modelling choice.

## The exercise

While in default or excluded, the country pays `p·(1 + κ)` for imported oil.
This is implemented in the model as `oil_disruption = κ`, and κ = 0 reproduces
the baseline exactly, so the exercise is a parameter change rather than a new
model.

| κ | mean spread | debt/GDP | default % p.a. | spread, low vol | spread, high vol | gap |
|---|---|---|---|---|---|---|
| 0 | 3.59% | 26.1% | 3.35% | 3.27% | 4.05% | **+0.77** |
| 0.10 | 2.94% | 29.7% | 2.80% | 2.70% | 3.30% | +0.60 |
| 0.25 | 2.01% | 36.7% | 1.81% | 1.92% | 2.14% | +0.22 |
| 0.50 | 1.30% | 48.2% | 1.27% | 1.30% | 1.29% | **−0.00** |

*σ_oil = 0.25, the adopted calibration, every other parameter at its baseline
value. Spreads are whole-simulation means, debt is relative to annual output,
and low and high volatility are the extreme states of the simulated grid.*

Three things move the wrong way, all monotonically.

**The state dependence collapses.** The gap between high- and low-volatility
spreads falls from +0.77 to +0.22 and then to zero. At κ = 0.50 the simulated
spread is the same in the most and least volatile states, to two decimal places.
The paper's central prediction is not weakened at the margin; it is gone.

**The spread level falls by two thirds**, 3.59% to 1.30%, against a target of
about 4%. A disruption premium makes default more painful, so less of it is
priced.

**Debt runs away**, 26.1% to 48.2% against a 34% target, for the same reason: a
costlier default sustains more borrowing.

The three are not independent, and that is the point. Debt/GDP passes through
its 34% target at about κ = 0.19 — so there is a disruption premium at which the
debt moment is matched. At that κ the volatility gap is +0.36, less than half
the baseline's +0.77, and the mean spread is 2.36% against a 4% target. **The
calibration can have the debt moment or the state dependence, not both.**

## Why it fails, which is the useful part

The extra cost of defaulting is `κ·p·m`: it is proportional to the oil price.
So a dearer barrel does two things at once. It squeezes the importer, which
pushes it toward default — the paper's mechanism. And it raises the penalty for
defaulting, which pushes it away. The two offset, and past roughly κ = 0.2 the
penalty dominates, so a higher oil price *lowers* an oil importer's spread.

This is not a numerical artefact. It is the same cancellation that makes the
oil price a weak driver of default incentives in any model where the shock is
near-permanent: a persistent price rise shifts the value of repaying and the
value of defaulting almost equally. Adding a disruption premium does not break
that symmetry; it tilts it the wrong way, because the premium is largest
exactly when the price is highest.

The earlier σ_oil = 0.30 sweep found the same thing one step further: measured
on the price-to-spread slope read off the bond schedule, rather than on realised
spreads, the slope turned *negative* at κ ≥ 0.25 — a higher oil price lowering
an oil importer's spread. At the adopted calibration our measure reaches zero
rather than crossing it, which is a weaker statement about the same mechanism,
and we report what we measure.

## What would work, and why we have not done it

For a price rise to raise the spread more strongly, the default penalty must
*fall* when oil is dear, so that defaulting becomes relatively more attractive
precisely when the importer is squeezed. The natural candidate is to express
the penalty as a share of **value added** — output net of the oil bill —
rather than of the endowment, since value added shrinks when oil is expensive.

We have not implemented it, for a reason worth stating: the current penalty is
in endowment units, and tying it to value added introduces a fixed point, since
the penalty affects productive capacity, which affects oil demand, which
affects value added. That needs an iterative solve rather than a parameter
change, and it is a structural change to the production and default block, not
a robustness check.

## What we propose to say

1. State the assumption explicitly where the default cost is introduced,
   including that the empirically relevant channel runs through foreign
   exchange and trade credit rather than through exclusion from oil markets.
2. Report the disruption exercise and its negative result, with the
   cancellation that explains it. A referee who implements the suggestion will
   find the same thing, and the explanation is more informative than the
   exercise would have been had it worked.
3. Note the value-added penalty as the version that would work, and that it is
   a structural extension rather than a robustness check.

## Note

`oil_disruption` is a parameter in
`model/economies_common_check/benchmark/oil_prod_CES_benchmark.f90`, applied as
`p_eff = p + default_grid(i_excl)·log(1 + oil_disruption)`. The sweep is
`model/economies_common_check/oil_disruption/disruptsweep.sh`, which patches
that one literal and greps ten others back out before compiling.

The σ_oil = 0.30 runs are `model/runs_oildisrupt/{k0.10,k0.25,k0.50}`, with
their panels intact; re-extracted with the same awk they give the same pattern,
the volatility gap falling from +0.64 to +0.20 as κ rises, and they are kept in
`oil_disruption/sweep/sigma030_prior.csv` for comparison. The earlier write-up
is `results/OIL_DEPENDENT_DEFAULT_COST.md`; its spread and debt figures use
episode windows and a different debt basis, so they do not line up with the
table above.
