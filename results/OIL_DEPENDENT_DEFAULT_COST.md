# Making the default cost depend on the oil price

Tested the mechanism already built into `oil_prod_CES.f90` for R2 major 3:
while in default or exclusion the country pays `p*(1+kappa)` for imported oil
(`oil_disruption = kappa`). This is the Mendoza–Yue (2012) channel the referee
pointed at with the Sri Lanka example. Runs in `model/runs_oildisrupt/`, on
top of the calibrated `sigma_oil = 0.30` model.

**It does not work, and it fails in an instructive way.**

## Result

| kappa | spread | debt/GDP | slope v2 | slope v3 | slope v4 | ratio 4/2 | level (%) |
|---|---|---|---|---|---|---|---|
| 0 (baseline) | 3.99 | 33.4 | 0.00189 | 0.00180 | 0.00171 | 0.902 | 2.276 |
| 0.10 | 3.03 | 35.9 | 0.00030 | 0.00043 | 0.00049 | 1.639 | 1.679 |
| 0.25 | 3.28 | 41.2 | −0.00010 | 0.00014 | 0.00030 | −3.040 | 1.576 |
| 0.50 | 3.27 | 49.6 | −0.00048 | −0.00017 | 0.00005 | −0.098 | 1.356 |

Three things go wrong:

1. **The price→spread slope collapses**, 0.0019 → 0.0004 at kappa = 0.10. A
   20% oil price move then shifts the spread by under 1 bp. The paper's core
   mechanism is weakened, not strengthened.
2. **At kappa >= 0.25 the slope turns negative** — a higher oil price *lowers*
   an oil importer's spread, which is the opposite of the paper's premise.
3. **Debt/GDP runs away**, 33.4 → 49.6 against a 34.0 target, because a
   costlier default sustains more debt.

### The ratio above 1 at kappa = 0.10 is not a success

It is tempting to read `ratio = 1.639` as the state dependence finally pointing
the paper's way. In absolute terms the gap is +0.00019 (against −0.00018 at
baseline), so the sign does genuinely flip — but on a slope base that has
fallen 4–6x. The ratio rose because its **denominator nearly vanished**, and
one step further (kappa = 0.25) the denominator crosses zero and the ratio
explodes to −3.04. A ratio of two near-zero numbers is not evidence of a
mechanism.

## Why it fails

The premium makes default *more* painful exactly when oil is expensive: the
extra cost of defaulting is `kappa * p * m`, which rises with `p`. So a higher
oil price, which hurts the importer and should push it toward default, now
*also* raises the penalty for defaulting. The two effects offset, and past
kappa ≈ 0.2 the penalty dominates and the sign reverses.

This is the same cancellation identified in `WHY_OPPOSITE.md` §3, made worse.
There the problem was that a near-permanent oil price shock shifts the value of
repaying and of defaulting almost equally. The disruption premium does not
break that symmetry — it tilts it the wrong way.

## What direction would work

For an oil price rise to raise the spread more strongly, the default cost must
**fall** when oil is dear, so that defaulting becomes relatively more
attractive exactly when the importer is squeezed. The natural candidate is to
express the default penalty as a share of **value added** (`output − oil
bill`) rather than of the endowment: value added shrinks when oil is
expensive, so the absolute penalty shrinks with it.

Two caveats before anyone implements this:

- The current penalty, `max(0, d0*y + d1*y^2)`, is in endowment units. Making
  it depend on value added introduces a fixed point (the penalty affects TFP,
  which affects oil demand, which affects value added), so it needs a two-pass
  or iterative solve rather than a parameter change.
- A quick analytic check suggests the effect is weak if the penalty is tied to
  **gross** output: `Y ∝ (1-s)^(1/|theta|)`, and with an 8.3% oil share a 15%
  price rise moves gross output only about 0.4%. Value added moves
  considerably more, because the oil bill is subtracted, so that is the version
  worth trying.

This is a structural change to the production/default block rather than a
switch, so it has not been made.
