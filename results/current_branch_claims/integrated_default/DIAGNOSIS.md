# Independent diagnosis of the stopped runs

Both runs stopped under the pricing-stall rule, not under the equilibrium convergence rule. These are experimental numerical refinements at unchanged branch economic parameters, not validated paper results.

| Independent check | Full process (bm) | Mean-preserving candidate (mp) |
|---|---:|---:|
| Maximum one-step bond-pricing residual | 0.0028255744 | 0.0031474231 |
| Median pricing residual | 0.0000020766 | 0.0000001337 |
| 99th percentile pricing residual | 0.0002425456 | 0.0000533018 |
| Fraction of states with pricing error above 1e-6 | 63.62% | 22.66% |
| Full-grid saved-policy value residual | 2.067e-6 | 1.181e-7 |
| Maximum borrowing optimality regret in 162 independently checked states | 1.128e-9 | 8.177e-12 |
| Last fixed-policy lender linear-system residual | 9.605e-11 | 8.694e-11 |

The largest full-process pricing error is at oil price 0.12506, low endowment, and proposed debt 11.471; other large errors are around oil price 5.3 and debt 14.544. The mean-preserving candidate's largest error is near oil price 7.493 and debt 9.832, at mean log endowment. Thus a lower-price-boundary fix alone cannot resolve both models.

The evidence points to the joint feedback between borrowing/default decisions and bond prices as the remaining numerical obstacle. Borrowing optimization is accurate in the independently checked states, and the fixed-policy lender equations are solved accurately. Neither fact proves convergence of the joint problem. At the last outer update, repayment/default and borrowing decisions still change. The full-process saved borrower policy also needs further updating against its terminal price schedule.

The stall rule means twelve pricing updates without a new five-percent improvement in the best residual. It is not evidence that an equilibrium does not exist. A controlled continuation with a smaller price step, retaining these terminal arrays as warm starts and checking fresh pricing residuals, is the next numerical experiment. Do not change economic parameters to obtain the desired claim.

Do not use these arrays to certify amplification or precautionary borrowing. Conditional comparisons require a converged solution and consistent continuous-endowment expectations. Simulations require a simulator consistent with the new integration scheme.

Detailed evidence: bm_independent_pricing_check.json, mp_independent_pricing_check.json, bellman_audit/*_bellman_and_debt_grid.json, and raw/*/{convergence,nested_history,fixed_policy_pricing,pricing_progress}.csv.

The tracked original model file is unchanged (SHA256 4c6ffdd79d2b7a7cda32670b0e6641fefff1a824cd75d36e228c927dd476f9ff).
