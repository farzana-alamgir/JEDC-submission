#!/bin/bash
# Three solves for R1 Major 5, two at a time. kappa_risk = 0 is the economy of
# record (../benchmark) and is not re-solved. The values bracket the plausible
# range: at sigma_oil = 0.30 the implied annualised Sharpe ratio was about 0.25
# per unit of kappa, so kappa = 1 to 2 is near the equity benchmark of 0.4 and
# kappa = 3 is already well past it.
set -u
cd "$(dirname "$0")"
./kappasweep.sh 1.0 &
./kappasweep.sh 2.0 &
wait
./kappasweep.sh 3.0
echo "ALL DONE"
sort -t, -k1 -g sweep/kappa.csv
