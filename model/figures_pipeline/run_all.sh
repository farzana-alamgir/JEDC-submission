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
  echo "  exit=$?  workspace=$(ls -la oil_$1.mat 2>/dev/null | awk '{print int($5/1048576)}')MB"
  grep -iE '^error|Error using|Index exceeds' "ml_$1.log" | head -2
}
stage intermediate "$S/wrun_cv"      # constant volatility, price still moving
stage basic        "$S/wrun_basic"   # both constant
find . -maxdepth 1 -name 'FIGURE*.jpg' -delete
stage bm           "$S/wrun_bm"    # full SV, drawn last so FIGURE2/7 see the others
echo "=== figures: $(ls FIGURE*.jpg 2>/dev/null | wc -l) ($(date +%H:%M)) ==="
echo DONE > run_all.done
