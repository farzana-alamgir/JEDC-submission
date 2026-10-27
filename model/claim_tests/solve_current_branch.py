"""Prepare/solve isolated copies of the current branch, with auditable controls.

Economic equations and calibration are preserved. The MP copy changes only the
mean_preserving switch. Both use archived policies only as numerical starting
values, recompute their CURRENT transition kernels, and reset iteration counts.
Stopping diagnostics include value/price changes and default/debt policy changes.
"""
import argparse
import difflib
import hashlib
import json
from pathlib import Path
import shutil
import subprocess

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'results/current_branch_claims'
ARCHIVE=Path('/tmp/claude-501/-Users-farzanaalamgir-code-JEDC-submission/b6660bc3-6976-496e-b7a2-4e265f410095/scratchpad/fin2')


def replace_once(text,old,new):
    assert text.count(old)==1,(old,text.count(old))
    return text.replace(old,new,1)


def accelerate(source):
    """Algebraically identical BLAS contractions; only enabled for kappa=0.

    The original default-free triple expectation is a separate reporting bond;
    computing it by three contractions also preserves its state dependence.
    """
    assert 'parameter (kappa_risk = 0d+0)' in source
    marker='contains\n\n\nsubroutine discretize_AR'
    source=replace_once(source,marker,
        'DOUBLE PRECISION :: qdf_a(y_num,p_num,p_vol_num), qdf_b(y_num,p_num,p_vol_num), qdf_expect(y_num,p_num,p_vol_num)\n'
        +marker)
    first='''do ivn = 1, p_vol_num
   do ip = 1, p_num
      acc_by = 0d+0
      acc_y  = 0d+0
      do ipn = 1, p_num
         w = trans_matrix_p(ip, ipn, ivn)
         acc_by = acc_by + w * exp_aux_a(:, :, ipn, ivn)
         acc_y  = acc_y  + w * exc_aux_a(:, ipn, ivn)
      end do
      exp_aux_b(:, :, ip, ivn) = acc_by
      exc_aux_b(:, ip, ivn)    = acc_y
   end do
end do'''
    source=replace_once(source,first,'''do ivn = 1, p_vol_num
   call dgemm('N','T',b_num*y_num,p_num,p_num,1d0,exp_aux_a(1,1,1,ivn), &
       b_num*y_num,trans_matrix_p(1,1,ivn),p_num,0d0,exp_aux_b(1,1,1,ivn),b_num*y_num)
   call dgemm('N','T',y_num,p_num,p_num,1d0,exc_aux_a(1,1,ivn), &
       y_num,trans_matrix_p(1,1,ivn),p_num,0d0,exc_aux_b(1,1,ivn),y_num)
end do''')
    start=source.index('do ivn = 1, p_vol_num\n   sdc_sdf =')
    end=source.index('\n\ndo iv = 1, p_vol_num',start)
    source=source[:start]+'''do ivn = 1, p_vol_num
   call dgemm('N','T',b_num*y_num,p_num,p_num,exp(-rstar),exp_aux_a(1,1,1,ivn), &
       b_num*y_num,trans_matrix_p(1,1,ivn),p_num,0d0,exp_aux_b(1,1,1,ivn),b_num*y_num)
end do'''+source[end:]
    marker='END SUBROUTINE precompute_expectations'
    qdf='''! Same default-free recursion, factored over y', p', h'.
do ivn=1,p_vol_num
   do ipn=1,p_num
      do iy=1,y_num
         qdf_a(iy,ipn,ivn)=0d0
         do iyn=1,y_num
            qdf_a(iy,ipn,ivn)=qdf_a(iy,ipn,ivn)+trans_matrix(iy,iyn) &
                *(coup_const+(1d0-delta)*q_def_free_paid_matrix(iyn,ipn,ivn))
         end do
      end do
   end do
   call dgemm('N','T',y_num,p_num,p_num,exp(-rstar),qdf_a(1,1,ivn), &
       y_num,trans_matrix_p(1,1,ivn),p_num,0d0,qdf_b(1,1,ivn),y_num)
end do
do iv=1,p_vol_num
   qdf_expect(:,:,iv)=0d0
   do ivn=1,p_vol_num
      qdf_expect(:,:,iv)=qdf_expect(:,:,iv)+trans_matrix_p_vol(iv,ivn)*qdf_b(:,:,ivn)
   end do
end do
'''
    source=replace_once(source,marker,qdf+marker)
    # Restrict replacement to this function, not q_fun.
    start=source.index('DOUBLE PRECISION function q_def_free_fun(')
    end=source.index('end function q_def_free_fun',start)
    section=source[start:end]
    section=section.replace('exp_m = 0d+0',
        'q_def_free_fun = qdf_expect(i_y,i_p,i_p_vol)\nreturn\nexp_m = 0d+0',1)
    source=source[:start]+section+source[end:]
    # Repayment maximization evaluates the SAME resources 100 times per state.
    # Evaluate them once, then scan the same debt choices with the same utility.
    # The assertions restrict this shortcut to the branch's gamma=2 calibration.
    assert 'parameter (sigma = 2d+0' in source
    start=source.index('subroutine optimize(index_opt, v_value)')
    end=source.index('end subroutine optimize',start)+len('end subroutine optimize')
    source=source[:start]+'''subroutine optimize(index_opt, v_value)
USE param
integer :: index_opt, index_vector(1)
DOUBLE PRECISION :: v_value, vector(b_num), cs(b_num), tfp_opt, m_opt, x_opt, p_eff_opt, resources_opt
DOUBLE PRECISION, EXTERNAL :: u_fun
if (i_excl_global /= 1) error stop 'Vectorized optimize is repayment-only'
tfp_opt = scale_y*exp(y_initial)
p_eff_opt = p_initial
m_opt = func_m(y_initial,p_eff_opt)
x_opt = ((1-alpha)*tfp_opt**theta+alpha*m_opt**theta)**(1./theta)
resources_opt = x_opt-m_opt*exp(p_eff_opt)
cs = resources_opt-(b_initial*coupon-q_vector*(b_grid-(1d0-delta)*b_initial))
vector = -1d0/max(cs,1d-10)+beta*exp_v_vector
index_vector = maxloc(vector)
v_value = vector(index_vector(1))
index_opt = index_vector(1)
i_b_next = b_num
end subroutine optimize'''+source[end:]
    return source


def prepare(economy, maxiter, tolerance, fast, output_root, warm_runs, relaxation):
    output_root.mkdir(parents=True,exist_ok=True)
    directory=output_root/'raw'/economy
    directory.mkdir(parents=True,exist_ok=False)
    original=(ROOT/'model/oil_prod_CES.f90').read_text()
    source=original
    if economy=='mp':
        source=replace_once(source,'mean_preserving = .false., p_width_sd',
                            'mean_preserving = .true., p_width_sd')
    # These changes affect initialization, stopping and diagnostics only.
    source=replace_once(source,'indicator_external = 0 !IF SET',
                        'indicator_external = 1 !IF SET')
    source=replace_once(source,"        READ(17,*) counter",
                        "        READ(17,*) counter\n        counter = 0")
    tolerance_literal=f'{tolerance:.12e}'.replace('e','d')
    source=replace_once(source,'criteria = 1.0d-3',f'criteria = {tolerance_literal}')
    source=replace_once(source,'INTEGER i_b, i_y,i_p, i_p_vol, i_p_next, i_p_vol_next, i_b_optimal0, i_b_optimal1, i_y_next, i_b_prime',
        'INTEGER i_b, i_y,i_p, i_p_vol, i_p_next, i_p_vol_next, i_b_optimal0, i_b_optimal1, i_y_next, i_b_prime\n'
        'INTEGER :: changes_d, changes_b\n'
        'INTEGER :: old_d(b_num,y_num,p_num,p_vol_num), old_b(b_num,y_num,p_num,p_vol_num)')
    source=replace_once(source,'   counter = counter + 1',
        '   counter = counter + 1\n   old_d = default_decision\n   old_b = b_next_matrix')
    source=replace_once(source,'   WRITE(*, *) counter, deviation, deviation_q',
        '   changes_d = count(default_decision /= old_d)\n'
        '   changes_b = count(b_next_matrix /= old_b)\n'
        '   WRITE(*, *) counter, deviation, deviation_q, changes_d, changes_b\n'
        '   flush(6)\n'
        "   open(711,file='convergence.csv',position='append')\n"
        "   write(711,'(I0,2(A,ES24.16),2(A,I0))') counter,',',deviation,',',deviation_q,',',changes_d,',',changes_b\n"
        '   close(711)')
    source=replace_once(source,'   if (deviation < criteria .or. counter > 1499) then',
        f'   if ((deviation < criteria .and. deviation_q < criteria .and. changes_d == 0 .and. changes_b == 0) .or. counter >= {maxiter}) then\n'
        "      open(712,file='solve_status.txt')\n"
        '      if (deviation < criteria .and. deviation_q < criteria .and. changes_d == 0 .and. changes_b == 0) then\n'
        "         write(712,*) 'CONVERGED'\n"
        '      else\n'
        "         write(712,*) 'NOT_CONVERGED_ITERATION_LIMIT'\n"
        '      end if\n      close(712)')
    source=replace_once(source,'call simulate\n','! Deterministic policy tests do not require simulation.\n')
    if fast:
        source=accelerate(source)
    if relaxation<1:
        literal=f'{relaxation:.12e}'.replace('e','d')
        marker='contains\n\n\nsubroutine discretize_AR'
        source=replace_once(source,marker,
            'DOUBLE PRECISION :: q_schedule_old(b_num,y_num,p_num,p_vol_num), raw_schedule_residual\n'
            +marker)
        source=replace_once(source,'      open (19, FILE=\'graphs_q_def_free_dss.txt\')',
            '      open (19, FILE=\'graphs_q_def_free_dss.txt\')\n'
            '      open (713, FILE=\'graphs_q_dss.txt\')')
        source=replace_once(source,'               READ(14, *) q_paid_matrix(i_b, i_y,i_p, i_p_vol)',
            '               READ(14, *) q_paid_matrix(i_b, i_y,i_p, i_p_vol)\n'
            '               READ(713, *) q_schedule_old(i_b,i_y,i_p,i_p_vol)')
        source=replace_once(source,'   CLOSE(19)\n\n\nend if',
                            '   CLOSE(19)\n   close(713)\n\n\nend if')
        marker='END SUBROUTINE precompute_expectations'
        source=replace_once(source,marker,
            '! Relax the price schedule only; raw_schedule_residual tests the UNDAMPED pricing equation.\n'
            'raw_schedule_residual=maxval(abs(q_fun_matrix-q_schedule_old))\n'
            f'q_fun_matrix=(1d0-{literal})*q_schedule_old+{literal}*q_fun_matrix\n'
            'q_schedule_old=q_fun_matrix\n'+marker)
        condition='deviation < criteria .and. deviation_q < criteria .and. changes_d == 0 .and. changes_b == 0'
        source=source.replace(condition,condition+' .and. raw_schedule_residual < criteria')
        source=replace_once(source,"   close(711)",
            "   close(711)\n   open(714,file='pricing_residual.csv',position='append')\n"
            "   write(714,'(I0,A,ES24.16)') counter,',',raw_schedule_residual\n   close(714)")
    # The first main-program warm-start read loads the complete policy arrays.
    seeds=['graphs_v_dss.txt','graphs_q_paid_dss.txt','graphs_b_next_dss.txt',
           'graphs_counter.txt','graphs_q_def_free_dss.txt']
    warm_directory=warm_runs/economy if warm_runs else ARCHIVE/('run_'+economy)
    if relaxation<1:
        seeds.append('graphs_q_dss.txt')
    for name in seeds:
        shutil.copyfile(warm_directory/name,directory/name)
    (directory/'source.f90').write_text(source)
    (directory/'convergence.csv').write_text('iteration,value_change,paid_price_change,default_changes,debt_choice_changes\n')
    diff=''.join(difflib.unified_diff(original.splitlines(True),source.splitlines(True),
                                    fromfile='current_branch',tofile=economy+'_instrumented'))
    (output_root/(economy+'_instrumentation.diff')).write_text(diff)
    (output_root/'branch_source.f90').write_text(original)
    manifest=dict(economy=economy,source_sha256=hashlib.sha256(original.encode()).hexdigest(),
        commit=subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
        tolerance=tolerance,max_iterations=maxiter,warm_start=str(warm_directory),
        price_update_relaxation=relaxation,
        changed_equations=False,mean_preserving=(economy=='mp'),
        algebraic_blas_acceleration=fast,
        compiler_flags=['-O3','-march=native','-ffree-line-length-none']+(['-framework','Accelerate'] if fast else []))
    (output_root/(economy+'_manifest.json')).write_text(json.dumps(manifest,indent=2)+'\n')
    subprocess.run(['gfortran',*manifest['compiler_flags'],'source.f90','-o','solve'],cwd=directory,check=True)
    return directory


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('economy',choices=['bm','mp'])
    p.add_argument('--max-iterations',type=int,default=160)
    p.add_argument('--tolerance',type=float,default=1e-6)
    p.add_argument('--blas',action='store_true')
    p.add_argument('--output-root',type=Path,default=OUT)
    p.add_argument('--warm-runs',type=Path)
    p.add_argument('--price-relaxation',type=float,default=1.)
    args=p.parse_args()
    assert 0<args.price_relaxation<=1
    directory=prepare(args.economy,args.max_iterations,args.tolerance,args.blas,
                      args.output_root.resolve(),args.warm_runs.resolve() if args.warm_runs else None,
                      args.price_relaxation)
    print('Prepared',directory,flush=True)
    with (directory/'run.log').open('w') as log:
        result=subprocess.run([str(directory/'solve')],cwd=directory,stdout=log,stderr=subprocess.STDOUT)
    print('Solver exit',result.returncode,flush=True)
    print((directory/'solve_status.txt').read_text() if (directory/'solve_status.txt').exists()
          else 'No completion status; inspect run.log',flush=True)


if __name__=='__main__':
    main()
