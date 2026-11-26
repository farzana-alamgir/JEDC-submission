# R1, Major 5 — lender-side risk pricing

> The precautionary-borrowing result assumes risk-neutral lenders. [...] the
> paper should discuss how robust it is to lender-side risk pricing, state that
> its strength is conditional on risk-neutral pricing, and if feasible add a
> robustness exercise with an exogenous SDF or a reduced-form global risk
> premium.

We have run the exercise. The result does not depend on risk-neutral pricing:
at an empirically disciplined risk premium the state dependence is slightly
*stronger* than in the baseline, and the debt moment is essentially unchanged.

## The exercise

The model carries an exogenous stochastic discount factor,

> m′ = exp(−r*) · exp(κ·ε′) / Z(p, σ′)

where ε′ is the innovation to the log oil price and Z normalises the kernel on
the discrete grid, so that E[m′] = exp(−r*) holds exactly at any κ. A positive
κ makes the discount factor high when oil is dear, so lenders demand more for
default risk concentrated in those states. κ = 0 is the baseline and reproduces
it exactly.

We note for completeness that an earlier version of this kernel used the
continuous-state lognormal correction, which does not normalise on a discrete
grid: measured on the benchmark grid, E[m]/exp(−r*) ranged from 0 to 2559. The
kernel is now normalised numerically and the results below are post-fix.

## Disciplining κ

κ is not observable, so it is disciplined by the maximum Sharpe ratio the
kernel implies, which for this kernel is √(exp(κ²v) − 1) in a state with
conditional innovation variance v, averaged over the volatility states at their
simulated frequencies and annualised. Equities run about 0.4 a year, so a kernel
implying much more than that is not a plausible description of lenders.

## The result

| κ | mean spread | debt/GDP | default % p.a. | spread, low vol | spread, high vol | gap | implied Sharpe |
|---|---|---|---|---|---|---|---|
| 0 | 3.59% | 26.1% | 3.35% | 3.27% | 4.05% | +0.77 | 0.00 |
| 1.0 | 4.15% | 26.1% | 1.86% | 3.79% | 4.68% | +0.89 | 0.28 |
| 2.0 | 4.67% | 25.1% | 0.92% | 4.25% | 5.28% | +1.03 | 0.56 |
| 3.0 | 5.12% | 23.3% | 0.40% | 4.67% | 5.79% | +1.12 | 0.87 |

*σ_oil = 0.25, the adopted calibration, with every other parameter held at its
baseline value. Spreads are whole-simulation means; debt is relative to annual
output; low and high volatility are the extreme states of the simulated grid.*

*These are whole-simulation means, not the Table 3 statistics, which average
over the 100 quarters before each qualifying default episode. On that basis the
κ = 0 economy has a mean spread of 4.08% and debt/GDP of 34.3%, against targets
of 4.1% and 34.0%, so the baseline matches both; the whole-simulation figures
for the same economy are 3.59% and 26.1%. Every column is computed the same way
at every κ, so the comparison across rows is like for like — but no column
should be read against a Table 3 target.*


**The state dependence strengthens monotonically in κ.** The gap between
high- and low-volatility spreads rises from +0.77 to +1.12. Risk pricing loads
on exactly the states where default risk is concentrated, so it reinforces the
mechanism rather than competing with it.

**At a plausible risk premium the calibration barely moves.** The equity
benchmark of 0.4 falls between the second and third rows of the table, at
κ = 1.43. There the volatility gap is +0.95 against +0.77, so the state
dependence is about a fifth stronger, and debt/GDP is 25.6% against 26.1% —
half a percentage point on the same basis. The precautionary-borrowing
margin the paper is about is therefore not an artefact of risk neutrality, and
if anything the baseline understates it.

## What we should still concede

The default frequency falls sharply, from 3.35% a year to 1.86% at κ = 1 and
0.92% at κ = 2. That is the mechanical consequence of pricing default risk more
expensively: the country defaults less because defaulting has become dearer to
finance. The exercise holds every other parameter at its baseline value, which
is the right way to isolate the risk-pricing channel but means the κ > 0
economies no longer match the default frequency in Table 3. Matching it again
would require re-selecting d₁, and we have not done that, because the point of
the exercise is the comparative static rather than a second calibration.

So the honest claim is about the *sign and the ordering*, not the levels:
introducing a plausible risk premium leaves the state dependence intact and
slightly larger, at a debt ratio essentially unchanged, while lowering the
default rate below its target.

## What we propose to say

1. State in the text that spreads in the baseline are pure expected-default
   compensation, with no price of risk, as the referee asks.
2. Report this exercise, with the Sharpe ratio as the discipline on κ, and the
   conclusion that the state dependence survives and strengthens.
3. Note the fall in the default frequency as the cost of the exercise, and that
   re-matching it would require re-calibrating the default cost.
4. Cross-reference the reply to Major 6 of the other report, where risk-neutral
   pricing is named as the most promising route to closing the remaining gap
   between the model's volatility coefficient and the panel's. This exercise is
   the evidence for that: κ = 1.43 raises the mean spread from 3.59% to about
   4.3%, which is movement in the right direction on the same channel.

## Note

`JEDC_riskpremium.m` in `model/economies_common_check/risk_premium/`, writing
`table1_kappa.csv`. The three solves are `kappasweep.sh`, which patches
`kappa_risk` in the economy of record and greps ten other literals back out
before compiling; the κ = 0 row is `../benchmark` itself, extracted with the
same awk. Run directories are deleted once their moments are out, so what
survives per κ is the patched source and a log tail.

The earlier σ_oil = 0.30 sweep is in `results/RISK_PREMIUM_AND_FIGURE3.md`.
Its conclusion was that risk pricing buys the Figure 3 ordering only by
destroying the debt moment — debt/GDP fell from 33.7% to 18.1% by κ = 3, on the
episode-window measure. At the adopted calibration the fall is far smaller,
26.1% to 23.3% over the same range, on the whole-simulation measure. The levels
are not comparable across the two bases; the contrast is in the size of the
decline, roughly a half against a tenth. The re-solve was worth doing for that reason alone.
