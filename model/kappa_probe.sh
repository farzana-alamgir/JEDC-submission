#!/bin/bash
# kappa_risk gradient probe on the CONVERGED common grid (p_num=277).
#
# WHY THIS EXISTS
#   The coarse p_num=7 sweeps in runs_kappa/ and runs_sdf/ show sd/spread near
#   the 0.488 data target (runs_sdf/k3.0 hits 0.485), which makes kappa_risk
#   look like the lever that fixes the ratio. It is an artifact: p_num=7
#   understates sd by ~38% while understating spread by only ~12%.
#
#     runs_va_final/bm      p=7     spread 4.4061  sd 2.9141  sd/sp 0.661
#     runs_common_v6/bm277  p=277   spread 4.9336  sd 4.0252  sd/sp 0.816
#     runs_common_v6/bm     p=549   spread 4.9229  sd 4.0063  sd/sp 0.814
#
#   277 and 549 agree to 0.5% on every moment, so 277 is converged and the
#   p=7 ratios cannot be used. kappa_risk has to be re-probed at 277 before it
#   can be judged.
#
# BASELINE  runs_common_v6/bm277: beta=0.972, d0=-0.246, d1=0.46,
#   va_default_cost=.true., use_common_p_grid=.true., p_num=277, kappa_risk=0.
#   Every run below varies kappa_risk ALONE, so each is directly differenced
#   against bm277. (runs_cal/* share this baseline at kappa_risk=0 too.)
#
# COST  4 runs in parallel on 10 cores, ~40 min wall clock by the runs_cal
#   precedent, ~1.7 GB per run (6.9 GB total). runs_kcal/ is gitignored.
#
# READ THE RESULT
#   python3 analysis/moments_fast.py runs_common_v6/bm277 runs_kcal/*
#   The number to watch is d(sd)/d(spread). beta, d0 and d1 all come out at
#   0.45-0.98; closing the ratio gap needs a lever above 1.0.
set -u
cd "$(dirname "$0")"

OUT=runs_kcal

run () {
  local tag=$1 k=$2
  local d=$OUT/$tag
  rm -rf "$d"; mkdir -p "$d"
  cp oil_prod_CES.f90 "$d/src.f90"

  perl -i -pe 's/alpha=0\.3d\+0/alpha=0.000307d+0/'                    "$d/src.f90"
  perl -i -pe 's/theta=0\.5d\+0/theta=-2.33333333d+0/'                 "$d/src.f90"
  perl -i -pe 's/beta=0\.96d\+0/beta=0.972d+0/'                        "$d/src.f90"
  perl -i -pe 's/d1 = 0\.3847d\+0/d1 = 0.46d+0/'                       "$d/src.f90"
  perl -i -pe 's/parameter \(va_default_cost = \.false\.\)/parameter (va_default_cost = .true.)/' "$d/src.f90"
  perl -i -pe 's/parameter \(use_common_p_grid = \.false\./parameter (use_common_p_grid = .true./' "$d/src.f90"
  perl -i -pe 's/p_num=7, p_vol_num=5/p_num=277, p_vol_num=5/'         "$d/src.f90"
  perl -i -pe "s/parameter \(kappa_risk = 0d\+0\)/parameter (kappa_risk = ${k}d+0)/" "$d/src.f90"
  # d0 is left at the source default, which is already the baseline -0.246.

  # Verify every setting landed BEFORE spending 40 minutes on the solve. A
  # silently unmatched perl pattern would otherwise hand back a run at the
  # wrong parameters that looks perfectly healthy.
  local want
  for want in 'alpha=0.000307d+0' 'theta=-2.33333333d+0' 'beta=0.972d+0' \
              'd0 = -0.246d+0' 'd1 = 0.46d+0' \
              'parameter (va_default_cost = .true.)' \
              'parameter (use_common_p_grid = .true.' \
              'p_num=277, p_vol_num=5' \
              "parameter (kappa_risk = ${k}d+0)"; do
    grep -qF "$want" "$d/src.f90" || { echo "FATAL $tag: not set -- $want" >&2; return 1; }
  done

  ( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log && ./solverP > fort.6 2>&1 ) \
    && echo "done   $tag (kappa_risk=$k)" \
    || { echo "FAILED $tag (kappa_risk=$k) -- see $d/build.log" >&2; return 1; }
}

# kappa_risk = 0 IS the baseline (runs_common_v6/bm277); do not re-solve it.
# -0.5 and +0.5 straddle it, giving a central difference at the baseline.
# +1.0 and +2.0 measure curvature, which turned out to matter a great deal
# for d0 (its one-sided derivatives disagreed by 28-43% over a span of 0.1).
run kneg0.5 -0.5 &
run k0.5     0.5 &
run k1.0     1.0 &
run k2.0     2.0 &
wait

echo
echo "next: python3 analysis/moments_fast.py runs_common_v6/bm277 $OUT/*"
