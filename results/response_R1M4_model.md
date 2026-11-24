# R1, Major 4 — the model comparison

*How much of the effect is specific to oil rather than to imported-input
volatility in general?*

> If feasible, a simple model-based comparison with a generic imported-input
> price process matched on persistence and unconditional volatility could also
> help assess how much of the quantitative effect is specific to oil rather than
> imported-input volatility more generally.

It is feasible, and it turns out to be in the paper already. We had not
presented it as this comparison, and we should have.

## The comparison economy already exists

A generic imported input is one whose price has no stochastic volatility: an
AR(1) in the log price with a fixed innovation variance. Matching such a process
to oil on persistence and unconditional volatility pins it down completely, and
what it is pinned to is the constant-volatility economy of Section 6.2. Within
this class, the only thing that distinguishes oil is the time variation in its
volatility.

Measured on the simulated paths rather than asserted from the parameters:

| economy | persistence of log p | sd(log p) | mean p |
|---|---|---|---|
| full (oil, stochastic volatility) | 0.94751 | 0.44065 | 1.24294 |
| constant volatility (generic input) | 0.94772 | 0.44025 | 1.24211 |
| difference | +0.02% | −0.09% | −0.07% |

The two economies agree to four decimal places on persistence and to within one
tenth of one percent on unconditional volatility, and they face the same average
price. So the comparison the referee asks for is the full economy against the
constant-volatility economy, and the decomposition already reports it.

## What the comparison says

| | spread | annual default rate |
|---|---|---|
| oil price risk at all (full − constant price) | +200.7 bp (±4.8) | +1.679 pp (±0.104) |
| of which time-varying volatility (full − constant vol) | +13.4 bp (±6.0) | +0.113 pp (±0.119) |

**On spreads, 187 of the 201 basis points — 93% — is what a generic imported
input with oil's persistence and volatility would deliver.** The part that
requires the volatility itself to move over time is 13.4 basis points, which is
distinguishable from zero but small: about 3% of the mean spread of 408 basis
points. On the default rate the time-varying part is not distinguishable from
zero at all.

Welfare splits the other way. Removing all oil price risk is worth 0.34% to
0.46% of consumption and removing only the time variation in volatility 0.19% to
0.22%, so roughly half of the welfare cost does come from the stochastic
volatility even though only a fifteenth of the spread effect does. We report
both rather than choosing the flattering one.

## What is, and is not, specific to oil

The referee's reading of the structure is correct and we now say so in the text:
mathematically the mechanism is an imported-input mechanism, not an oil
mechanism. Nothing in the production technology knows that the input is oil.

What is specific to oil is which input satisfies the premise. The referee's own
phrase is "any sufficiently important imported intermediate input," and the
question is which inputs are in fact sufficiently important and sufficiently
volatile. For the economies in our sample oil is 9% to 10% of GDP, its log price
has a quarterly persistence of 0.95, and its unconditional standard deviation is
0.44 — a 44 log-point spread in the price of a tenth of GDP. Few imported inputs
are simultaneously that large and that volatile, which is why the mechanism
binds here and would not bind for most other inputs. That is an empirical claim
about oil rather than a structural claim about the model, and we make it as one.

One thing this comparison does not settle. It isolates the price process while
holding the CES share and everything else fixed, so it answers "oil versus a
generic imported input," not "oil price volatility versus stochastic volatility
in external fundamentals more generally." Volatility in the endowment, as in
Seoane (2019), or in the world interest rate, as in Johri, Khan and Sosa-Padilla
(2022), enters the problem in a different place and is not nested in this
exercise. We take that comparison up in our reply to the first part of this
comment.

## Suggested manuscript wording

> The constant-volatility economy can be read as a generic imported input whose
> price is an AR(1) with a fixed innovation variance, matched to oil on
> persistence (0.948 against 0.948) and on unconditional volatility (0.440
> against 0.441) as well as on the average price level. On that reading, 187 of
> the 201 basis points by which oil price risk raises the mean spread is
> attributable to the input price being volatile and persistent at all, and 13
> basis points to the time variation in its volatility; the corresponding split
> of the welfare cost is closer to even. The mechanism is therefore a general
> imported-input mechanism, and what singles out oil is that it is both large
> enough, at 9 to 10 per cent of GDP, and volatile enough, at an unconditional
> standard deviation of 0.44 in logs, for the mechanism to matter quantitatively.

## Note

The matched moments are `table7_price_process.csv` and the channels are
`table3_decomposition.csv`, both written by `JEDC_decomposition.m` into
`model/economies_common_check/decomposition/`. Persistence and unconditional
volatility are computed on the simulated log price, dropping the 499 lag-1 pairs
that straddle a join between the 500 independent 1,500-quarter samples. The
constant-price economy has a single price node, so its persistence is undefined
and is reported as such. No new solves were needed for any of this.
