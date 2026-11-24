# R2, Major 2

*Do the comparison economies face the same oil price?*

The referee is right, and the objection was serious. In the submitted version
the constant-price economy held the oil price at the median of its log-normal
distribution rather than at its mean. The median is **1.1275**; the average
price the full economy actually pays is **1.2429**. So the economy we were
calling "the same, without oil price risk" was in fact buying oil **10.2%
cheaper**, every quarter, for ever. Any welfare gain or spread difference we attributed to
removing risk included a permanent discount on oil.

The same problem, in smaller form, affected the constant-volatility economy.
Fixing volatility at the middle node of its grid is not the same as fixing it at
its average level: because the innovation variance enters exponentially, the
average of the variance exceeds the variance at the average, and an economy with
a more variable log price faces a higher average price level. This is the
convexity point the referee makes, and it ran in the same direction as the first
problem.

## What we changed

All four economies are now solved on one shared 277-node price grid, with the
same preferences, technology, default costs and shocks. Two pins moved:

- the constant-price economy is now held at **E[p]**, the mean of the price
  level, rather than at the median of its logarithm;
- the constant-volatility economy is now held at the **average innovation
  variance**, not at the middle node of the volatility grid.

The result is that the four economies face effectively the same oil price:

| economy | average oil price in simulation | difference from the full model |
|---|---|---|
| full | 1.2429 | — |
| mean-preserving | 1.2418 | −0.10% |
| constant volatility | 1.2421 | −0.07% |
| constant price | 1.2423 | −0.05% |

Within one tenth of one percent, against the 10% gap in the submitted version.
Whatever now separates these economies is risk, not the price of oil.

## What it does to the results

With the average price held fixed, removing **all** oil price risk is worth
between **0.34% and 0.46% of consumption**, depending on the level of output,
and removing only the *time variation* in volatility between **0.19% and
0.22%**. Both curves are positive everywhere and properly nested, which is what
removing strictly more risk has to deliver, and Figure 7 shows that.

These are smaller than the **1.1%** in the submitted paper, but we should not
claim the whole of that difference for this correction. The substitution
elasticity has also been recalibrated since submission, in response to Major 3
of the other report, and the welfare cost of oil price risk is sensitive to it.
We have not re-run the matched comparison at the original elasticity, so we
cannot divide the change between the two. What we can say is the referee's
point itself: under the old construction the comparison economy bought oil
10.2% cheaper for ever, and that discount was being counted as a gain from
removing risk.

The spread comparison survives better. The difference in mean spreads between
the full economy and the constant-price economy is **200.7 basis points**, and
because both now face the same average oil price this is a risk effect rather
than a price-level effect. It is about half the mean spread, so oil price risk
still matters a great deal to these borrowers.

The referee also asks for a comparison economy that varies only in dispersion.
We have built it, and it is the subject of our reply to Major 1.

## Where this leaves the paper

Section 6.2 and the welfare discussion have been rewritten around the matched
economies. The headline welfare number falls from 1.1% to roughly 0.4%, and we
say plainly in the text why it fell.

---

### Suggested manuscript wording

> The comparison economies are constructed to face the same average oil price
> as the full model. The constant-price economy is pinned at E[p] rather than
> at the median of the log price distribution, and the constant-volatility
> economy at the average innovation variance rather than at the central
> volatility node; simulated average prices then agree across the four
> economies to within 0.1%. Under this construction, removing all oil price
> risk is worth between 0.34% and 0.46% of consumption and removing only the
> time variation in volatility between 0.19% and 0.22%, against a mean-spread
> difference of 200.7 basis points for oil price risk as a whole. An earlier
> version of this comparison held the constant-price economy at the median of
> the log-normal distribution, so that it faced oil roughly 10% cheaper on
> average; the welfare gains reported there were correspondingly larger.

### Note

The four economies are `model/economies_common_check/{benchmark,
mean_preserving, intermediate, basic}`, one standalone Fortran source each, and
the pins are the `p_grid` assignments in the constant-price and
constant-volatility sources. Simulated average prices are computed over the
whole simulation, not over pre-default windows: the table above is
`table6_mean_price.csv`, written by `model/analysis/JEDC_decomposition.m` to
`model/economies_common_check/decomposition/` along with the other tables and
the figure. Welfare curves are from `ALL_FIGURES_common_grid.m`, Figure 7.
