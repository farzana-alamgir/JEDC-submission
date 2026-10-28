# Default cost as a share of value added

A structural change to the default penalty, implemented behind the switch
`va_default_cost` in `oil_prod_CES.f90`. It is the fix for the diagnosis in
`WHY_OPPOSITE.md` §3, and it works: **the oil price's effect on spreads rises
about tenfold.**

## The change

The submitted penalty is

    max(0, d0*EXP(y) + d1*EXP(y)**2)

a function of the **endowment** alone. The oil price therefore never enters the
default decision except through the consumption level common to both branches.
With `rho_p = 0.98` an oil price shock is very nearly permanent, so it shifts
the value of repaying and the value of defaulting by almost the same amount,
the default margin barely moves, and every oil channel comes out small.

With the switch on, the base of the quadratic is instead **normalised value
added**, `(Y - p*m)/scale_y`, which shrinks when oil is expensive. A higher oil
price now *lowers* the absolute cost of defaulting, so default becomes
relatively more attractive exactly when the importer is squeezed.

Value added is evaluated at the **no-default TFP**, which does not depend on
the penalty. That is what makes this a two-pass calculation rather than a fixed
point, and it matches how default costs are normally described — a share of the
output the country would otherwise have produced.

Implementation: new `va_norm()` (the same relative-tolerance bisection as
`func_m`, deliberately duplicated so the hot path is untouched) and
`defloss()`, replacing the penalty at all six sites — four in the solver, two
in the simulation. **Regression: with `va_default_cost = .false.` the solver
reproduces the previous baseline byte-identically**, including the full 160 MB
simulation dump.

## Calibration

The penalty base falls from `EXP(y) ~ 1.0` to `VA ~ 0.92`, so the whole
calibration shifts and `d1`, `beta` and `alpha` all need re-fitting.

| | endowment cost | **value-added cost** |
|---|---|---|
| `alpha` | 0.000188992 | **0.000307** |
| `beta` | 0.964 | **0.972** |
| `d1` | 0.37 | **0.46** |
| `d0` | −0.246 | −0.246 |

| moment | target | endowment | **value added** |
|---|---|---|---|
| mean spread | 4.1 | 3.99 | 4.41 |
| sd(spread) | 2.0 | **2.25** | 2.91 |
| debt/GDP | 34.0 | 33.41 | **33.69** |
| oil/GDP | 9.0 | 8.73 | 8.73 |

Spread, debt and the oil share all fit. **The cost is sd(spread)**, which rises
from 2.25 to 2.91 against a 2.0 target — unsurprising, since a far larger
oil-price response mechanically makes the spread more volatile.

## Result: the oil channel becomes economically meaningful

Spread slope at the matched-price contrast, and what it implies for a 20% oil
price move:

| debt index | endowment: slope / bp | **value added: slope / bp** |
|---|---|---|
| 30 | 0.00159 / 3.6 bp | **0.01506 / 33.9 bp** |
| 44 (mean debt) | 0.00180 / **4.1 bp** | **0.01894 / 42.7 bp** |
| 60 | 0.00437 / 9.8 bp | **0.02859 / 64.5 bp** |

**A 20% oil price move shifts the spread by 43 bp instead of 4 bp**, a factor
of 10.5 at mean debt. That is the difference between an oil channel that
rounds to nothing and one that can plausibly speak to the empirical
correlations the paper documents.

Debt amplification survives and strengthens in absolute terms: 33.9 → 64.5 bp
across the debt grid.

## What it does NOT fix

**The volatility state dependence still runs against the paper**, and slightly
more so: the high/low ratio moves from 0.90 to **0.62**, below 1 at every debt
level tested.

This is expected, and it is the third independent confirmation of the same
mechanism. The spread is the probability of crossing the default threshold; as
a function of today's price that is a step convolved with the conditional
distribution of `p'`. Raising volatility widens the kernel and **flattens** the
function. Making the price response larger makes that smoothing *more* visible,
not less — exactly as the `rho_p` diagnostic predicted
(`WHY_OPPOSITE.md` §3), and exactly as the `oil_disruption` experiment showed
from the opposite direction.

On the evidence now available the FIGURE3 claim is **structurally unavailable**
in this model class, not a calibration or measurement problem. Three separate
interventions — lower persistence, an oil-price-dependent default cost, and a
value-added default cost — all move it further the wrong way.

## Recommendation

Adopt the value-added default cost. It is a defensible modelling choice, it
directly answers the referees' point that oil should matter for default (and
is closer to Mendoza–Yue than the endowment-only penalty), and it buys a
tenfold increase in the paper's central mechanism for a 0.9 deterioration in
one second-moment target.

Drop or restate FIGURE3.
