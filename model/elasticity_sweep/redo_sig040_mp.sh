#!/bin/bash
# sigma = 0.40 mean_preserving, which died when the shared source directory was
# switched to sigma = 0.25 mid-sweep. Patched from the CURRENT (sigma 0.25)
# source, so the substitution targets are the 0.25 literals, not the 0.30 ones
# recalsweep.sh expects.
set -u
cd "$(dirname "$0")"
SRC=/Users/farzanaalamgir/code/JEDC_submission/model/src_spdebt
d=sweep_recal/sig0.40_mean_preserving
rm -rf "$d"; mkdir -p "$d"
cp "$SRC/oil_prod_CES_mean_preserving.f90" "$d/src.f90"

perl -i -pe 's/alpha=5\.779464d-5/alpha=2.466742d-3/'   "$d/src.f90"
perl -i -pe 's/theta=-3\.0d\+0/theta=-1.5d+0/'          "$d/src.f90"
perl -i -pe 's/beta=0\.971528d\+0/beta=0.970796d+0/'    "$d/src.f90"
perl -i -pe 's/d1 = 0\.468175d\+0/d1 = 0.488276d+0/'    "$d/src.f90"

for want in 'alpha=2.466742d-3,' 'theta=-1.5d+0,' 'beta=0.970796d+0' 'd1 = 0.488276d+0' \
            'rho_p = 0.9475d+0' 'mean_p_vol = -4.012d+0' 'rho_p_vol = 0.7382d+0' \
            'eta = 0.2889d+0' 'd0 = -0.246d+0' \
            'parameter (va_default_cost = .true.)' 'parameter (kappa_risk = 0d+0)' \
            'parameter (use_common_p_grid = .true., mean_preserving'; do
  grep -qF "$want" "$d/src.f90" || { echo "FATAL: not set -- $want" >&2; exit 1; }
done
for gone in 'alpha=5.779464d-5' 'theta=-3.0d+0' 'beta=0.971528d+0' 'd1 = 0.468175d+0'; do
  grep -qF "$gone" "$d/src.f90" && { echo "FATAL: stale 0.25 literal -- $gone" >&2; exit 1; }
done
gfortran -fsyntax-only "$d/src.f90" -J "$d" 2>"$d/syntax.log" || { echo "FATAL: will not compile" >&2; exit 1; }
echo "patched to sigma 0.40 and compile-clean; solving"
( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log && ./solverP > fort.6 2>&1 ) \
  || { echo "FAILED" >&2; exit 1; }
python3 -I /Users/farzanaalamgir/code/JEDC_submission/model/analysis/moments_fast.py "$d" | tail -1
