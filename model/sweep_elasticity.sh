#!/bin/bash
set -u
cd "$(dirname "$0")"
OUT=runs_elasticity; mkdir -p $OUT
# sigma  alpha           theta
SPECS="0.3:0.000188992:-2.33333333
0.5:0.00663861:-1.0
0.8:0.0475319:-0.25
1.2:0.13613:0.16666667
1.5:0.2023:0.33333333
2.0:0.290215:0.5"
build () { # name extra_perl...
  local d=$OUT/$1; shift; mkdir -p $d; cp oil_prod_CES.f90 $d/src.f90
  for e in "$@"; do perl -0pi -e "$e" $d/src.f90; done
  ( cd $d && gfortran -O3 -march=native -o solver src.f90 2>build.log \
      && ./solver > fort.6 2>&1; echo $? > exit.code )
}
for spec in $SPECS; do
  s=${spec%%:*}; rest=${spec#*:}; a=${rest%%:*}; t=${rest#*:}
  A="s/alpha=0\.3d\+0/alpha=${a}d+0/"
  T="s/theta=0\.5d\+0/theta=${t}d+0/"
  build "s${s}_bm"      "$A" "$T" &
  build "s${s}_basic"   "$A" "$T" \
    's/constant_vol = \.false\./constant_vol = .true./' \
    's/p_num=7, p_vol_num=5/p_num=1, p_vol_num=1/' \
    's/p_grid = mean_p \+ 0\.5d\+0\*mean_innov_var\/\(1d\+0 - rho_p\*\*\(2d\+0\)\)/p_grid = 0.288107d+0/' &
done
wait
for spec in $SPECS; do
  s=${spec%%:*}
  for k in bm basic; do
    d=$OUT/s${s}_$k
    printf "%-16s exit=%s  %s\n" "s${s}_$k" "$(cat $d/exit.code 2>/dev/null)" \
      "$(grep -icE 'iterations exceeded|NaN' $d/fort.6 2>/dev/null) errors"
  done
done
