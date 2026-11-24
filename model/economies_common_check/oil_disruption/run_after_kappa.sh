#!/bin/bash
# Waits for the R1 Major 5 kappa sweep to finish, then runs the R2 Major 3
# disruption sweep at the adopted sigma_oil = 0.25. Chained rather than
# concurrent so no more than two solves share the machine at once.
set -u
cd "$(dirname "$0")"

echo "[$(date +%H:%M:%S)] waiting for the kappa sweep to finish"
while pgrep -f "kappasweep.sh" > /dev/null; do sleep 60; done
echo "[$(date +%H:%M:%S)] kappa sweep done; starting the disruption sweep"

./disruptsweep.sh 0.10 &
./disruptsweep.sh 0.25 &
wait
./disruptsweep.sh 0.50
echo "ALL DONE"
sort -t, -k1 -g sweep/disrupt.csv
