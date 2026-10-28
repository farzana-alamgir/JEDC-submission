# A risk premium on oil price risk recovers FIGURE3's ordering

Tested `kappa_risk`, the price of oil price risk in the lenders' stochastic
discount factor, on top of the value-added default cost calibration. Runs in
`model/runs_kappa/`, figure at `results/FIGURE3_kappa3.jpg`.

    log m' = -rstar + kappa*eps_p' - 0.5*kappa^2*Var(eps_p' | sigma')

`kappa > 0` makes the SDF high when oil is unexpectedly expensive. For an
importer that is exactly when default is likely and the bond pays least, so
the bond is a poor hedge and carries a premium. Crucially the normalisation
uses the **state-specific** conditional variance, so the premium scales with
each volatility state's own sd — which is the state dependence FIGURE3 claims.

## Result: the ordering flips at kappa ~ 2.7

Spread slope at the matched-price contrast, i_b = 44:

| kappa | vol 1 | vol 2 | vol 3 | vol 4 | vol 5 | ratio 4/2 |
|---|---|---|---|---|---|---|
| 0 | 0.03046 | 0.02379 | 0.01894 | 0.01478 | 0.01132 | 0.621 |
| 0.5 | 0.03352 | 0.02693 | 0.02071 | 0.01714 | 0.01318 | 0.637 |
| 1.0 | 0.03153 | 0.02607 | 0.02037 | 0.01819 | 0.01481 | 0.698 |
| 2.0 | 0.02871 | 0.02490 | 0.02005 | 0.01927 | 0.01720 | 0.774 |
| 2.5 | 0.02151 | 0.01985 | 0.01702 | 0.01812 | 0.01801 | 0.913 |
| **3.0** | 0.01169 | 0.01291 | 0.01246 | 0.01595 | **0.01826** | **1.235** |

Monotone in `kappa`, crossing 1 at about **2.7**. The mechanism is visible in
the columns: the high-volatility slope rises steadily (0.0113 -> 0.0183, +61%)
while the low-volatility slope falls. At `kappa = 3` the slope *increases*
with volatility, and `FIGURE3_kappa3.jpg` shows High above Mean above Low for
output above about 9.2 (it still reverses below that).

## Correction to an earlier conclusion

Earlier notes in this revision concluded that the FIGURE3 claim was
"structurally unavailable in this model class", on the evidence that four
separate interventions — lower `rho_p`, the oil-disruption premium, the
value-added default cost, and matched-price measurement — all pushed the ratio
further below 1.

**That was wrong, and the reason is identifiable.** All four were tested under
**risk-neutral** pricing (`kappa_risk = 0`). Under risk neutrality the spread
is a pure default probability, and as a function of today's price that is a
step convolved with the conditional distribution of `p'` — widening the kernel
can only flatten it. The convolution argument is correct, but it governs only
the *default-probability* component of the spread. A risk premium is a second
component the argument does not cover, and it scales with volatility in the
opposite direction. Adding it reverses the sign.

## What it costs

| | target | kappa = 0 | kappa = 2.5 | kappa = 3.0 |
|---|---|---|---|---|
| mean spread | 4.1 | 4.41 | 5.26 | 4.81 |
| sd(spread) | 2.0 | 2.91 | 3.10 | 3.24 |
| debt/GDP | 34.0 | **33.69** | 25.05 | **25.02** |
| oil/GDP | 9.0 | 8.73 | 10.25 | 9.91 |

Two caveats, both real:

1. **The calibration breaks.** debt/GDP falls to 25 against a 34 target. A
   joint re-fit of `beta`, `d0`, `d1` at the chosen `kappa` is required before
   any of these numbers can be reported. `kappa = 4` fails outright — only 284
   default episodes and the spread collapses to 2.57.

2. **The required price of risk is high.** `kappa = 3` implies a maximum
   quarterly Sharpe ratio of `kappa * sd(eps_p) = 3 * 0.125 = 0.375`, roughly
   0.75 annualised. That is above the equity Sharpe (~0.4) though within the
   range used in the sovereign-debt asset-pricing literature. It needs
   justifying, not asserting.

## Magnitude

The ratio at `kappa = 3` is **1.235**, not the paper's 3.0. The *sign* and
*ordering* are recovered; the *magnitude* is about a quarter of the claim.
Pushing further requires `kappa` beyond 3, where the model degrades.

Note also that the published 3.0 was itself inflated by the per-state grid
artifact (`SUMMARY_OPTION_A.md` §6), so 3.0 was never a clean target.

## Recommendation

This is the right mechanism to put in the paper. Risk premia in sovereign
spreads are standard and well documented, the model already implements it, and
it answers R1 major 5 at the same time. The honest framing is:

- oil price risk raises spreads (+206 bp) and is welfare-costly (+0.73%) under
  risk-neutral pricing already;
- the *state dependence* of the spread response requires risk-averse lenders,
  and is quantitatively modest (about 1.2x, not 3x);
- under risk neutrality it has the opposite sign, which is itself a result
  worth reporting since it isolates what the risk premium is doing.

Next step if adopted: joint (beta, d0, d1) re-fit at `kappa = 3`, then redraw.
