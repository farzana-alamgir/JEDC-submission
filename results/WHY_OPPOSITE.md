# Why FIGURE2 and FIGURE3 come out against the paper

Three separate causes, only one of which is a defect in the model.

---

## 1. FIGURE2 is not actually reversed — it was a price mismatch

The three economies were plotted at three different oil prices:

| economy | price plotted at |
|---|---|
| full | 1.1275 — its central log node, `exp(mean_p)` |
| intermediate | 1.1090 |
| basic | **1.3339** — the ergodic mean price |

Rouwenhorst centres its grid on the **median of log p**, while the basic
economy is pinned on the **mean of p**. Jensen puts those 18.3% apart. Basic
was being drawn at an 18% higher oil price than full, which is the whole of
its apparent excess spread.

Evaluated at a common price (1.3339, by interpolation):

| i_b | full | interm | basic | basic−full |
|---|---|---|---|---|
| 20 | 1.7923 | 1.8055 | 1.8093 | +0.017 |
| 30 | 1.9886 | 1.9895 | 1.9806 | −0.008 |
| 44 | 2.3326 | 2.3031 | 2.3602 | +0.028 |
| 50 | 2.5622 | 2.4987 | 2.5709 | +0.009 |
| 60 | 3.5014 | 3.3800 | 3.4202 | −0.081 |

Gaps of ±8 bp that change sign along the debt grid. So the correct statement
is **not** "removing oil price risk raises spreads" (what the mismatched
figure showed) and **not** "removing it lowers spreads" (the paper's claim) —
it is that the three schedules are the same to within a few basis points.

## 2. FIGURE3: volatility smooths the default margin, it does not amplify it

At a fixed price and debt, the spread **level** is flat across volatility
states while the **slope** falls:

| vol state | level (%) | slope |
|---|---|---|
| 1 | 2.2836 | 0.00191 |
| 3 | 2.2762 | 0.00195 |
| 5 | 2.2798 | 0.00164 |
| | **ratio 0.998** | **ratio 0.856** |

The mechanism is a convolution. The spread is essentially the probability that
next period's state crosses the default threshold. As a function of *today's*
price that probability is a step convolved with the conditional distribution of
`p'`. Raising volatility widens that kernel, which **flattens** the function —
it does not steepen it. The level is unchanged because a mean-preserving
widening moves mass symmetrically across the threshold.

So the paper's intuition — "uncertainty makes spreads more responsive to oil
prices" — runs the wrong way in an Eaton–Gersovitz default model. Uncertainty
blurs the default margin.

This is separate from, and in addition to, the grid artifact: the published
3× came from per-state grid widths (see `SUMMARY_OPTION_A.md` §6), and the
underlying economics points the other way regardless.

## 3. Why every oil channel is small: `rho_p = 0.98`

Diagnostic run, identical except `rho_p` lowered from 0.98 to 0.90
(`model/runs_diag/rho090/`; **not** a proposed recalibration — the oil process
is otherwise unchanged from the submission):

| | mean slope | slope hi/lo | level hi/lo |
|---|---|---|---|
| `rho_p = 0.98` (submitted) | 0.00186 | 0.856 | 0.998 |
| `rho_p = 0.90` (diagnostic) | **0.00381** | 0.542 | 1.005 |

**Halving the persistence roughly doubles the spread's response to the oil
price.** At `rho_p = 0.98` an oil price shock is very nearly permanent, so it
shifts the value of repaying and the value of defaulting by almost the same
amount; the default *decision* barely moves, and neither does the spread. The
default cost `max(0, d0*y + d1*y^2)` is a function of output, so a near-permanent
oil price level shift largely passes through both branches of the default
choice and cancels.

That is the quantitative reason the oil-price-risk channel is +7 bp rather than
+100 bp: the paper's own oil process is calibrated to be so persistent that oil
prices cannot move sovereign spreads much in this class of model.

Note that lowering persistence does **not** rescue FIGURE3 — the state
dependence gets *more* negative (0.856 → 0.542), consistent with §2: a bigger
price response makes the volatility-smoothing more visible, not less.

---

## What to take from this

- **FIGURE2**: no reversal to explain. The economies coincide. Report it as a
  null, or replace it with the mean-preserving comparison (+26.6 ± 5.2 bp),
  which is the one spread channel that is both significant and correctly
  signed.
- **FIGURE3**: the claim is contradicted by the model's economics, not just by
  a measurement problem. Volatility flattens the default margin. The published
  3× was a grid artifact.
- **The persistence point is a paper-level finding**, not a bug: with
  `rho_p = 0.98`, oil price risk is close to a permanent level shift and
  therefore weak for default incentives. If the paper wants large oil-driven
  spread movements it needs either a less persistent price process or a
  default cost that depends on the oil price directly rather than only on
  output.
