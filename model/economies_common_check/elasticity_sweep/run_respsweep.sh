#!/bin/bash
# Five benchmark solves for R1 Major 3, two at a time. sigma = 0.25 is the
# adopted calibration and is already on disk, so it is extracted rather than
# re-solved. (beta, d1) at each sigma are the points recalsweep.sh landed.
set -u
cd "$(dirname "$0")"

run() { ./respsweep.sh "$@"; }

#          sigma  theta             alpha       beta       d1
run 0.20 '-4.0d+0'        '4.709d-6' 0.971010 0.460215 &
run 0.30 '-2.33333333d+0' '3.070d-4' 0.970654 0.468505 &
wait
run 0.35 '-1.85714286d+0' '1.011d-3' 0.970366 0.478420 &
run 0.40 '-1.5d+0'        '2.467d-3' 0.970796 0.488276 &
wait
run 0.50 '-1.0d+0'        '8.579d-3' 0.970215 0.508393
echo "ALL DONE"
sort -t, -k1 -g sweep_resp/responses.csv
