# Separate oil-price validation

The submitted sovereign model and its outputs have not been changed. This folder
contains a standalone candidate price process and checks of its numerical
approximation. It does **not** contain a new sovereign-model calibration, a
mean-preserving decomposition, or revised paper results.

## Result in plain language

The separate numerical process reproduces the candidate equations closely for
the log-price statistics checked:

| Statistic | Equation target | Direct simulation | Discrete process |
|---|---:|---:|---:|
| Average log price | -0.112657 | -0.109847 | -0.112657 |
| Standard deviation of log price | 0.552877 | 0.550897 | 0.553843 |
| Log-price persistence | 0.968360 | 0.968094 | 0.968358 |

The discrete standard deviation differs from the equation target by about 0.17%.
Refining 201 price / 21 volatility nodes to 401 / 41 changes that statistic by
about 0.53%. Changes in bounds in the checks remain below 1%. The independent
Python and Fortran probability calculations agree within 1e-12 (observed maximum
difference: zero on the comparison grid).

These are numerical checks of a **candidate** specification. They do not show
that it is uniquely preferred by the data, or validate sovereign spreads,
borrowing, default, welfare, or price-level tail moments.

## Candidate and provenance

The input estimates were supplied by the user in this chat. The model was fitted
with its log-price center fixed to the observed sample center, and complete
posterior draws were retained conditional on stationary price persistence. The
original posterior object and raw draws are not saved in this repository, so this
folder reproduces the calculation at the supplied rounded point estimates,
not the Bayesian estimation or its convergence checks.

Use log variance `h` consistently:

```
h_next = mu_h + rho_h * (h - mu_h) + eta_h * normal_shock
z_next = center + rho_p * (z - center) + exp(h_next / 2) * normal_shock
```

The two shocks are independent. `z` is the log of price divided by the observed
sample-average real price. This normalization makes the **observed sample** mean
price one; it does not impose a stationary mean price of one.

| Parameter | Value |
|---|---:|
| Fixed center | -0.1126566 |
| Price persistence | 0.9683596 |
| Mean log variance | -4.2718859 |
| Log-variance persistence | 0.6677605 |
| Log-variance innovation standard deviation | 0.5866213 |

If integrating with log-standard-deviation notation, divide `h`, `mu_h`, and
`eta_h` by two. Do not divide either persistence by two. The implementation here
keeps log variance to avoid that ambiguity.

## Files and reproduction

- `price_kernel.f90`: standalone Fortran module with a common physical log-price
  grid, matched volatility nodes/probabilities, exact normal CDF cell masses, and
  explicit future-volatility timing.
- `check_kernel.f90`: small driver for independent probability comparisons.
- `validate.py`: analytical moments, independent equation simulation, stationary
  Markov-chain moments, conditional-moment checks, and grid/bounds sensitivity.
- `results.json` and `grid_checks.csv`: saved results from the completed run.
- `candidate_kernel.npz`: generated factorized kernel and joint stationary
  distribution; ignored by Git because it is regenerable.

Requirements: Python 3, NumPy, and gfortran. No SciPy or R is required to run these
numerical checks. Run from the repository root:

```
python3 oil_price_validation/validate.py
```

On the current machine, the tested Python with NumPy is:

```
/Users/farzanaalamgir/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3 oil_price_validation/validate.py
```

The compiler runs in a temporary directory, so compiler module files do not
overwrite any files under `model/`. The validator writes only inside this folder.

## Numerical conventions and checks

The joint transition is

```
K((z_i,h_k),(z_j,h_l)) = S[k,l] * P[l,i,j]
```

`P` has Python shape `(future volatility, current price, future price)`; the
Fortran routine exposes `p(current price, future price, future volatility)`.
The same physical `z_i` applies in every volatility regime. Tail probability
beyond the grid is assigned to boundary nodes, not discarded and renormalized.

The joint stationary distribution is obtained using this exact factorized kernel;
it is not the product of separately calculated marginals. The analytic log-price
variance target is

```
Vh = eta_h**2 / (1 - rho_h**2)
Var(z) = exp(mu_h + Vh/2) / (1 - rho_p**2)
```

The program checks probability normalization, nonnegativity, convergence of the
stationary distribution, agreement with the analytic log-price variance and
persistence, weighted conditional mean error, agreement of the Fortran and Python
implementations, and sensitivity of log-price standard deviation to refinement
and bounds. Direct simulation uses 1,000,000 retained quarters after 10,000 burn-in
quarters and NumPy seed 123; it is not expected to reproduce R's random sequence.

## Limits before integration into the sovereign model

1. **Boundary accuracy:** maximum conditional errors at extreme price/volatility
   combinations are appreciable. In the reference grid, the largest conditional
   log-mean error is about 0.228, although the stationary-weighted RMS error is
   about 0.000077. Price-boundary mass is about 0.0000011. The current checks
   support aggregate log moments, not uniform accuracy for every default-relevant
   tail state. Those tails need targeted checks when the sovereign model is run.
2. **Cost:** 401 price and 41 volatility nodes are a validation reference, not a
   proposed production sovereign-model grid. An economical approximation needs
   its own economic-result convergence assessment.
3. **Production feasibility:** the wider corrected price support reaches below
   0.09. With the submitted code's CES parameters alpha=0.3, theta=0.5, marginal
   product tends to alpha**(1/theta)=0.09 as oil use grows. At prices below that
   threshold, unconstrained net production is unbounded. The existing oil-search
   cap must not silently determine results. This needs an explicit economic
   treatment before integration; this folder makes no production changes.
4. **Estimation:** fixing the center and conditioning on stationarity are explicit
   restrictions. Compare with the original fit and inspect posterior convergence
   before adopting the candidate as the revised benchmark.
5. **Interpretation:** no expected price-level means, welfare gains, or
   mean-preserving counterfactual results are inferred from these log-moment
   checks. Price-level moments under bounded numerical volatility can depend on
   truncation; do not assume a Gaussian unconditional log-price distribution.

Next: resolve production feasibility and select an accurate, economical kernel
before integrating into a separate sovereign-model version. Keep the submitted
baseline available for comparison.
