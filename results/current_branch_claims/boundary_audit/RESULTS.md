# Oil-price boundary audit

The central price region used in the conditional claim tests is accurately
represented, but the original finite-grid MP process is not globally
mean-preserving. This is an approximation finding, not an economic claim test.

| Diagnostic | Full SV | MP SV |
|---|---:|---:|
| Worst relative error in conditional expected level price | 10.50% | 12.09% |
| Worst error in central price region | 5.62e-11 | 1.44e-12 |
| Stationary probability of the two endpoint nodes | 0.0710% | 0.0748% |
| Stationary weighted absolute relative level-mean error | 0.00207% | 0.00278% |
| Rows missing log-moment targets by more than 1e-8 | 22 / 2745 | 21 / 2745 |

The stationary weights are calculated for the exogenous joint price/volatility
chain with the same timing as the solver. They are not default probabilities.
The central region is 0.8 to 1.5 times exp(0.12). Volatility grids in text outputs
are rounded to eight decimals; a 1e-8 tolerance avoids calling that rounding a
moment-matching failure.

Matching two log moments does not generally match E[exp(z)] on truncated support.
The MP conditional expected level price varies by as much as 6.62% across current
volatility states at the lower boundary, after averaging over future volatility.
The central-region range is about 5.25e-15.

## Extending the upper grid

A separate kernel-only test added 64 nodes while preserving all original nodes
and their spacing, increasing the upper price from 10.1650 to 16.9892. At the
old upper boundary, the MP conditional level-mean error fell from at most 1.94%
to 0.00378%; its cross-current-volatility mean range fell from 0.786% to 0.00184%.
However, the worst lower-edge level-mean error rose from 12.09% to 17.13%. This
extension therefore does not fix the entire process. No economic model was
solved on the extended grid. See ../upper_boundary_extension/comparison.json.

## The technology limits lower-tail extensions

With theta=0.5 and alpha=0.3, output net of oil expenditure is

    (1-alpha)^2*A + 2*alpha*(1-alpha)*sqrt(A*m) + (alpha^2-p)*m.

Consequently a finite optimal oil input requires p>alpha^2=0.09. At p<=0.09
net resources increase without bound as oil input increases. This follows from
the production function, not a numerical bisection tolerance. The existing grid
minimum 0.1251 respects the restriction. An unrestricted Gaussian log-price law
has support below this threshold, so lower-tail support and technology must be
specified consistently in the mathematical model. These experiments retain the
existing bounded grid and do not change the technology or impose an input cap.

## A tested alternative

An exponential tilt in level price can match the intended conditional expected
level price at every grid point. The MP version also passed a full finite-support
convex-order check, giving a genuine conditional mean-preserving spread across
volatility states. This sacrifices log-moment accuracy near the boundaries.
See ../level_mean_kernel_audit/RESULTS.md. It is an alternative discretization,
not evidence that the economic model has converged.
