#!/bin/bash
# Solve all six economies at the VALUE-ADDED default cost calibration.
#
#   alpha 0.000307   theta -2.33333333 (sigma_oil = 0.30)
#   beta  0.972      d0 -0.246   d1 0.46   va_default_cost = .true.
#
# Usage: ./solve_va_final.sh [outdir]
set -u
cd "$(dirname "$0")"
OUT="${1:-runs_va_final}"
A=0.000307; T=-2.33333333; B=0.972; D0=-0.246; D1=0.46
rm -rf $OUT; mkdir -p $OUT

build () {
  local d=$OUT/$1; shift; mkdir -p $d; cp oil_prod_CES.f90 $d/src.f90
  perl -i -pe "s/alpha=0\.3d\+0/alpha=${A}d+0/"                                   $d/src.f90
  perl -i -pe "s/theta=0\.5d\+0/theta=${T}d+0/"                                   $d/src.f90
  perl -i -pe "s/beta=0\.96d\+0/beta=${B}d+0/"                                    $d/src.f90
  perl -i -pe "s/d0 = -0\.246d\+0/d0 = ${D0}d+0/"                                 $d/src.f90
  perl -i -pe "s/d1 = 0\.3847d\+0/d1 = ${D1}d+0/"                                 $d/src.f90
  # target the PARAMETER statement, not the first textual match (a comment)
  perl -i -pe 's/parameter \(va_default_cost = \.false\.\)/parameter (va_default_cost = .true.)/' $d/src.f90
  for e in "$@"; do perl -0pi -e "$e" $d/src.f90; done
  ( cd $d && gfortran -O3 -march=native -o solver src.f90 2>build.log \
       && ./solver > fort.6 2>&1; echo $? > exit.code )
}

# mean_p shift for intermediate_matched: its simulated E[p] is 1.3562 against
# the benchmark's 1.3339, and the price process is unchanged by the default
# cost, so the same shift as the endowment-cost calibration applies.
build bm &
build mp                  's/mean_preserving = \.false\./mean_preserving = .true./' &
build intermediate        's/constant_vol = \.false\./constant_vol = .true./' &
build intermediate_matched 's/constant_vol = \.false\./constant_vol = .true./' \
                           's/mean_p = 0\.12d\+0/mean_p = 0.10342d+0/' &
wait
build basic               's/constant_vol = \.false\./constant_vol = .true./' \
                          's/p_num=7, p_vol_num=5/p_num=1, p_vol_num=1/' &
build basic_matched       's/constant_vol = \.false\./constant_vol = .true./' \
                          's/p_num=7, p_vol_num=5/p_num=1, p_vol_num=1/' \
                          's/p_grid = mean_p \+ 0\.5d\+0\*mean_innov_var\/\(1d\+0 - rho_p\*\*\(2d\+0\)\)/p_grid = 0.288107d+0/' &
wait

for d in bm mp intermediate intermediate_matched basic basic_matched; do
  n=$(grep -c '\*\*\*' $OUT/$d/graphs_data_sim_dss.txt 2>/dev/null || echo 0)
  if [ "${n:-0}" -gt 0 ] 2>/dev/null; then perl -i -pe 's/\*{3,}/NaN/g' $OUT/$d/graphs_data_sim_dss.txt; fi
  printf "%-22s exit=%s overflow=%s va=%s\n" $d "$(cat $OUT/$d/exit.code 2>/dev/null)" "${n:-0}" \
    "$(grep -oE 'parameter \(va_default_cost = \.[a-z]+' $OUT/$d/src.f90 | grep -oE '\.[a-z]+$')"
done
echo "=== moments ==="
python3 analysis/moments_fast.py $OUT/bm $OUT/mp $OUT/intermediate $OUT/intermediate_matched $OUT/basic $OUT/basic_matched
echo "=== welfare ==="
( cd $OUT && python3 ../analysis/welfare_raw.py bm 7 5 intermediate intermediate_matched basic basic_matched )
echo "=== simulated mean prices (matched economies must equal bm) ==="
for d in bm intermediate intermediate_matched basic basic_matched; do
  python3 -c "
p=[float(l.split()[13]) for l in open('$OUT/$d/graphs_data_sim_dss.txt')]
print(f'  {\"$d\":<22} E[p] = {sum(p)/len(p):.4f}')"
done
