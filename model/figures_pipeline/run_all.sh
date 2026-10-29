#!/bin/bash
set -u
F="$(cd "$(dirname "$0")" && pwd)"; S="$(dirname "$F")"
MATLAB=/Applications/MATLAB_R2025a.app/bin/matlab
cd "$F"
stage () {
  echo "=== $1  ($(date +%H:%M)) ==="
  find . -maxdepth 1 -name 'graphs_*.txt' -delete; rm -f p_grid.txt p_vol_grid.txt
  cp "$2"/graphs_*.txt "$2"/p_grid.txt "$2"/p_vol_grid.txt . 2>/dev/null
  rm -f graphs_data_sim_dss.txt
  "$MATLAB" -batch "run('script_$1.m')" > "ml_$1.log" 2>&1
  echo "  exit=$?  workspace=$(ls -la oil_$1.mat 2>/dev/null | awk '{print $5}')B"
}
stage intermediate "$S/fin2/run_cv"
stage basic        "$S/fin2/run_basic"
find . -maxdepth 1 -name 'FIGURE*.jpg' -delete
stage bm           "$S/fin2/run_bm"
echo "=== figures: $(ls FIGURE*.jpg 2>/dev/null | wc -l | tr -d ' ') ==="
