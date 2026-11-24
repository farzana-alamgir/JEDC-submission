#!/bin/bash
# R2 Major 3 at the adopted sigma_oil = 0.25. Three solves, two at a time.
#
# This writes sweep/DONE when it finishes. A watcher should wait for THAT FILE,
# not for a process name: an earlier version waited on `pgrep -f kappasweep.sh`
# and matched the watcher's own command line, so the two waited on each other
# and nothing ran for eight hours.
set -u
cd "$(dirname "$0")"
rm -f sweep/DONE
./disruptsweep.sh 0.10 &
./disruptsweep.sh 0.25 &
wait
./disruptsweep.sh 0.50
echo "ALL DONE"
sort -t, -k1 -g sweep/disrupt.csv
touch sweep/DONE
