"""Controlled policy comparisons on archived solved economies, without re-solving.

No submitted code or archived solutions are changed. Uses NumPy only.
Run with --archive pointing to the scratchpad containing fin and fin2.
Outputs are conditional grid comparisons, NOT statistical causal estimates.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import re

import numpy as np

OUT = Path(__file__).resolve().parents[2] / 'results' / 'claim_tests'


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024*1024), b''):
            h.update(block)
    return h.hexdigest()


def csv_write(path, rows):
    if not rows:
        return
    with path.open('w', newline='') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]))
        w.writeheader()
        w.writerows(rows)


def number(source, name):
    # Parameters are read only from the active top-level parameter block.
    start=re.search(r'(?im)^module\s+param\s*$',source)
    if start is None:
        raise ValueError('Missing Fortran parameter module')
    tail=source[start.end():]
    end=re.search(r'(?im)^\s*contains\s*$',tail)
    block='\n'.join(line.split('!')[0] for line in tail[:end.start()].splitlines())
    match = re.search(r'\b'+name+r'\s*=\s*([-+\d.eEdD]+)', block)
    if match is None:
        raise ValueError('Missing literal parameter '+name)
    return float(match.group(1).lower().replace('d','e'))


def spread(q, coupon, delta, qrf):
    safe = np.where(q > 1e-10, q, np.nan)
    return 10000*((1+coupon/safe-delta)**4-(1+coupon/qrf-delta)**4)


def gross_output(y, p, alpha, scale):
    # Exact interior CES allocation for theta=0.5 in these archived runs.
    a = scale*np.exp(y)
    root_m = alpha*(1-alpha)*np.sqrt(a)/(p-alpha**2)
    return ((1-alpha)*np.sqrt(a)+alpha*root_m)**2


def finite_mean(x, mask):
    vals = np.asarray(x)[mask]
    return float(np.mean(vals)) if vals.size else None


def price_at_debt(schedule, debt, grid):
    """Linear interpolation along the final debt axis, preserving other axes."""
    left=np.clip(np.searchsorted(grid,debt,side='right')-1,0,len(grid)-2)
    weight=(debt-grid[left])/(grid[left+1]-grid[left])
    return ((1-weight)*np.take_along_axis(schedule,left,axis=-1)
            +weight*np.take_along_axis(schedule,left+1,axis=-1))


def load_solution(archive, group, economy, current=False, allow_provisional=False):
    directory = archive/economy if current else archive/group/('run_'+economy)
    source_file = directory/'source.f90' if current else archive/group/('src_'+economy+'.f90')
    source = source_file.read_text()
    assert ('use_moment_matching = .true.' if current else 'use_moment_matching = .false.') in source
    solve_status=(directory/'solve_status.txt').read_text().strip() if current else 'ARCHIVED_VALUE_ONLY_STOP'
    if current and solve_status!='CONVERGED' and not allow_provisional:
        raise RuntimeError('Solver has not converged; use --allow-provisional to inspect, not endorse, its policies')
    assert 'kappa_risk = 0d+0' in source
    assert ('mean_preserving = .true.' in source) == (economy=='mp')
    b = np.loadtxt(directory/'graphs_b_grid_dss.txt')
    y = np.loadtxt(directory/'graphs_y_grid_dss.txt')
    h = np.loadtxt(directory/'graphs_p_vol_grid_dss.txt')
    z = np.loadtxt(directory/'graphs_p_grid_dss.txt',usecols=0).reshape(len(h),-1)
    assert np.max(abs(z-z[0])) < 1e-12, 'Not a common physical price grid'
    z=z[0]
    shape=(len(h),len(z),len(y),len(b))
    records={}
    for key,name in [('choice','graphs_b_next_dss.txt'),('default','graphs_default_dss.txt'),
                     ('q','graphs_q_dss.txt'),('q_paid','graphs_q_paid_dss.txt')]:
        print('Reading',group,economy,name,flush=True)
        records[key]=np.loadtxt(directory/name).reshape(shape)
    choice=records['choice'].astype(np.int64)-1
    assert choice.min()>=0 and choice.max()<len(b)
    default=records['default'] > .5
    continuous='subroutine continuous_debt(n,grid' in source
    if continuous:
        bounds=np.loadtxt(directory/'graphs_bounds_dss.txt',max_rows=1)
        b=np.linspace(bounds[0],bounds[1],len(b))
        repay_bnext=np.loadtxt(directory/'graphs_b0_next_dss.txt',usecols=0).reshape(shape)
        bnext=np.where(default,0,repay_bnext)
        q_at_choice=price_at_debt(records['q'],bnext,b)
    else:
        bnext=b[choice]
        q_at_choice=np.take_along_axis(records['q'],choice,axis=3)
    price_identity=float(np.max(abs(q_at_choice[~default]-records['q_paid'][~default])))
    assert price_identity<1e-9
    print('Reading convergence diagnostics',group,economy,flush=True)
    residuals=np.loadtxt(directory/'graphs_dev_dss.txt')
    value_error=float(residuals[:,0].max())
    price_error=float(residuals[:,1].max())
    last_price_change=residuals[:,1].reshape(shape).copy()
    del residuals
    iterations=int((directory/'graphs_counter.txt').read_text())
    if not current:
        assert iterations<1500 and value_error<.001
    qrf=float((directory/'graphs_q_def_free.txt').open().readline())
    delta=number(source,'delta'); r=number(source,'rstar')
    # rstar is declared on the first line of the parameter block.
    coupon=(r+delta)/(1+r)
    pars={k:number(source,k) for k in ['beta','alpha','theta','d0','d1','scale_y','rho_p','mean_p']}
    assert pars['theta']==.5
    s=np.loadtxt(directory/'graphs_trans_matrix_p_vol.txt').reshape(len(h),len(h))
    p=np.loadtxt(directory/'graphs_trans_matrix_p.txt',usecols=0).reshape(len(h),len(z),len(z))
    expected_p=s@(p@np.exp(z))
    # Independent one-step zero-profit check at every price used in the tests.
    # Hold the final default and borrowing policies fixed; this is a diagnostic,
    # not a new equilibrium. The original solver stopped on value changes only.
    selected=[]
    for factor in [.8,1.,1.2]:
        ip0=int(np.argmin(abs(z-(.12+np.log(factor)))))
        selected.append(ip0)
        for shock in [.05,.10,.20]:
            selected.append(int(np.argmin(abs(z-(z[ip0]+np.log1p(shock))))))
    selected=sorted(set(selected))
    ty=np.loadtxt(directory/'graphs_trans_matrix_y.txt').reshape(len(y),len(y))
    continuous_y='call repayment_hat_weights' in source
    if continuous_y:
        from gaussian_y import repay_payoff_expectations
        assert continuous
        values=np.loadtxt(directory/'graphs_v_dss.txt').reshape(*shape,3)
        vr=values[...,1].copy()
        va=values[:,:,:,0,2].copy()
        del values
        conditional_q=price_at_debt(records['q'],repay_bnext,b)
        pay=(coupon+(1-delta)*conditional_q)*np.exp(-r)
        after_y=repay_payoff_expectations(vr,va,pay,y,number(source,'rho'),number(source,'std_eps'))
        del vr,va,conditional_q
    else:
        pay=(~default)*(coupon+(1-delta)*records['q_paid'])*np.exp(-r)
        after_y=np.einsum('ij,vpjb->vpib',ty,pay,optimize=True)
    after_p=np.empty((len(h),len(selected),len(y),len(b)))
    for v in range(len(h)):
        after_p[v]=(p[v,selected,:]@after_y[v].reshape(len(z),-1)).reshape(len(selected),len(y),len(b))
    refreshed=np.einsum('kl,lpib->kpib',s,after_p,optimize=True)
    del pay,after_y,after_p
    refreshed_paid={}
    schedule_errors={}
    for j,ip in enumerate(selected):
        refreshed_paid[ip]=(price_at_debt(refreshed[:,j],bnext[:,ip],b) if continuous
                            else np.take_along_axis(refreshed[:,j],choice[:,ip],axis=2))
        schedule_errors[ip]=refreshed[:,j]-records['q'][:,ip]
    tested=(z>=.12+np.log(.8))&(z<=.12+np.log(1.5))
    mean_range=np.ptp(expected_p[:,tested],axis=0)
    drift_diagnostic=float(np.max(mean_range/expected_p[len(h)//2,tested]))
    del p
    inputs=[source_file]+[directory/name for name in [
        'graphs_b_grid_dss.txt','graphs_y_grid_dss.txt','graphs_p_grid_dss.txt',
        'graphs_p_vol_grid_dss.txt','graphs_b_next_dss.txt','graphs_default_dss.txt',
        'graphs_q_dss.txt','graphs_q_paid_dss.txt','graphs_dev_dss.txt',
        'graphs_trans_matrix_p.txt','graphs_trans_matrix_p_vol.txt',
        'graphs_trans_matrix_y.txt','graphs_q_def_free.txt','param_calib.txt']]
    if continuous:
        inputs.extend([directory/'graphs_b0_next_dss.txt',directory/'graphs_bounds_dss.txt'])
    if continuous_y:
        inputs.extend([directory/'graphs_v_dss.txt',directory/'y_gaussian_hat_weights.txt'])
    provenance=dict(group=group,economy=economy,directory=str(directory),parameters=pars,
        solve_status=solve_status,continuous_interpolated_debt=continuous,
        continuous_y_cutoff_integration=continuous_y,
        iterations=iterations,value_iteration_change=value_error,
        bond_price_iteration_change=price_error,choice_price_identity_error=price_identity,
        max_expected_price_relative_range_across_volatility=drift_diagnostic,
        bond_price_convergence_warning=bool(price_error>=.001),
        inputs=[dict(path=str(f),sha256=digest(f)) for f in inputs])
    return dict(b=b,y=y,h=h,z=z,choice=choice,bnext=bnext,continuous_debt=continuous,default=default,q=records['q'],
                q_paid=records['q_paid'],qrf=qrf,coupon=coupon,delta=delta,pars=pars,
                expected_p=expected_p,provenance=provenance,
                refreshed_paid=refreshed_paid,schedule_errors=schedule_errors,
                last_price_change=last_price_change)


def analyze(sol, group, economy):
    b,y,z=sol['b'],sol['y'],sol['z']
    pgrid=np.exp(z); pars=sol['pars']
    Y,B=np.meshgrid(y,b,indexing='ij')
    bnext=sol['bnext']
    annual_spread=spread(sol['q_paid'],sol['coupon'],sol['delta'],sol['qrf'])
    summaries=[]; representatives=[]; details=[]; defaults=[]
    for base_factor in [.8,1.,1.2]:
        i0=int(np.argmin(abs(z-(.12+np.log(base_factor)))))
        x0=gross_output(Y,pgrid[i0],pars['alpha'],pars['scale_y'])
        debt_ratio=B/(4*x0)
        domain=(debt_ratio>=.1)&(debt_ratio<=.7)&(abs(Y)<=.15)
        for shock in [.05,.10,.20]:
            i1=int(np.argmin(abs(z-(z[i0]+np.log1p(shock)))))
            dlog=z[i1]-z[i0]
            assert i1>i0
            ref_choice=sol['choice'][2,i0]
            ref_debt=bnext[2,i0]
            for low,high in [(0,4),(1,3)]:
                repay0=(~sol['default'][low,i0])&(~sol['default'][high,i0])
                repay1=(~sol['default'][low,i1])&(~sol['default'][high,i1])
                valid=domain&repay0&repay1
                db0=bnext[high,i0]-bnext[low,i0]
                db1=bnext[high,i1]-bnext[low,i1]
                s_low=annual_spread[low,i1]-annual_spread[low,i0]
                s_high=annual_spread[high,i1]-annual_spread[high,i0]
                # Identical proposed issuance at all four states; mean-vol policy at p0.
                sched={}
                for v in [low,high]:
                    for ip in [i0,i1]:
                        q=(price_at_debt(sol['q'][v,ip],ref_debt,b) if sol['continuous_debt']
                           else np.take_along_axis(sol['q'][v,ip],ref_choice,axis=1))
                        sched[v,ip]=spread(q,sol['coupon'],sol['delta'],sol['qrf'])
                f_low=sched[low,i1]-sched[low,i0]
                f_high=sched[high,i1]-sched[high,i0]
                fresh={}
                for v in [low,high]:
                    fresh[v]=(spread(sol['refreshed_paid'][i1][v],sol['coupon'],sol['delta'],sol['qrf'])
                              -spread(sol['refreshed_paid'][i0][v],sol['coupon'],sol['delta'],sol['qrf']))
                fixed_valid=valid&(~sol['default'][2,i0])
                label=dict(calibration=group,economy=economy,base_price_factor=base_factor,
                    requested_price_increase=shock,p0=float(pgrid[i0]),p1=float(pgrid[i1]),
                    actual_price_increase=float(np.expm1(dlog)),
                    low_vol_state=low+1,high_vol_state=high+1)
                row=dict(**label,domain_states=int(domain.sum()),
                    common_repayment_states=int(valid.sum()),
                    common_repayment_fraction=float(valid.sum()/domain.sum()),
                    mean_price_response_low_bp=finite_mean(s_low,valid),
                    mean_price_response_high_bp=finite_mean(s_high,valid),
                    mean_amplification_high_minus_low_bp=finite_mean(s_high-s_low,valid),
                    one_step_price_check_amplification_bp=finite_mean(fresh[high]-fresh[low],valid),
                    fraction_amplified=finite_mean((s_high-s_low)>1e-6,valid),
                    fixed_issuance_amplification_bp=finite_mean(f_high-f_low,fixed_valid),
                    borrowing_effect_at_p0=finite_mean(db0,domain&repay0),
                    borrowing_effect_at_p1=finite_mean(db1,domain&repay1),
                    fraction_more_debt_at_p0=finite_mean(db0>1e-9,domain&repay0),
                    fraction_more_debt_at_p1=finite_mean(db1>1e-9,domain&repay1),
                    borrowing_price_interaction=finite_mean(
                        (bnext[high,i1]-bnext[high,i0])-(bnext[low,i1]-bnext[low,i0]),valid))
                summaries.append(row)
                defaults.append(dict(**label,
                    low_default_fraction_at_p0=finite_mean(sol['default'][low,i0],domain),
                    high_default_fraction_at_p0=finite_mean(sol['default'][high,i0],domain),
                    low_default_fraction_at_p1=finite_mean(sol['default'][low,i1],domain),
                    high_default_fraction_at_p1=finite_mean(sol['default'][high,i1],domain)))
                # Detailed rows for the primary 10% contrast and extreme vol states.
                if base_factor==1 and shock==.10 and low==0:
                    for iy,ib in zip(*np.where(domain)):
                        details.append(dict(**label,endowment_log=float(y[iy]),
                            current_debt=float(b[ib]),initial_debt_to_annual_output=float(debt_ratio[iy,ib]),
                            common_repayment=bool(valid[iy,ib]),
                            spread_response_low_bp=float(s_low[iy,ib]) if valid[iy,ib] else None,
                            spread_response_high_bp=float(s_high[iy,ib]) if valid[iy,ib] else None,
                            debt_change_high_minus_low_p0=float(db0[iy,ib]) if repay0[iy,ib] else None,
                            debt_change_high_minus_low_p1=float(db1[iy,ib]) if repay1[iy,ib] else None))
                    for y_target in [-.07,0,.07]:
                        iy=int(np.argmin(abs(y-y_target)))
                        for ratio in [.256,.35,.563]:
                            ib=int(np.argmin(abs(debt_ratio[iy]-ratio)))
                            valid_here=bool(valid[iy,ib])
                            reps=dict(**label,endowment_log=float(y[iy]),target_debt_ratio=ratio,
                                actual_debt_ratio=float(debt_ratio[iy,ib]),current_debt=float(b[ib]),
                                common_repayment=valid_here,
                                low_default_p0=bool(sol['default'][low,i0,iy,ib]),
                                high_default_p0=bool(sol['default'][high,i0,iy,ib]),
                                low_default_p1=bool(sol['default'][low,i1,iy,ib]),
                                high_default_p1=bool(sol['default'][high,i1,iy,ib]))
                            for key,array in [('spread_response_low_bp',s_low),('spread_response_high_bp',s_high),
                                    ('fixed_issuance_response_low_bp',f_low),('fixed_issuance_response_high_bp',f_high)]:
                                reps[key]=float(array[iy,ib]) if valid_here else None
                            reps['amplification_ratio']=(float(s_high[iy,ib]/s_low[iy,ib])
                                if valid_here and s_low[iy,ib]>1e-6 else None)
                            reps['one_step_price_check_response_low_bp']=float(fresh[low][iy,ib]) if valid_here else None
                            reps['one_step_price_check_response_high_bp']=float(fresh[high][iy,ib]) if valid_here else None
                            reps['max_last_paid_price_change']=float(max(
                                sol['last_price_change'][v,ip,iy,ib] for v in [low,high] for ip in [i0,i1]))
                            reps['borrowing_high_minus_low_p0']=float(db0[iy,ib]) if repay0[iy,ib] else None
                            reps['borrowing_high_minus_low_p1']=float(db1[iy,ib]) if repay1[iy,ib] else None
                            for v,label_v in [(low,'low'),(high,'high')]:
                                for ip,label_p in [(i0,'p0'),(i1,'p1')]:
                                    ok=not sol['default'][v,ip,iy,ib]
                                    reps[f'next_debt_{label_v}_{label_p}']=float(bnext[v,ip,iy,ib]) if ok else None
                                    reps[f'net_issuance_{label_v}_{label_p}']=(
                                        float(bnext[v,ip,iy,ib]-(1-sol['delta'])*b[ib]) if ok else None)
                            representatives.append(reps)
    return summaries,representatives,details,defaults


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--archive',type=Path)
    parser.add_argument('--current-runs',type=Path)
    parser.add_argument('--allow-provisional',action='store_true')
    parser.add_argument('--output',type=Path)
    args=parser.parse_args()
    if (args.archive is None)==(args.current_runs is None):
        parser.error('Supply exactly one of --archive or --current-runs')
    global OUT
    if args.output is not None:
        OUT=args.output.resolve()
    OUT.mkdir(parents=True,exist_ok=True)
    all_summary=[]; all_reps=[]; all_detail=[]; all_default=[]; provenance=[]
    grid_reference=None
    groups=['current_branch'] if args.current_runs is not None else ['fin2','fin']
    for group in groups:
        for economy in ['bm','mp']:
            sol=load_solution(args.current_runs or args.archive,group,economy,
                              current=args.current_runs is not None,allow_provisional=args.allow_provisional)
            if grid_reference is None:
                grid_reference=[sol[k].copy() for k in ['b','y','z','h']]
            else:
                for k,ref in zip(['b','y','z','h'],grid_reference):
                    assert np.allclose(sol[k],ref,rtol=0,atol=1e-12),k
            summary,reps,detail,defaults=analyze(sol,group,economy)
            all_summary.extend(summary);all_reps.extend(reps);all_detail.extend(detail);all_default.extend(defaults)
            provenance.append(sol['provenance'])
            print('PRIMARY SUMMARY',summary[8],flush=True)
            del sol
    for name,rows in [('summary.csv',all_summary),('representative_states.csv',all_reps),
                      ('state_details.csv',all_detail),('default_transitions.csv',all_default)]:
        csv_write(OUT/name,rows)
    distributions=[]
    for group in groups:
        for economy in ['bm','mp']:
            rows=[r for r in all_detail if r['calibration']==group and r['economy']==economy]
            good=[r for r in rows if r['common_repayment'] and r['spread_response_low_bp']>.1]
            ratios=np.array([r['spread_response_high_bp']/r['spread_response_low_bp'] for r in good])
            debt=np.array([r['debt_change_high_minus_low_p0'] for r in rows
                           if r['debt_change_high_minus_low_p0'] is not None])
            distributions.append(dict(calibration=group,economy=economy,
                ratio_states=len(ratios),minimum_low_response_bp=.1,
                median_amplification_ratio=float(np.median(ratios)),
                ratio_5_percent=float(np.quantile(ratios,.05)),
                ratio_95_percent=float(np.quantile(ratios,.95)),
                fraction_ratio_at_least_3=float(np.mean(ratios>=3)),
                borrowing_states=len(debt),fraction_more_debt=float(np.mean(debt>1e-9)),
                fraction_unchanged_debt=float(np.mean(abs(debt)<1e-9)),
                fraction_less_debt=float(np.mean(debt< -1e-9))))
    csv_write(OUT/'distribution_summary.csv',distributions)
    (OUT/'provenance.json').write_text(json.dumps(provenance,indent=2)+'\n')
    print('Results saved in',OUT,flush=True)


if __name__=='__main__':
    main()
