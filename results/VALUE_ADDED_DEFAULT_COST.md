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

---

# Full solve: all six economies and the ten figures

Runs in `model/runs_va_final/`, figures in `results/figures_valueadded/`,
sources in `model/sigma03_calibrated_valueadded/`.

## Decomposition — the oil price risk channel is now dominant

Comparison economies level-matched at the benchmark's simulated
`E[p] = 1.3339` (verified for both).

| channel | value added | endowment |
|---|---|---|
| **oil price risk** (full − basic, matched) | **+206.5 bp** | +7.1 bp |
| time-varying volatility (full − intermediate, matched) | +1.7 bp | +5.6 bp |
| mean-preserving | −13.6 bp | +26.6 bp |

Oil price risk goes from a rounding error to **206 bp**, and is now by far the
largest channel. This is the paper's headline mechanism finally carrying real
quantitative weight.

## Welfare — in the paper's range, correctly nested

| comparison | CEV |
|---|---|
| full → basic, matched (remove all oil price risk) | **+0.732%** |
| full → intermediate, matched (remove time-varying vol) | **+0.175%** |

Both positive, properly nested, and +0.73% sits inside the paper's claimed
+0.2% to +1.1%. FIGURE7 shows +0.81% and +0.16%.

## Claims

| claim | paper | value added | endowment |
|---|---|---|---|
| [1] slope state dependence | 3.0 | **0.65** | 0.90 |
| [2] debt amplification | larger when indebted | **112 → 286 bp** | 15 → 44 bp |
| [3] debt slope by vol state | 0.16/0.25/0.70 | not measurable | not measurable |
| [4] welfare | +0.2% to +1.1% | **+0.73%** | +0.52% |

Debt amplification is now an order of magnitude larger in absolute terms
(112 bp at low debt rising to 286 bp at high debt) while keeping the same
monotone shape. Claim [1] still fails, now at 0.65.

## Figures (`results/figures_valueadded/`)

All ten drawn, no blank or sparse panels.

**FIGURE2 now matches the paper.** The Basic schedule sits clearly below Full
and Intermediate across the whole debt range, a gap of roughly 0.5–1 pp,
consistent with the +206 bp channel. Under the endowment cost the three
schedules coincided to within ±8 bp and the figure carried no message.

**FIGURE7 matches the paper** — both curves positive and well separated.

**FIGURE3 still contradicts the paper**, and now does so more visibly: the
slopes are an order of magnitude larger (0.01–0.06 against 0.001–0.005), so
the three curves separate cleanly — in the wrong order, low volatility
steepest.

**FIGURE4c needed a fix.** With the default cost tied to the oil price, the
country defaults with certainty at the top two price nodes, so `q = 0` and the
spread is NaN there. The local-cubic smoother propagated that NaN across the
entire curve and blanked the panel. The smoother now drops non-finite nodes
from each window and leaves NaN only where the spread is genuinely undefined.

## Recommendation

Adopt the value-added default cost. It is a defensible modelling choice, it
directly answers the referees' point that oil should matter for default (and
is closer to Mendoza–Yue than the endowment-only penalty), and it buys a
tenfold increase in the paper's central mechanism for a 0.9 deterioration in
one second-moment target.

Drop or restate FIGURE3.
