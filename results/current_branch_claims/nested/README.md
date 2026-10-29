# Nested solver experiment

This experiment keeps the economic equations, calibration and grids of commit
0f27ce0. It starts separately from each terminal 0.05-relaxation run.

For each price update, the borrower Bellman operator is iterated at a fixed
issuance-price schedule until its maximum value change is below 1e-9 (or 200
inner sweeps). The next schedule is updated with weight 0.10. The raw, undamped
pricing residual is checked on every sweep. Final acceptance still requires
value and paid-price changes below 1e-6, raw pricing error below 1e-6, and no
changes to default or borrowing choices. A small inner error alone is not
full equilibrium convergence.

`raw/bm` and `raw/mp` contain generated sources and complete diagnostic histories.
`*_switching_examples.txt`, when present, captures observed switching states:
indices (debt, endowment, price, volatility), debt, log endowment, log price,
repayment-minus-default value, old decision, new decision. Decisions 1 and 2
mean repayment and default. The monitor samples files; these are examples, not
a complete count. Full counts are in convergence.csv.

Run with the bundled Python and NumPy runtime:

    VECLIB_MAXIMUM_THREADS=1 python model/claim_tests/solve_nested.py bm --max-iterations 600
    VECLIB_MAXIMUM_THREADS=1 python model/claim_tests/solve_nested.py mp --max-iterations 600

Original model source remains untouched. No economic conclusions should be
reported from an unfinished or nonconverged run.
