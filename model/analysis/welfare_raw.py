"""Consumption-equivalent welfare straight from a run directory's text dumps.

Avoids staging each run through the MATLAB figures pipeline, which is the slow
step in an elasticity sweep. Validated against welfare_matched.m.

Layout (from oil_prod_CES.f90):
  graphs_v_dss.txt      one line per (i_p_vol, i_p, i_y, i_b), i_b innermost,
                        three columns: v_matrix, v0_matrix, v1_matrix
  graphs_pdf_p.txt      one line per (i_p_vol, i_p), i_p innermost,
                        two columns: prob_vector_p, exp_p
  graphs_pdf_p_vol.txt  one line per i_p_vol
  graphs_output_dss.txt same shape as graphs_v_dss.txt (used for the
                        CES-feasibility mask)
"""
import sys, os

B_NUM, Y_NUM = 100, 21
IB_WELFARE = 44          # mean debt index, as in welfare.m
SIGMA = 2.0              # CRRA
FEAS_MAX = 1e3           # output above this means the node is infeasible


def load(run, p_num, p_vol_num):
    def col0(fn, n=None):
        out = []
        with open(os.path.join(run, fn)) as f:
            for line in f:
                w = line.split()
                if w:
                    out.append([float(x) for x in w])
        return out

    v = col0('graphs_v_dss.txt')
    o = col0('graphs_output_dss.txt')
    pdf_p = col0('graphs_pdf_p.txt')
    pdf_v = col0('graphs_pdf_p_vol.txt')
    exp_n = B_NUM * Y_NUM * p_num * p_vol_num
    if len(v) != exp_n:
        raise SystemExit(f'{run}: v has {len(v)} rows, expected {exp_n}')

    def idx(ib, iy, ip, iv):
        return ((iv * p_num + ip) * Y_NUM + iy) * B_NUM + ib

    # feasibility mask over (ip, iv): max output across all (ib, iy)
    feas = {}
    for iv in range(p_vol_num):
        for ip in range(p_num):
            m = max(o[idx(ib, iy, ip, iv)][0]
                    for iy in range(Y_NUM) for ib in range(B_NUM))
            feas[(ip, iv)] = m < FEAS_MAX

    # ergodic-weighted value at mean debt, for each output state
    V = []
    for iy in range(Y_NUM):
        acc = wtot = 0.0
        for iv in range(p_vol_num):
            inner = w = 0.0
            for ip in range(p_num):
                if not feas[(ip, iv)]:
                    continue
                ww = pdf_p[iv * p_num + ip][0]
                inner += ww * v[idx(IB_WELFARE - 1, iy, ip, iv)][0]
                w += ww
            acc += inner * pdf_v[iv][0]
            wtot += w * pdf_v[iv][0]
        V.append(acc / wtot)
    n_bad = sum(1 for k in feas if not feas[k])
    return V, n_bad


def cev(Va, Vf):
    """lambda such that the full model with consumption scaled by (1+lambda)
    matches the alternative. Negative => the alternative is worse."""
    r = [a / f for a, f in zip(Va, Vf)]
    e = 1.0 / (1.0 - SIGMA)
    return 100.0 * (sum(x ** e for x in r) / len(r) - 1.0)


if __name__ == '__main__':
    full, p_num, p_vol_num = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
    Vf, nb = load(full, p_num, p_vol_num)
    print(f'{full}: masked {nb} node(s); mean V = {sum(Vf)/len(Vf):.6f}')
    for alt in sys.argv[4:]:
        Va, nb = load(alt, 1, 1) if 'basic' in alt else load(alt, p_num, p_vol_num)
        print(f'  full -> {alt:<34} CEV {cev(Va, Vf):+8.4f}%   '
              f'mean V {sum(Va)/len(Va):.6f}  (masked {nb})')
