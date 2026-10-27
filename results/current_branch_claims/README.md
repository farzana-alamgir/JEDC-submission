# Current-branch full and mean-preserving solves

These runs start from `corrected-volatility` commit `0f27ce0`. They preserve its
calibration and enabled moment matching, and use a separate mean-preserving
copy. They do not use the alternative centered/stationary R calibration.

**Do not treat a run as a solved equilibrium unless its recorded status is
CONVERGED.** A completed executable with exit code zero is not sufficient.

## What is being checked

The original source stops when the maximum value-function change is below
1e-3, regardless of bond-price changes. These isolated runs require value and
paid-price changes below 1e-6 and unchanged default and debt policies. Damped
runs additionally require the undamped price-schedule residual below 1e-6.
The stricter checks affect the stopping rule, not the economic model.

The full and MP economies have exactly the same structural parameters:

| Parameter | Value |
|---|---:|
| Utility risk aversion | 2 |
| Discount factor | 0.96 |
| CES oil weight | 0.3 |
| CES exponent / substitution elasticity | 0.5 / 2 |
| Default-cost coefficients d0, d1 | -0.246, 0.3847 |
| World interest rate / bond decay | 0.01 / 0.03 |
| Re-entry probability | 0.0833 |
| Endowment persistence / innovation SD | 0.9 / 0.03 |
| Log-price center / persistence | 0.12 / 0.98 |
| Mean log variance / persistence / innovation SD | -4.33 / 0.66 / 0.44 |
| Lender price of risk / oil disruption | 0 / 0 |
| Debt / endowment / price / volatility nodes | 100 / 21 / 549 / 5 |
| Price / volatility grid half-widths | 3.5 / 2 stationary SDs |
| Moment matching | enabled |

The log-variance innovation parameter and log-price center are deliberately
preserved from the branch, not reinterpreted as new R estimates. The earlier
parameter-mapping questions remain separate research issues.

## Numerical methods and controls

1. Original undamped price updates, with the stronger stopping diagnostics.
   Initialized from the archived fin2 policies, then recomputing and iterating
   with the branch's current moment-matched kernels. Limit: 160 iterations.
2. Price-schedule relaxation of 0.2, initialized from the final states of run 1.
   Limit: 300 iterations.
3. Price-schedule relaxation of 0.05, independently initialized from run 1.
   Limit: 300 iterations.

For a relaxation weight w, the update is Q_next=(1-w)*Q_old+w*pricing_operator.
At convergence its fixed point is the same zero-profit pricing equation. No
default smoothing, additional shock, calibration change or altered preferences
are introduced. The undamped pricing residual is monitored so that a small
update step cannot falsely establish convergence.

The slow reference routines were first run for seven iterations. BLAS
contractions and a repayment-only vectorized debt scan were then checked
against those iterations. Value/price differences are at most machine rounding
and default/debt change counts are identical; see `acceleration_check.json`.
The vectorized scan is restricted to this branch's utility risk aversion of 2.
Default-free bond pricing uses the same recursion factored over y', p', h'.
Random simulation is skipped because the requested claims are conditional
policy comparisons, not simulated moments or welfare calculations.

The sources in the actual `model/` directory were not changed. Each generated
source, compiler flags, source hash, code diff, starting-value provenance and
stopping controls are recorded in this result folder. Large raw solver outputs
are ignored by Git. The aborted initial instrumentation trial and slow control
runs are retained under `raw/` and are not reported as completed solutions.

## Files

- `solve_diagnostics.csv`: status and final diagnostics for each solve attempt.
- `*_convergence.csv`: complete compact iteration histories outside raw storage.
- `*_pricing_residual.csv`: undamped price residuals for relaxed runs.
- `branch_source.f90`: snapshot of the branch source used for these runs.
- `bm_manifest.json`, `mp_manifest.json`: provenance for the undamped runs.
- `damped/` and `damped005/`: sources, manifests and diffs for relaxed runs.
- `provisional/`: conditional policy comparisons on the undamped terminal
  iterates. These are explicitly provisional if the solve did not converge.

Use `model/claim_tests/summarize_current_solves.py` to refresh the compact
diagnostics. Use `model/claim_tests/test_claims.py --current-runs ... --output ...`
for the controlled claim comparisons. That analysis rejects nonconverged runs
unless `--allow-provisional` is explicitly supplied.

## Interpretation

Convergence must be established before reporting amplification ratios or
precautionary borrowing as economic results. If pricing and policies continue
cycling, the correct finding is a numerical-solution problem, not proof that
the economic mechanisms exist or do not exist. Provisional tables can locate
the problem but must not be used as final paper results.
