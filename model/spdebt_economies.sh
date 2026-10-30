#!/bin/bash
# The other three economies at the spdebt calibration (beta=0.9746, d1=0.4731,
# d0=-0.246), so the channel decomposition and the ten figures can be
# regenerated at a calibration that fits better than the one shipped.
#
# WHY  JEDC_common_grid_final ships beta=0.972, d1=0.46, which misses the four
#   targets by 20.3% / 101.3% / 1.8% / 3.8% (spread, sd, debt, oil share).
#   runs_bd1/spdebt at beta=0.9746, d1=0.4731 misses by 0.2% / 81.3% / 0.2% /
#   0.9% -- better on all four, with d0 left at its submitted -0.246. The
#   deliverable's channels and figures were computed at the old calibration, so
#   the other three economies have to be re-solved before anything can be
#   regenerated.
#
# METHOD  Each economy is built from the EXACT source that produced the current
#   figure set -- runs_common_v6/{int_c,mp_c,basic_c}/src.f90 -- with only beta
#   and d1 changed. Nothing else is touched, so each economy's own volatility
#   treatment is preserved byte-for-byte:
#     int_c    = bm277 + constant_vol = .true.
#     mp_c     = bm277 + mean_preserving = .true.
#     basic_c  = bm277 + constant_vol + p_num=1, p_vol_num=1 + pinned p_grid
#
# THE BENCHMARK IS ALREADY SOLVED: runs_bd1/spdebt. Not repeated here.
#
# basic's PINNED PRICE IS LEFT ALONE, deliberately. It is pinned at
#   p_grid = 0.316427 because the basic economy must face the benchmark's
#   ergodic mean price. beta and d1 do not enter the price process, and the
#   simulated E[p] is 1.372100 at beta=0.972, at 0.9746 and at 0.9847 alike --
#   identical to six decimals. So the pin stays valid. (Note: 0.316427 is
#   log(1.372216), while log(1.372100) = 0.316343 -- the shipped pin is 0.0085%
#   high. Negligible, inside the README's own 0.06% tolerance, and left as is so
#   these runs stay comparable to the shipped figure set.)
#
# COST  intermediate and mean_preserving ~40 min in parallel, ~1.7 GB each;
#   basic is seconds. runs_spdebt/ is gitignored.
#
# READ THE RESULT
#   python3 analysis/moments_fast.py runs_bd1/spdebt runs_spdebt/*
#   Channels: benchmark minus each of basic / intermediate / mean_preserving,
#   in bp, against the shipped +286.0 / +7.3 / +3.2.
set -u
cd "$(dirname "$0")"

OUT=runs_spdebt
NEW_B=0.9746
NEW_D1=0.4731

run () {
  local tag=$1 srcdir=$2 switch=$3
  local d=$OUT/$tag
  rm -rf "$d"; mkdir -p "$d"
  cp "runs_common_v6/$srcdir/src.f90" "$d/src.f90"

  perl -i -pe "s/beta=0\.972d\+0/beta=${NEW_B}d+0/"   "$d/src.f90"
  perl -i -pe "s/d1 = 0\.46d\+0/d1 = ${NEW_D1}d+0/"   "$d/src.f90"

  local want
  for want in "beta=${NEW_B}d+0" "d1 = ${NEW_D1}d+0" 'd0 = -0.246d+0' \
              'alpha=0.000307d+0' 'theta=-2.33333333d+0' \
              'parameter (va_default_cost = .true.)' \
              'parameter (kappa_risk = 0d+0)' \
              "$switch"; do
    grep -qF "$want" "$d/src.f90" || { echo "FATAL $tag: not set -- $want" >&2; return 1; }
  done
  # and assert the OLD values are gone
  for gone in 'beta=0.972d+0' 'd1 = 0.46d+0'; do
    grep -qF "$gone" "$d/src.f90" && { echo "FATAL $tag: stale -- $gone" >&2; return 1; }
  done

  ( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log && ./solverP > fort.6 2>&1 ) \
    && echo "done   $tag" \
    || { echo "FAILED $tag -- see $d/build.log" >&2; return 1; }
}

run intermediate     int_c   'parameter (constant_vol = .true.)' &
run mean_preserving  mp_c    'mean_preserving = .true.'          &
run basic            basic_c 'p_grid = 0.316427d+0'              &
wait

echo
echo "next: python3 analysis/moments_fast.py runs_bd1/spdebt $OUT/*"
