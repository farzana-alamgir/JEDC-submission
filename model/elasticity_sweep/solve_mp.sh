#!/bin/bash
# The fourth economy at the adopted sigma = 0.25, UNPRUNED. The sweep's copy
# was pruned down to the moments, but decomposition.py and horizon_check.py
# need the full graphs_* set, and the replication package needs all four
# economies solved from the committed sources.
set -u
cd "$(dirname "$0")"
SRC=/Users/farzanaalamgir/code/JEDC_submission/model/src_spdebt
d=runs_sig025/run_mean_preserving
rm -rf "$d"; mkdir -p "$d"
cp "$SRC/oil_prod_CES_mean_preserving.f90" "$d/src.f90"

# the source is already at sigma = 0.25; verify rather than patch
for want in 'alpha=5.779464d-5,' 'theta=-3.0d+0,' 'beta=0.971528d+0' 'd1 = 0.468175d+0' \
            'rho_p = 0.9475d+0' 'mean_p_vol = -4.012d+0' 'rho_p_vol = 0.7382d+0' \
            'eta = 0.2889d+0' 'd0 = -0.246d+0' \
            'parameter (va_default_cost = .true.)' 'parameter (kappa_risk = 0d+0)' \
            'parameter (use_common_p_grid = .true., mean_preserving'; do
  grep -qF "$want" "$d/src.f90" || { echo "FATAL: not set -- $want" >&2; exit 1; }
done
cmp "$d/src.f90" "$SRC/oil_prod_CES_mean_preserving.f90" || { echo "FATAL: copy differs" >&2; exit 1; }
gfortran -fsyntax-only "$d/src.f90" -J "$d" 2>"$d/syntax.log" || { echo "FATAL: will not compile" >&2; exit 1; }
echo "verified against the committed source; solving"
( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log && ./solverP > fort.6 2>&1 ) \
  || { echo "FAILED" >&2; exit 1; }
grep -q 'interior oil optimum' "$d/fort.6" && echo "WARN: interior-optimum failure"
python3 -I /Users/farzanaalamgir/code/JEDC_submission/model/analysis/moments_fast.py "$d" | tail -1
echo "sweep recorded: spread 3.9585  sd 2.9360  debt 34.1026"
