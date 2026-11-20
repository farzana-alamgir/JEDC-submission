"""Newton step on (beta, d1) to hit spread 4.10 / debt 34.0.

Jacobian measured at the adopted sigma=0.30 common-grid point by finite
differences (beta +0.005, d1 +0.03) from the base calibration:

    d spread / d beta = -217.50      d spread / d d1 =   -6.123
    d debt   / d beta = -867.62      d debt   / d d1 =  223.98

Checked against the realised step to the adopted point: predicted d spread
+0.886 against +0.967 actual (9% low), predicted d debt +2.39 against +1.65
(45% high). So one step lands close and a second is usually needed on debt.
The caller verifies and re-steps; this only proposes.
"""
import sys

JSB, JSD = -217.50, -6.123
JDB, JDD = -867.62, 223.98
DET = JSB*JDD - JSD*JDB
T_SPREAD, T_DEBT = 4.10, 34.0


def step(beta, d1, spread, debt):
    rs, rd = spread - T_SPREAD, debt - T_DEBT
    db  = (-rs*JDD + JSD*rd) / DET
    dd1 = (-JSB*rd + JDB*rs) / DET
    return beta + db, d1 + dd1


if __name__ == '__main__':
    b, d, s, q = (float(x) for x in sys.argv[1:5])
    nb, nd = step(b, d, s, q)
    print('%.6f %.6f' % (nb, nd))
