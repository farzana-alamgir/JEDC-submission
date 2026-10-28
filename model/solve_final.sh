#!/bin/bash
# Solve all five economies at a given (sigma_oil implied theta, alpha, beta, d0, d1)
# and stage them for the figures pipeline.
#
# Usage: ./solve_final.sh <outdir> <alpha> <theta> <beta> <d0> <d1>
# e.g.   ./solve_final.sh runs_final 0.000188992 -2.33333333 0.965 -0.246 0.37
set -u
cd "$(dirname "$0")"
OUT=$1; A=$2; T=$3; B=$4; D0=$5; D1=$6
rm -rf $OUT; mkdir -p $OUT

build () {
  local d=$OUT/$1; shift; mkdir -p $d; cp oil_prod_CES.f90 $d/src.f90
  perl -0pi -e "s/alpha=0\.3d\+0/alpha=${A}d+0/"        $d/src.f90
  perl -0pi -e "s/theta=0\.5d\+0/theta=${T}d+0/"        $d/src.f90
  perl -0pi -e "s/beta=0\.96d\+0/beta=${B}d+0/"         $d/src.f90
  perl -0pi -e "s/d0 = -0\.246d\+0/d0 = ${D0}d+0/"      $d/src.f90
  perl -0pi -e "s/d1 = 0\.3847d\+0/d1 = ${D1}d+0/"      $d/src.f90
  for e in "$@"; do perl -0pi -e "$e" $d/src.f90; done
  ( cd $d && gfortran -O3 -march=native -o solver src.f90 2>build.log \
       && ./solver > fort.6 2>&1; echo $? > exit.code )
}

build bm &
build mp            's/mean_preserving = \.false\./mean_preserving = .true./' &
build intermediate  's/constant_vol = \.false\./constant_vol = .true./' &
build basic         's/constant_vol = \.false\./constant_vol = .true./' \
                    's/p_num=7, p_vol_num=5/p_num=1, p_vol_num=1/' &
build basic_matched 's/constant_vol = \.false\./constant_vol = .true./' \
                    's/p_num=7, p_vol_num=5/p_num=1, p_vol_num=1/' \
                    's/p_grid = mean_p \+ 0\.5d\+0\*mean_innov_var\/\(1d\+0 - rho_p\*\*\(2d\+0\)\)/p_grid = 0.288107d+0/' &
wait

for d in bm mp intermediate basic basic_matched; do
  n=$(grep -c '\*\*\*' $OUT/$d/graphs_data_sim_dss.txt 2>/dev/null || echo 0)
  [ "$n" -gt 0 ] 2>/dev/null && perl -i -pe 's/\*{3,}/NaN/g' $OUT/$d/graphs_data_sim_dss.txt
  printf "%-15s exit=%s overflow=%s\n" $d "$(cat $OUT/$d/exit.code)" "$n"
done

echo "=== moments (sim_prod_oil_dec29 convention) ==="
python3 analysis/moments_fast.py $OUT/bm $OUT/mp $OUT/intermediate $OUT/basic $OUT/basic_matched
echo "=== welfare ==="
( cd $OUT && python3 ../analysis/welfare_raw.py bm 7 5 intermediate basic basic_matched )
