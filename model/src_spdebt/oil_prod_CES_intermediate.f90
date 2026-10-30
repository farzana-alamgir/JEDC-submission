!**************************************************************************************************

!cd /Users/farzanaalamgir/code/JEDC_submission/model

! gfortran -O3 -march=native oil_prod_CES.f90 -o oil_prod_CES
!
! ./oil_prod_CES
!INCLUDE 'link_fnl_static.h'

MODULE shared_types

	IMPLICIT NONE

    INTEGER, PARAMETER :: data_type = selected_real_kind(p = 8, r = 30) ! double precision

END MODULE shared_types
module param
DOUBLE PRECISION :: beta, sigma, b_inf, b_sup, y_inf, y_sup, std_eps,mmax_global, &
     rho, mean_y, std_y, pi_number, zero, width, prob_excl_end, alpha,theta, &
     rstar, coupon, delta, m, scale_y, d0, d1,pprime, &
     p_vol_inf, p_vol_sup, std_u_p, std_u_vol, rho_p, rho_p_vol, mean_p, mean_p_vol, std_p_vol,eta

parameter (sigma = 2d+0, pi_number = 3.1415926535897932d+0, zero = 0d+0,  width = 1.5d+0,  rstar = 0.01d+0,  &
     prob_excl_end =0.0833d+0, std_eps = 0.03d+0, rho = 0.9d+0, beta=0.9746d+0, alpha=0.000307d+0, theta=-2.33333333d+0,&          !A-m has been changed in order to capture the new specification of stealing function
     mean_y = -0.5d+0*std_eps**2,delta = 0.03d+0,  m=4d+0, scale_y=10d+0, d0 = -0.246d+0, d1 = 0.4731d+0, mmax_global=100d+0,&
     std_u_p = 1d+0, std_u_vol= 1d+0, rho_p = 0.98d+0, rho_p_vol = 0.66d+0 ,pprime=3.97d+0,mean_p = 0.12d+0, mean_p_vol = -4.33d+0, eta = 0.44d+0)

!---------------------------------------------------------------------
! Price-grid discretization switch.
!
! .false. reproduces the submitted behaviour: discretize_AR builds a SEPARATE
!         Rouwenhorst grid per volatility state, whose half-width scales with
!         exp(sigma_t). A volatility shock then rescales the price LEVEL, and
!         the same price index means a different physical price in different
!         volatility states. See REVISION_NOTES section 3.1.
! .true.  uses ONE physical log-price grid shared by every volatility state,
!         with volatility entering only the transition kernel via tauchen_fixed.
!         This is the process the paper actually specifies.
!
! p_width_sd is the grid half-width in unconditional SDs of log price. The
! usable range interacts with the CES elasticity: an interior oil optimum needs
! the lowest grid price above alpha**(1/theta) when theta > 0. See
! oil_price_validation/elasticity_sweep.py, column max_price_half_width_sd.
!---------------------------------------------------------------------
!---------------------------------------------------------------------
! VOLATILITY CONVENTION. The stochvol package parameterises
!     y_t = exp(h_t/2) * eps_t,
! so h is the log VARIANCE and the conditional STANDARD DEVIATION is
! exp(h/2). The submitted code used exp(h) as the standard deviation,
! which at mean_p_vol = -4.33d+0 gives 1.32% per quarter against 11.47% under
! exp(h/2). The real oil price in empirical/oil_qtrly.xlsx has a quarterly
! log-change standard deviation of 14.47% over 1995-2019, so exp(h) makes
! the model's oil price about 8x too smooth and its most volatile state
! still 3x below the data's average. Every aggregate below is therefore
! E[exp(h)] = exp(mu_h + var_h/2), not E[exp(2h)] = exp(2*mu_h + 2*var_h).
!---------------------------------------------------------------------
LOGICAL :: use_common_p_grid, mean_preserving, use_moment_matching, constant_vol
DOUBLE PRECISION :: p_width_sd, p_vol_width_sd
parameter (use_moment_matching = .false.)
parameter (constant_vol = .true.)
!---------------------------------------------------------------------
! R2 major comment 3. In the submitted model a country in default keeps
! importing oil at the world price with no friction; the only direct cost of
! default is the endowment loss. The referee notes that the motivating example
! (Sri Lanka's difficulty paying for fuel imports ahead of its 2022 default)
! and the cited literature (Mendoza and Yue 2012, where losing imported inputs
! is precisely what makes default costly) both suggest oil access should be
! disrupted in default.
!
! Modelled as a proportional premium on the imported oil price while the
! country is in default or excluded: p_eff = p * (1 + oil_disruption). The
! country still optimises its oil demand, it just faces a worse price, so the
! CES first-order condition and func_m are unchanged. oil_disruption = 0
! reproduces the submitted model exactly.
!---------------------------------------------------------------------
DOUBLE PRECISION :: oil_disruption
parameter (oil_disruption = 0d+0)
!---------------------------------------------------------------------
! R1 major comment 5: risk-averse lenders.
!
! The submitted model prices with a constant SDF, m = exp(-rstar), so the
! spread is pure expected loss and carries no risk premium. Here the kernel
! loads on the innovation to the log oil price, which is the global state in
! this model and the one default is tied to:
!
!   log m' = -rstar - kappa_risk * eps' - 0.5 * kappa_risk^2 * Var(eps')
!   eps'   = log p' - [(1-rho_p)*mean_p + rho_p*log p]
!
! kappa_risk > 0 makes the SDF HIGH when oil is expensive. Default happens
! when oil is expensive, so losing the payoff in those states is costly in
! present-value terms and lenders demand a premium. (An earlier version had
! this sign backwards: an SDF that is LOW in default states makes EXCLUDING
! them raise the bond price, which drove the spread negative.)
!
!   log m' = -rstar + kappa_risk*(log p' - mean_p) - 0.5*kappa_risk^2*V
!   V      = Var(log p) unconditionally, so E[m'] = exp(-rstar)
!
! The price of risk is on the oil price LEVEL, not the innovation. A level
! kernel depends only on p', so it folds into the payoff before the
! contraction over (y', p', sigma') and the factorisation is preserved. An
! innovation kernel depends on the current price too and would not factorise.
! kappa_risk = 0 reproduces the submitted model exactly.
!---------------------------------------------------------------------
DOUBLE PRECISION :: kappa_risk
parameter (kappa_risk = 0d+0)
parameter (use_common_p_grid = .true., mean_preserving = .false., p_width_sd = 3.5d+0, p_vol_width_sd = 2d+0)

! Memo cache for func_m (see the comment in that function).
DOUBLE PRECISION :: m_cache_y, m_cache_p, m_cache_val
INTEGER :: m_cache_excl
LOGICAL :: m_cache_valid = .false.
!---------------------------------------------------------------------
! VALUE-ADDED DEFAULT COST.
!
! The submitted penalty, max(0, d0*yt + d1*yt**2) with yt = EXP(y), is a
! function of the ENDOWMENT alone, so the oil price never enters the default
! decision except through the consumption level common to both branches. With
! rho_p = 0.98 an oil price shock is very nearly permanent and shifts the
! value of repaying and of defaulting by almost the same amount, so the
! default margin barely moves. That is the quantitative reason every oil
! channel comes out small -- see results/WHY_OPPOSITE.md.
!
! With va_default_cost = .true. the penalty is instead a function of VALUE
! ADDED, output net of the oil bill, which shrinks when oil is expensive. A
! higher oil price then LOWERS the absolute cost of defaulting, making default
! relatively more attractive exactly when the importer is squeezed, so the
! spread should respond more strongly rather than less.
!
! Value added is evaluated at the NO-DEFAULT TFP, which does not depend on the
! penalty. That is what makes this a two-pass calculation rather than a fixed
! point, and it matches how default costs are normally described: a share of
! the output the country would otherwise have produced. It is normalised by
! scale_y so it is O(1) like EXP(y), and va_default_cost = .false. reproduces
! the submitted model exactly.
!---------------------------------------------------------------------
LOGICAL :: va_default_cost
parameter (va_default_cost = .true.)
DOUBLE PRECISION :: va_cache_y, va_cache_p, va_cache_val
LOGICAL :: va_cache_valid = .false.

CHARACTER(LEN = 10) :: outFormat

! parameter (sigma = 2d+0, pi_number = 3.1415926535897932d+0, zero = 0d+0,  width = 1.5d+0,  rstar = 0.01d+0, kappa=0, epsilon = 5.2d+0, &
!      prob_excl_end =0.0385d+0, std_eps = 0.03d+0, rho = 0.9d+0, beta = 0.97d+0, tax_rate=1d+0, gamma = 1.06d+0, monitoring = 2.64d+0, A_m=0,theta = 0.01d+0,&             !A-m has been changed in order to capture the new specification of stealing function
!      mean_y = -0.5d+0*std_eps**2,delta = 0.07d+0, cost=0.92d+0, m=4d+0, monitoring_in_bc=0, scale_y=10d+0, d0 = -0.15d+0, d1 = 0.25d+0,&
!      std_u_p = 1d+0, std_u_vol= 1d+0, rho_p = 0.98d+0, rho_p_vol = 0.66d+0, mean_p = 0.12d+0, mean_p_vol = -4.33d+0, eta = 0.49d+0)


INTEGER :: b_num, y_num, quad_num, nout, i_y_global, i_excl_global, p_num, p_vol_num,&
     i_b_global, i_default_global, indicator_2, i_b_next, i_b_zero, b_num_interm, counter


parameter (b_num= 100, y_num = 21, p_num=277, p_vol_num=5)
! parameter (b_num= 200, y_num = 50)

DOUBLE PRECISION :: b_grid(1:b_num), y_grid(1:y_num), default_grid(1:2), &
     std_p(1:p_vol_num),p_grid(p_num,p_vol_num),p_vol_grid (1:p_vol_num), &
     matrix_v_global(b_num, y_num, p_num, p_vol_num),vector_v_global(y_num, p_num, p_vol_num),y_initial, b_initial, &
     p_initial, p_vol_initial, v1_matrix(y_num, p_num, p_vol_num), exp_v_vector(b_num),q_vector(b_num),&
     exp_v_excl_vector(b_num), b_global, y_global,p_global, p_vol_global, q_nodef(y_num, p_num, p_vol_num), m1(y_num,p_num,p_vol_num), &
     expected_SDF_matrix(y_num, p_num, p_vol_num), variance_p_level_epsilon_tomorrow(p_vol_num), TFP1(y_num, p_num, p_vol_num),&
     p_grid_1(p_num,p_vol_num), p_grid_2(p_num,p_vol_num), p_grid_3(p_num,p_vol_num), p_grid_4(p_num,p_vol_num), p_grid_5(p_num,p_vol_num)

DOUBLE PRECISION, DIMENSION(b_num, y_num,p_num, p_vol_num ) :: v_matrix
INTEGER, DIMENSION(b_num, y_num, p_num, p_vol_num) :: default_decision, b_next_matrix, b0_next_matrix_indice
DOUBLE PRECISION, DIMENSION(b_num, y_num, p_num, p_vol_num) :: v0_matrix, b0_next_matrix, b1_next_matrix, q_paid_matrix, &
c_matrix, TFP_matrix, output_matrix, oil_matrix, TFP0, m0
DOUBLE PRECISION, DIMENSION(p_vol_num, p_vol_num) :: trans_matrix_p_vol, cdf_matrix_p_vol, trans_matrix_p_vol_AR
DOUBLE PRECISION, DIMENSION(y_num, y_num) :: trans_matrix, cdf_matrix
DOUBLE PRECISION, DIMENSION(p_num, p_num, p_vol_num) :: trans_matrix_p_AR,trans_matrix_p, cdf_matrix_p, trans_matrix_p_1, trans_matrix_p_2, trans_matrix_p_3, trans_matrix_p_4, trans_matrix_p_5
DOUBLE PRECISION, DIMENSION(p_num, p_vol_num) :: sdf_norm

DOUBLE PRECISION, DIMENSION (y_num, p_num, p_vol_num) :: q_def_free_paid_matrix

! Autarky (default-state) allocations. Promoted from locals of `iterate` to module
! scope so that `simulate` can read them during exclusion periods, when the country
! is in autarky and c_matrix/oil_matrix/output_matrix do not describe its allocation.
DOUBLE PRECISION, DIMENSION (y_num, p_num, p_vol_num) :: c1_matrix, output1_matrix, &
                                                         oil1_matrix, TFP1_matrix

! Precomputed conditional expectations of the value functions, and the two
! intermediate contractions used to build them. See precompute_expectations.
DOUBLE PRECISION, DIMENSION(b_num, y_num, p_num, p_vol_num) :: exp_v_matrix, exp_aux_a, exp_aux_b
DOUBLE PRECISION, DIMENSION(b_num, y_num, p_num, p_vol_num) :: q_fun_matrix, q_src
DOUBLE PRECISION, DIMENSION(y_num, p_num, p_vol_num) :: exp_v_excl_matrix, exc_aux_a, exc_aux_b

contains


subroutine discretize_AR(rho_ar, mu, sigma_eps, z, pi, w)
  implicit none


             !##### INPUT/OUTPUT VARIABLES #############################################

             ! autoregression parameter
             real*8, intent(in) :: rho_ar

             ! unconditional mean of the process
             real*8, intent(in) :: mu

             ! variance of the shock
             real*8, intent(in) :: sigma_eps

             ! discrete shock values
             real*8, intent(out) :: z(:)

             ! transition matrix
             real*8, intent(out) :: pi(:, :)

             ! the stationary distribution
             real*8, intent(out), optional :: w(:)


             !##### OTHER VARIABLES ####################################################

             integer :: n, in
             real*8 :: psi, sigma_eta


             !##### ROUTINE CODE #######################################################

             ! assert size equality and get approximation points
             ! n = assert_eq(size(z), size(pi,1), size(pi,2), 'discretize_AR') !-- This is the line in the CE-fortran toolbox
             n = size(z)

             ! calculate variance of the overall process
             sigma_eta = sigma_eps/(1d0-rho_ar**2d+0)

             ! determine the transition matrix
             call rouwenhorst_matrix(rho_ar, pi)

             ! determine the nodes
             psi = sqrt(dble(n-1))*sqrt(sigma_eta)
             do in = 1, n
                 z(in) = -psi + 2d0*psi*dble(in-1)/dble(n-1)
             enddo
             z = z + mu

             if(present(w))then
                 w = 1d0/dble(n)
                 do in = 1, 10000
                     w = matmul(transpose(pi), w)
                 enddo
             endif

             !##########################################################################
             ! Subroutines and functions
             !##########################################################################

             contains


             !##########################################################################
             ! subroutine rouwenhorst_matrix
             !
             ! Calculates value of function that should be integrated for pis.
             !##########################################################################
             recursive subroutine rouwenhorst_matrix(rho_ar, pi_new)

                 implicit none
                 real*8, intent(in) :: rho_ar
                 real*8, intent(out) :: pi_new(:, :)
                 integer :: n
                 real*8 :: p, pi_old(size(pi_new,1)-1, size(pi_new,1)-1)

                 n = size(pi_new, 1)
                 p = (1d0 + rho_ar)/2d0

                 if(n == 2)then
                     pi_new(1, :) = (/p, 1d0-p/)
                     pi_new(2, :) = (/1d0-p, p/)
                 else
                     call rouwenhorst_matrix(rho_ar, pi_old)
                     pi_new = 0d0

                     pi_new(1:n-1, 1:n-1) = pi_new(1:n-1, 1:n-1) + p*pi_old
                     pi_new(1:n-1, 2:n  ) = pi_new(1:n-1, 2:n  ) + (1d0-p)*pi_old
                     pi_new(2:n  , 1:n-1) = pi_new(2:n  , 1:n-1) + (1d0-p)*pi_old
                     pi_new(2:n  , 2:n  ) = pi_new(2:n  , 2:n  ) + p*pi_old

                     pi_new(2:n-1, :) = pi_new(2:n-1, :)/2d0
                 endif
             end subroutine

  end subroutine discretize_AR

SUBROUTINE tauchen(n,rho,mu_z,var_e,m,Z,Pi)
!z_{t+1}=(1-rho)*mu_z+rho*z_t+eps_t
!z_{t+1}-mu_z=rho*(z_t-mu_z)+eps_t
!y_{t+1}=rho*y_t+eps_t
!rho: persistence of AR(1) process
!mu_z: Mean of z
!var_e: Variance of epsilon
!n: number of finite states
INTEGER, INTENT(IN) :: n
DOUBLE PRECISION, INTENT(IN) :: rho,mu_z,var_e,m
DOUBLE PRECISION, INTENT(OUT) :: Z(n,1),Pi(n,n)
DOUBLE PRECISION :: Y(n,1),sig_z,h
INTEGER :: i,j
DOUBLE PRECISION :: x,mu,sd,pr
mu=0.
sd=SQRT(var_e)

sig_z=SQRT(var_e/(1.-(rho**2.)))

	DO i=1,n
	Y(i,1)=-m*sig_z+2.*m*sig_z*((i-1.)/(n-1.))**1.
	Z(i,1)=Y(i,1)+mu_z
	END DO

	DO i=1,n
! Left end point
	h=Y(2,1)-Y(1,1)
	x=Y(1,1)+h/2.-rho*Y(i,1)
	CALL Ncdf(x,mu,sd,pr)
	Pi(i,1)=pr

      x=Y(1,1)-rho*Y(i,1)-h/2
 	CALL Ncdf(x,mu,sd,pr)
 	pi(i,1)=pi(i,1)-pr
!Right end point
        h=Y(n,1)-Y(n-1,1)
	x=Y(n,1)+h/2.-rho*Y(i,1)
	CALL Ncdf(x,mu,sd,pr)
	Pi(i,n)=pr

	x=Y(n,1)-h/2.-rho*Y(i,1)
	CALL Ncdf(x,mu,sd,pr)
	pi(i,n)=pi(i,n)-pr




!midpoints
		DO j=2,n-1

		h=Y(j+1,1)-Y(j,1)
		x=Y(j,1)+h/2.-rho*Y(i,1)
		CALL Ncdf(x,mu,sd,pr)
		Pi(i,j)=pr


		h=Y(j,1)-Y(j-1,1)
		x=Y(j,1)-h/2.-rho*Y(i,1)
		CALL Ncdf(x,mu,sd,pr)
		Pi(i,j)=Pi(i,j)-pr

		END DO

	END DO

	do i=1,n
	Pi(i,:)=Pi(i,:)/sum(Pi(i,:))
	end do

END SUBROUTINE tauchen


subroutine d_tauchen(y,pi,rho,sigma,n,cover_tauchen)

    ! use imsl_libraries  ! COMMENTED OUT - IMSL library not needed
    use shared_types
    !use shared_data

	implicit none

	integer, intent(in) :: n

	real(data_type), intent(in) :: rho, sigma, cover_tauchen
	real(data_type), dimension (n,n), intent(out) :: pi
	real(data_type), dimension (n), intent(out) :: y

	integer :: yc, tc, tcc

	real(data_type) :: sigy, mu, upp, low

	! Define the discrete states of the Markov chain
	! variance of shock
	sigy = sigma/sqrt(1.0-rho**2)

	! set upper bound and lower bound of shocks
	y(n) = cover_tauchen*sigy !%(sqrt(n)/sqrt(2.0))*sigy ! good for 0.007, increase later
	y(1) = -y(n)

	do yc = 2, n-1

		y(yc) = y(1)+(y(n)-y(1))*(yc-1.0)/(n-1.0)

	end do

	! Compute the transition matrix

	do tc = 1,n

		mu = rho*y(tc)
		upp = (y(2)+y(1))/2.0
		upp = (upp-mu)/sigma
		pi(tc,1) = D_ANORDF(upp)
		low = (y(n)+y(n-1))/2.0
		low = (low-mu)/sigma
		pi(tc,n) = 1.0-D_ANORDF(low)

		do tcc = 2, n-1

			low = (y(tcc-1)+y(tcc))/2.0
			upp = (y(tcc+1)+y(tcc))/2.0
			low = (low-mu)/sigma
			upp = (upp-mu)/sigma
			pi(tc,tcc) = D_ANORDF(upp)-D_ANORDF(low)

		end do

	end do

end subroutine d_tauchen

! Function to replace IMSL D_ANORDF - standard normal CDF
function D_ANORDF(z)
    use shared_types
    implicit none
    real(data_type) :: D_ANORDF
    real(data_type), intent(in) :: z
    real(data_type) :: pr

    ! Call the existing Ncdf subroutine with mu=0, sd=1 for standard normal
    call Ncdf(dble(z), 0.0d0, 1.0d0, pr)
    D_ANORDF = real(pr, data_type)
end function D_ANORDF


SUBROUTINE Ncdf(x,mu,sd,pr)
IMPLICIT NONE
DOUBLE PRECISION, INTENT(IN) :: x,mu,sd
DOUBLE PRECISION, INTENT(OUT) :: pr
DOUBLE PRECISION :: z
DOUBLE PRECISION, PARAMETER :: PI=3.141592653589793238462643383279502884197

z=(x-mu)/sd

	IF (z .GT. 0.) THEN
	pr=.5+.5*SQRT(1.-EXP(-SQRT(PI/8.)*(z**2.)))
	ELSE
	pr=.5-.5*SQRT(1.-EXP(-SQRT(PI/8.)*(z**2.)))
	END IF
END SUBROUTINE Ncdf


!=====================================================================
! Accurate standard-normal CDF, for the common-grid price discretization.
!
! The Ncdf routine above is a Polya-type closed-form approximation with
! absolute error of order 3e-3 in probability. That is too coarse to build
! a transition kernel that has to reproduce conditional means and variances,
! so the common-grid path uses ERFC instead. This matches the independently
! validated Python kernel in oil_price_validation/validate.py, which uses
! 0.5*erfc(-t/sqrt(2)).
!=====================================================================
! Probability of a standardized normal falling in [lo, hi].
!
! Evaluated with ERFC on whichever side keeps both terms small, which avoids the
! catastrophic cancellation that `normal_cdf(hi) - normal_cdf(lo)` suffers when
! both CDFs are near 1. Identical in form to normal_cell in
! oil_price_validation/price_kernel.f90, whose output is checked against the
! Python kernel to 1e-12.
DOUBLE PRECISION FUNCTION normal_cell(lo, hi)
IMPLICIT NONE
DOUBLE PRECISION, INTENT(IN) :: lo, hi
DOUBLE PRECISION, PARAMETER :: root2 = 1.41421356237309504880168872420969808d+0
if (lo >= 0d+0) then
   normal_cell = 0.5d+0*(ERFC(lo/root2) - ERFC(hi/root2))
else
   normal_cell = 0.5d+0*(ERFC(-hi/root2) - ERFC(-lo/root2))
end if
normal_cell = max(0d+0, normal_cell)
END FUNCTION normal_cell


!=====================================================================
! Transition matrix for  z' = (1-rho)*mu + rho*z + sd_eps*eps  on a GIVEN grid.
!
! Unlike `tauchen` and `discretize_AR`, the grid is an INPUT, not an output.
! That is the whole point: one physical price grid shared by every volatility
! state, with the volatility entering only through sd_eps. With the grid
! generated per state instead, a change in volatility rescales the price grid
! and therefore the price LEVEL, which is not the process the paper specifies.
!
! Cell edges are midpoints between nodes; the two tails are assigned to the
! boundary nodes, as in validate.py's normal_rows.
!=====================================================================
!=====================================================================
! Exponentially tilt a discrete distribution so it matches a target mean and
! variance EXACTLY, keeping the support fixed.
!
! Why this is needed. Tauchen integrates the normal density over fixed grid
! cells. With rho_p = 0.98 the conditional mean advances by rho of a grid node
! per node, so it slips (1-rho) of a node each step and realigns with the cell
! edges every 1/(1-rho) = 50 nodes. The realised conditional moments therefore
! oscillate: measured on the 549-node grid the conditional mean departs from
! the exact AR(1) law by up to 1.4e-3 (0.7 of a node) and the conditional sd
! wobbles by 1.26%, putting an 11-cycle ripple into the bond price schedule.
!
! That is not merely cosmetic here. The mean-preserving experiment manipulates
! the conditional variance directly, so imposing a drift on a kernel whose own
! variance already wobbles 1.26% makes the experiment exact in intent but not
! in realisation.
!
! Rouwenhorst would match an AR(1) exactly at any rho, but it DETERMINES its
! own grid, and the whole point of this revision is a grid shared across
! volatility states. Tilting fixes the moments on an imposed grid instead.
!
! Solves for (lam1, lam2) in q_j ~ p_j exp(lam1 z_j + lam2 z_j^2) by Newton.
! The Jacobian is the covariance matrix of (z, z^2) under q, hence symmetric
! positive semi-definite, and convergence is quadratic. Returns ok = .false.
! without modifying p when the targets are not attainable on this support --
! which happens near the grid edges, where the conditional mean of the
! underlying process lies outside the grid altogether.
!=====================================================================
SUBROUTINE match_moments(n, z, p, m_target, v_target, ok)
IMPLICIT NONE
INTEGER, INTENT(IN) :: n
DOUBLE PRECISION, INTENT(IN) :: z(n), m_target, v_target
DOUBLE PRECISION, INTENT(INOUT) :: p(n)
LOGICAL, INTENT(OUT) :: ok
DOUBLE PRECISION :: lam1, lam2, u(n), q(n), w(n), wmax, sd
DOUBLE PRECISION :: e1, e2, j11, j12, j22, r1, r2, det, d1, d2, rn, rn_try, step
DOUBLE PRECISION :: lam1_try, lam2_try, e1_try, e2_try
INTEGER :: it, ls
DOUBLE PRECISION, PARAMETER :: tol = 1d-13
INTEGER, PARAMETER :: maxit = 80

ok = .false.
if (m_target <= z(1) .or. m_target >= z(n)) return
if (v_target <= 0d+0) return

! Work in the STANDARDISED variable u = (z - m_target)/sd, matching
! E[u] = 0 and E[u^2] = 1.
!
! The obvious basis (z, z^2) is nearly collinear here: the conditional sd is
! 0.0132 against a grid spanning 1.12, so over the range carrying any mass
! z^2 is almost an affine function of z. The Newton Jacobian is then the
! near-singular covariance matrix of two nearly identical regressors, the
! steps blow up, the iteration exhausts maxit and silently leaves the row at
! plain Tauchen -- which is exactly what happened on the first attempt.
! Standardising makes u and u^2 well separated over the support that matters.
sd = sqrt(v_target)
u  = (z - m_target)/sd

lam1 = 0d+0
lam2 = 0d+0
e1   = 0d+0
e2   = 0d+0
rn   = -1d+0
do it = 1, maxit
   if (rn < 0d+0) then                       ! evaluate at the current lambdas
      w    = lam1*u + lam2*u*u
      wmax = maxval(w)
      q    = p*exp(w - wmax)
      if (sum(q) <= 0d+0) return
      q  = q/sum(q)
      e1 = sum(q*u)
      e2 = sum(q*u*u)
      rn = abs(e1) + abs(e2 - 1d+0)
   end if
   r1 = e1
   r2 = e2 - 1d+0
   if (abs(r1) <= tol .and. abs(r2) <= tol) then
      p  = q
      ok = .true.
      return
   end if
   j11 = e2 - e1*e1
   j12 = sum(q*u*u*u)     - e1*e2
   j22 = sum(q*u*u*u*u)   - e2*e2
   det = j11*j22 - j12*j12
   if (abs(det) < 1d-14) return
   d1 = ( j22*r1 - j12*r2)/det
   d2 = (-j12*r1 + j11*r2)/det
   ! Backtracking: the tilt enters an exponential, so a full Newton step can
   ! collapse all mass onto one node. Accept only a step that reduces the
   ! residual.
   step = 1d+0
   do ls = 1, 40
      lam1_try = lam1 - step*d1
      lam2_try = lam2 - step*d2
      w    = lam1_try*u + lam2_try*u*u
      wmax = maxval(w)
      q    = p*exp(w - wmax)
      if (sum(q) > 0d+0) then
         q  = q/sum(q)
         e1_try = sum(q*u)
         e2_try = sum(q*u*u)
         rn_try = abs(e1_try) + abs(e2_try - 1d+0)
         if (rn_try < rn) then
            lam1 = lam1_try; lam2 = lam2_try
            e1 = e1_try; e2 = e2_try; rn = rn_try
            exit
         end if
      end if
      step = 0.5d+0*step
   end do
   if (ls > 40) return                        ! no downhill step exists
end do
END SUBROUTINE match_moments


SUBROUTINE tauchen_fixed(n, z, rho_ar, mu_z, sd_eps, Pi, drift)
IMPLICIT NONE
INTEGER, INTENT(IN) :: n
DOUBLE PRECISION, INTENT(IN) :: z(n), rho_ar, mu_z, sd_eps
DOUBLE PRECISION, INTENT(IN), OPTIONAL :: drift
DOUBLE PRECISION, INTENT(OUT) :: Pi(n,n)
DOUBLE PRECISION :: drift_use
INTEGER :: i, j
DOUBLE PRECISION :: cond_mean, row_sum, edge(n+1)
LOGICAL :: tilted
INTEGER :: n_tilt_ok, n_tilt_fail
DOUBLE PRECISION, PARAMETER :: big = 1d+100   ! finite surrogate for infinity

if (sd_eps <= 0d+0) then
   write(*,*) 'tauchen_fixed: sd_eps must be positive, got', sd_eps
   call exit
end if
if (n < 2) then
   Pi = 1d+0
   return
end if

drift_use = 0d+0
if (present(drift)) drift_use = drift
n_tilt_ok   = 0
n_tilt_fail = 0

edge(1)   = -big
edge(n+1) =  big
do j = 2, n
   edge(j) = 0.5d+0*(z(j-1) + z(j))
end do

do i = 1, n
   ! drift enters the CONDITIONAL mean directly. Folding it into mu_z instead
   ! would deliver only (1-rho_ar) of it -- 2% at rho_p = 0.98.
   cond_mean = (1d+0 - rho_ar)*mu_z + rho_ar*z(i) + drift_use
   do j = 1, n
      Pi(i,j) = normal_cell((edge(j)-cond_mean)/sd_eps, (edge(j+1)-cond_mean)/sd_eps)
   end do
   row_sum = sum(Pi(i,:))
   if (row_sum <= 0d+0) then
      write(*,*) 'tauchen_fixed: degenerate row', i
      call exit
   end if
   Pi(i,:) = Pi(i,:)/row_sum

   ! Match the conditional mean and variance exactly. Near the grid edges the
   ! targets are unattainable on this support; there we keep the plain Tauchen
   ! row, which is the best available and carries almost no ergodic mass.
   if (use_moment_matching) then
      call match_moments(n, z, Pi(i,:), cond_mean, sd_eps*sd_eps, tilted)
      if (tilted) then
         n_tilt_ok = n_tilt_ok + 1
      else
         n_tilt_fail = n_tilt_fail + 1
      end if
   end if
end do

if (use_moment_matching) then
   write(*,'(a,f10.6,a,i6,a,i6)') ' tauchen_fixed: sd_eps=', sd_eps, &
        '  moment matching ok on ', n_tilt_ok, ' of ', n_tilt_ok + n_tilt_fail
   flush(6)
end if
END SUBROUTINE tauchen_fixed


!=====================================================================
! Conditional expectations of the value functions, by factorized contraction.
!
! The quantity needed is, for every (b', y, p, sigma),
!
!   E[V(b',y',p',sigma') | y,p,sigma]
!     = sum_{sigma'} P_s(s,s') sum_{p'} P_p(p,p'|s') sum_{y'} P_y(y,y') V(b',y',p',s')
!
! Evaluated as written, that is a triple sum inside the loop over (y,p,sigma)
! and b', costing b*(y*p*s)^2 per sweep -- QUADRATIC in p_num, so raising p_num
! from 7 to the ~201 a common grid needs is roughly an 800x increase.
!
! The kernel is a product, so the sum separates into three sequential
! contractions, each reusing the previous one:
!
!   A(b',y,p',s') = sum_{y'} P_y(y,y')    V(b',y',p',s')     ! no (p,s) dependence
!   B(b',y,p ,s') = sum_{p'} P_p(p,p'|s') A(b',y,p',s')
!   E(b',y,p ,s ) = sum_{s'} P_s(s,s')    B(b',y,p ,s')
!
! Cost becomes b*y*p^2*s (the middle step dominates) instead of b*y^2*p^2*s^2,
! a saving of y_num*p_vol_num ~ 105x at these dimensions.
!
! The autarky value v1_matrix carries NO debt index, so its expectation is
! contracted separately on (y,p,sigma) alone rather than recomputed b_num times.
!
! NOTE ON REPRODUCIBILITY: this reorders the summation, and floating-point
! addition is not associative, so results differ from the unfactorized version
! at the level of machine rounding. It is not bit-identical by construction.
!=====================================================================
SUBROUTINE precompute_expectations
IMPLICIT NONE
INTEGER :: iy, iyn, ip, ipn, iv, ivn, ib
DOUBLE PRECISION :: w, m_const, coup_const, sdc_sdf, eps_sdf, m_sdf_s
DOUBLE PRECISION :: acc_by(b_num, y_num), acc_y(y_num)

! --- Step 1: contract over next-period endowment ---
do ivn = 1, p_vol_num
   do ipn = 1, p_num
      do iy = 1, y_num
         exp_aux_a(:, iy, ipn, ivn) = 0d+0
         exc_aux_a(iy, ipn, ivn)    = 0d+0
         do iyn = 1, y_num
            w = trans_matrix(iy, iyn)
            exp_aux_a(:, iy, ipn, ivn) = exp_aux_a(:, iy, ipn, ivn) &
                 + w * v_matrix(:, iyn, ipn, ivn)
            exc_aux_a(iy, ipn, ivn) = exc_aux_a(iy, ipn, ivn) &
                 + w * v1_matrix(iyn, ipn, ivn)
         end do
      end do
   end do
end do

! --- Step 2: contract over next-period price, conditional on next volatility ---
! Contract over p' with the (b,y) plane as one contiguous block.
!
! Indexing this as exp_aux_a(:, iy, ipn, ivn) inside the ipn loop strides by
! b_num*y_num*8 bytes per step, re-traversing a scattered multi-MB region
! p_num times for every (iy, ivn). At p_num = 225 that was slow enough that a
! single call did not finish in ten minutes. Accumulating over the whole
! contiguous (b,y) slice instead keeps the accumulator in cache and streams
! the source once per ipn.
do ivn = 1, p_vol_num
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
end do

! --- Step 3: contract over next-period volatility ---
do iv = 1, p_vol_num
   do ip = 1, p_num
      acc_by = 0d+0
      acc_y  = 0d+0
      do ivn = 1, p_vol_num
         w = trans_matrix_p_vol(iv, ivn)
         acc_by = acc_by + w * exp_aux_b(:, :, ip, ivn)
         acc_y  = acc_y  + w * exc_aux_b(:, ip, ivn)
      end do
      exp_v_matrix(:, :, ip, iv)   = acc_by
      exp_v_excl_matrix(:, ip, iv) = acc_y
   end do
end do


! --- Bond price: the same contraction applied to the survival-weighted payoff ---
!
! q(b',y,p,s) = sum_{s',p',y'} P_s P_p P_y * surv(b',y',p',s')
!                              * m * (coupon + (1-delta)*q_paid(b',y',p',s'))
!
! q_fun evaluated this directly: a 23,625-term triple sum per call, called
! b_num times per state, i.e. 5.6e10 inner iterations per sweep at p_num = 225.
! It was the single largest cost and made a sweep take over eleven minutes.
!
! CAVEAT -- this changes the update scheme. q_fun read default_decision and
! q_paid_matrix as they stood at the moment of the call, and both are written
! DURING the sweep, so the original is Gauss-Seidel in those objects.
! Precomputing at the top of the sweep makes it Jacobi. The fixed point is the
! same; the path to it is not, so iterates differ and the sweep count can change.
m_const = EXP(-rstar)
coup_const = (rstar + delta)/(1d+0 + rstar)

do ivn = 1, p_vol_num
   do ipn = 1, p_num
      do iyn = 1, y_num
         do ib = 1, b_num
            q_src(ib, iyn, ipn, ivn) = &
                 (1d+0 - default_grid(default_decision(ib, iyn, ipn, ivn))) &
                 * (coup_const + (1d+0-delta)*q_paid_matrix(ib, iyn, ipn, ivn))
         end do
      end do
   end do
end do

do ivn = 1, p_vol_num
   do ipn = 1, p_num
      do iy = 1, y_num
         exp_aux_a(:, iy, ipn, ivn) = 0d+0
         do iyn = 1, y_num
            exp_aux_a(:, iy, ipn, ivn) = exp_aux_a(:, iy, ipn, ivn) &
                 + trans_matrix(iy, iyn) * q_src(:, iyn, ipn, ivn)
         end do
      end do
   end do
end do

! Risk-averse lenders (R1 major 5). The kernel must be applied HERE, in the
! p'-contraction, because it depends on the current price as well as the next:
!
!   log m' = -rstar + kappa_risk*eps' - 0.5*kappa_risk^2*Var(eps'|sigma')
!   eps'   = log p' - [(1-rho_p)*mean_p + rho_p*log p]
!
! Normalising by the CONDITIONAL variance makes E[m'|p,sigma] = exp(-rstar) in
! EVERY state, which the perpetuity q = E[m(coupon + (1-delta)q')] requires:
! it converges only if (1-delta)*E[m|state] < 1 everywhere. A kernel on the
! price LEVEL normalised by the unconditional variance fails this -- it gives
! E[m|p] = 7.1 at the top of the grid, so (1-delta)E[m] = 6.9 and q_def_free
! diverged to 1e92.
do ivn = 1, p_vol_num
   sdc_sdf = std_u_p*exp(p_vol_grid(ivn)/2d+0)
   do ip = 1, p_num
      acc_by = 0d+0
      do ipn = 1, p_num
         eps_sdf = p_grid(ipn, ivn) &
                   - ((1d+0-rho_p)*mean_p + rho_p*p_grid(ip, ivn))
         ! numerically normalised kernel; see the SDF NORMALISER note
         m_sdf_s = EXP(-rstar)*EXP(kappa_risk*eps_sdf)/sdf_norm(ip, ivn)
         acc_by = acc_by + trans_matrix_p(ip, ipn, ivn) * m_sdf_s &
                  * exp_aux_a(:, :, ipn, ivn)
      end do
      exp_aux_b(:, :, ip, ivn) = acc_by
   end do
end do

do iv = 1, p_vol_num
   do ip = 1, p_num
      acc_by = 0d+0
      do ivn = 1, p_vol_num
         acc_by = acc_by + trans_matrix_p_vol(iv, ivn) * exp_aux_b(:, :, ip, ivn)
      end do
      q_fun_matrix(:, :, ip, iv) = acc_by
   end do
end do

END SUBROUTINE precompute_expectations

!-----------------------------------------------------
! Bisection
!-----------------------------------------------------

function func_m(y_initial,p_initial)
!DOUBLE PRECISION function func_m(x)

implicit none
! RELATIVE bisection tolerance. The old value was an ABSOLUTE 1e-2 on both the
! residual and the bracket width. Oil demand is order 0.5-1.6, so that is a
! 0.6%-2% error in m, and it propagates into output, consumption, the value
! function and every spread. It is visible as a staircase in FIGURE4a/4b once
! the scale makes it large enough (sigma = 0.39, where m ~ 0.52).
!
! It must be RELATIVE: the upper bracket expands up to 1d+12 at very low prices,
! where double precision resolves the bracket only to ~1d+12*2**-52 ~ 2e-4, so a
! flat absolute 1e-10 would be unreachable and would trip the exit below.
double precision, parameter :: tol_bi=1d-10
integer, parameter :: itmax_bi=5000
!double precision, intent(in):: x1,x2
double precision, intent(in):: p_initial, y_initial
double precision:: d_bi, m_opt, mmin, mmax,func_m,A
integer :: iter_bi

!---------------------------------------------------------------------
! Memo cache.
!
! func_m is a pure function of (y_initial, p_initial, i_excl_global): A depends
! only on y_initial and i_excl_global, and the root condition only on those plus
! p_initial. Everything else is a compile-time parameter.
!
! `optimize` scans b_num = 100 debt choices and calls objective_function for
! each, and objective_function calls func_m -- but y_initial, p_initial and
! i_excl_global are module globals that do not change inside that loop. So 99
! of every 100 bisections repeat work already done. Caching the last result
! removes them. Results are bit-identical, not approximate: on a hit the stored
! value is the one the bisection would have recomputed.
!---------------------------------------------------------------------
if (m_cache_valid .and. i_excl_global == m_cache_excl .and. &
    y_initial == m_cache_y .and. p_initial == m_cache_p) then
   func_m = m_cache_val
   return
end if

!Initializing
mmin = 1e-16
mmax = mmax_global
d_bi = 1.
iter_bi =0
! p_initial=x1
! y_initial=x2
 A=(1d+0 - default_grid(i_excl_global)) * scale_y*EXP(y_initial) + &
           default_grid(i_excl_global) * scale_y*(EXP(y_initial)  - defloss(y_initial, p_initial))
! x=mmin-((alpha/exp(p_initial))**(1/(1-theta)))*(alpha*mmin**theta+(1-alpha)*(exp(y_initial)**theta))**(1/theta)
! if (x .le. zero) then
!A=scale_y*EXP(y_initial)
!print*,'A', A
! if (mmin-((alpha/exp(p_initial))**(1/(1-theta)))*(alpha*mmin**theta+(1-alpha)*(A**theta))**(1./theta) .le. zero) then
! print*, 'decrease mmin', mmin
!     CALL EXIT
! end if
!
! ! x=mmax-((alpha/exp(p_initial))**(1/(1-theta)))*(alpha*mmax**theta+(1-alpha)*(exp(y_initial)**theta))**(1/theta)
! ! if (x .ge. zero) then
! if (mmax-((alpha/exp(p_initial))**(1./(1.-theta)))*(alpha*mmax**theta+(1-alpha)*(A**theta))**(1./theta) .ge. zero) then
! print*, 'increase mmax', mmax
!     CALL EXIT
! end if

! Expand the upper bracket until it actually brackets the root.
!
! F(m) = m - (alpha/p)**(1/(1-theta)) * (alpha*m**theta + (1-alpha)*A**theta)**(1/theta)
! is increasing with F(0) < 0 whenever an interior optimum exists, so bisection
! needs F(mmax) > 0. The fixed mmax_global = 100 is not enough once the price
! grid reaches far enough down: at p = 0.118 with A = 13.2 the optimum is near
! m = 760. Doubling from mmax_global keeps the bracket tight in ordinary states
! -- which keeps the relative stopping rule cheap -- while
! still covering the extremes.
do while (mmax < 1d+12 .and. &
          mmax - ((alpha/exp(p_initial))**(1./(1.-theta))) &
                 *(alpha*mmax**theta+(1-alpha)*(A**theta))**(1./theta) < zero)
   mmax = mmax*2d+0
end do

m_opt=(mmin+mmax)/2.
do while(iter_bi .le. itmax_bi .and. d_bi .ge. tol_bi*max(1d+0, abs(m_opt)))
m_opt=(mmin+mmax)/2.
d_bi= m_opt-((alpha/exp(p_initial))**(1./(1.-theta)))*(alpha*m_opt**theta+(1-alpha)*(A**theta))**(1./theta)

if (d_bi .le. zero) then
mmin=m_opt
ELSE
mmax=m_opt
end if

d_bi=max(abs(d_bi),abs(mmin-mmax))
iter_bi=iter_bi+1
end do

func_m=m_opt
! print*, 'm_opt', m_opt
! print*, 'd_bi', d_bi

if (d_bi .ge. tol_bi*max(1d+0, abs(m_opt))) then
print *, 'iterations exceeded at bisection'
print*, 'd_bi', d_bi
print*, 'y_initial', y_initial, ' p_initial', exp(p_initial)
print*, 'An interior oil optimum needs p > alpha**(1/theta) =', alpha**(1d+0/theta)
call exit
end if

! Store only a converged result, so a failed solve can never be served from cache.
m_cache_y     = y_initial
m_cache_p     = p_initial
m_cache_excl  = i_excl_global
m_cache_val   = m_opt
m_cache_valid = .true.


end function func_m


!---------------------------------------------------------------------
! Normalised value added at the NO-DEFAULT TFP: (Y - p*m)/scale_y.
!
! Solves the same CES oil first-order condition as func_m but with the
! undamaged TFP, so the result is independent of the default penalty and no
! fixed point arises. Same relative bisection tolerance and bracket expansion
! as func_m; the duplication is deliberate, so that the hot path in func_m is
! untouched by this feature.
!---------------------------------------------------------------------
function va_norm(y_initial, p_initial)
implicit none
double precision, intent(in) :: y_initial, p_initial
double precision :: va_norm, A, Y, d_bi, m_opt, mmin, mmax
integer :: iter_bi
integer, parameter :: itmax_bi = 5000
double precision, parameter :: tol_bi = 1d-10

if (va_cache_valid .and. y_initial == va_cache_y .and. p_initial == va_cache_p) then
   va_norm = va_cache_val
   return
end if

A = scale_y*EXP(y_initial)                       ! undamaged TFP
mmin = 1d-16
mmax = mmax_global
do while (mmax < 1d+12 .and. &
          mmax - ((alpha/exp(p_initial))**(1./(1.-theta))) &
                 *(alpha*mmax**theta+(1-alpha)*(A**theta))**(1./theta) < zero)
   mmax = mmax*2d+0
end do

d_bi = 1d+0
iter_bi = 0
m_opt = (mmin+mmax)/2d+0
do while (iter_bi .le. itmax_bi .and. d_bi .ge. tol_bi*max(1d+0, abs(m_opt)))
   m_opt = (mmin+mmax)/2d+0
   d_bi = m_opt - ((alpha/exp(p_initial))**(1./(1.-theta))) &
                  *(alpha*m_opt**theta+(1-alpha)*(A**theta))**(1./theta)
   if (d_bi .le. zero) then
      mmin = m_opt
   else
      mmax = m_opt
   end if
   d_bi = max(abs(d_bi), abs(mmin-mmax))
   iter_bi = iter_bi + 1
end do

if (d_bi .ge. tol_bi*max(1d+0, abs(m_opt))) then
   print *, 'iterations exceeded in va_norm'
   print *, 'y_initial', y_initial, ' p_initial', exp(p_initial)
   call exit
end if

Y = ((1-alpha)*A**theta + alpha*m_opt**theta)**(1./theta)
va_norm = (Y - exp(p_initial)*m_opt)/scale_y

va_cache_y     = y_initial
va_cache_p     = p_initial
va_cache_val   = va_norm
va_cache_valid = .true.

end function va_norm


!---------------------------------------------------------------------
! The default output penalty, in endowment units. Identical to the submitted
! max(0, d0*EXP(y) + d1*EXP(y)**2) when va_default_cost = .false.; the only
! change is which base the quadratic is evaluated at.
!---------------------------------------------------------------------
function defloss(y_initial, p_initial)
implicit none
double precision, intent(in) :: y_initial, p_initial
double precision :: defloss, base

if (va_default_cost) then
   base = va_norm(y_initial, p_initial)
else
   base = EXP(y_initial)
end if
defloss = max(zero, d0*base + d1*base**2)

end function defloss


end module param



!DEFINE UTILITY FUNCTION
DOUBLE PRECISION function u_fun(cs)
USE param
DOUBLE PRECISION, INTENT(IN) :: cs
DOUBLE PRECISION :: c_min, con

c_min = 1d-10
con = MAX(cs,c_min)

if (sigma == 1) then
   u_fun = LOG(con)
else
   u_fun = (con**(1-sigma)) / (1-sigma)
end if
end function u_fun


!SPECIFY GRID VALUES
subroutine compute_grid
USE param
!USE shared_data
INTEGER :: i, j, k, l, z_index, sigma_index
DOUBLE PRECISION :: delta_y, prob_mass, y_pointer, qq, pdf_tirar, cdf_right, cdf_left, &
    prob_vector(y_num), y_left, y_right, scale_int, mu_sigma, variance_y, exp_y(y_num), meany, &
    prob_vector_p_vol(p_vol_num), prob_vector_p(p_num,p_vol_num), variance_p_vol, variance_p_innovation, exp_p(p_num, p_vol_num), &
    prob_vector_p_1(p_num,p_vol_num), prob_vector_p_2(p_num,p_vol_num), prob_vector_p_3(p_num,p_vol_num),&
    prob_vector_p_4(p_num,p_vol_num), prob_vector_p_5(p_num,p_vol_num), variance_p_innovation1, variance_p_innovation2,&
    variance_p_innovation3, variance_p_innovation4, variance_p_innovation5, &
    p_grid_common(p_num), var_log_vol, mean_innov_var, uncond_sd_log_p, grid_spacing, sd_log_vol, &
    v0_innov, mean_p_adj, mp_drift, &
    pv_new(p_num), pvv_new(p_vol_num)

    CHARACTER(LEN = 2) :: column_num
    CHARACTER(LEN = 1) :: fileName0
    CHARACTER(LEN = 9) :: fileName
    CHARACTER(LEN = 13) :: fileNameInit

!Discretize the s.s. for volatility shocks:
variance_p_vol = (std_u_vol*eta)**(2d+0)

if(p_vol_num < 2) then
   p_vol_grid = mean_p_vol
   trans_matrix_p_vol = 1d+0
   cdf_matrix_p_vol= 1d+0
   prob_vector_p_vol= 1d+0

 else
  if (use_common_p_grid) then
   !------------------------------------------------------------------
   ! Explicit volatility grid with a MATCHING kernel.
   !
   ! The submitted path below has the same defect that froze the price in the
   ! intermediate model: tauchen fills p_vol_grid (+/-m*sd, spacing 0.904 here)
   ! AND trans_matrix_p_vol, then discretize_AR overwrites the GRID with
   ! Rouwenhorst nodes (+/-sqrt(n-1)*sd, spacing 0.452) while its own matrix
   ! goes to trans_matrix_p_vol_AR, which is never read. The surviving Tauchen
   ! matrix was built for cells twice as wide as the grid actually has, so it
   ! puts too much mass on the diagonal and the volatility process comes out
   ! more persistent than calibrated. Unlike the price case this one is LIVE in
   ! the benchmark (p_vol_num = 5).
   !------------------------------------------------------------------
   sd_log_vol = sqrt(variance_p_vol/(1d+0 - rho_p_vol**(2d+0)))
   do i = 1, p_vol_num
      p_vol_grid(i) = mean_p_vol - p_vol_width_sd*sd_log_vol &
           + 2d+0*p_vol_width_sd*sd_log_vol*dble(i-1)/dble(p_vol_num-1)
   end do
   call tauchen_fixed(p_vol_num, p_vol_grid, rho_p_vol, mean_p_vol, &
                      sqrt(variance_p_vol), trans_matrix_p_vol)
   prob_vector_p_vol = 1d+0/dble(p_vol_num)
   do j = 1, 20000
      pvv_new = matmul(prob_vector_p_vol, trans_matrix_p_vol)
      if (maxval(abs(pvv_new - prob_vector_p_vol)) < 1d-14) then
         prob_vector_p_vol = pvv_new
         exit
      end if
      prob_vector_p_vol = pvv_new
   end do
   prob_vector_p_vol = prob_vector_p_vol/sum(prob_vector_p_vol)

   !------------------------------------------------------------------
   ! INTERMEDIATE economy: the oil price level still moves, its volatility
   ! does not. Volatility is held at the level that reproduces the
   ! UNCONDITIONAL variance of the price innovation in the SV economy,
   !
   !     E[exp(2h)] = exp(2*mu_h + 2*var_h)   =>   h_const = mu_h + var_h
   !
   ! which is -4.33 + 0.343 = -3.987 at this calibration -- the value the
   ! existing wrun_cv run uses. Matching the variance rather than the mean of h
   ! is what makes "full vs intermediate" isolate TIME-VARIATION in volatility
   ! rather than its level.
   !------------------------------------------------------------------
   if (constant_vol) then
      p_vol_grid         = mean_p_vol + 0.5d+0*sd_log_vol**(2d+0)
      trans_matrix_p_vol = 1d+0/dble(p_vol_num)
      prob_vector_p_vol  = 1d+0/dble(p_vol_num)
      write(*,'(a,f12.6)') ' constant_vol: h held at ', p_vol_grid(1)
   end if

   if (.not. constant_vol) then
   if (sqrt(variance_p_vol) < 0.5d+0*(p_vol_grid(2)-p_vol_grid(1))) then
      write(*,*) '*** WARNING: p_vol_num too small / p_vol_width_sd too wide:'
      write(*,*) '*** volatility innovation sd is under half a grid cell.'
   end if
   end if

  else
    !call tauchen(y_num,rho, zero, variance_y,m, y_grid, trans_matrix)
    call tauchen(p_vol_num,rho_p_vol, mean_p_vol, variance_p_vol,m, p_vol_grid, trans_matrix_p_vol)

   call discretize_AR(rho_p_vol, mean_p_vol , variance_p_vol, p_vol_grid, trans_matrix_p_vol_AR, prob_vector_p_vol)

   !------------------------------------------------------------------
   ! constant_vol on the PER-STATE grid path.
   !
   ! The constant_vol override above sits inside the use_common_p_grid
   ! branch, so with use_common_p_grid = .true. it never executed and the
   ! intermediate economy silently solved with FULL stochastic volatility --
   ! identical to the benchmark on every moment. Same level as the common-grid
   ! branch: h pinned at mu_h + var_h/2, which reproduces the UNCONDITIONAL
   ! variance of the price innovation, E[exp(h)] = exp(mu_h + var_h/2), so
   ! "full vs intermediate" isolates TIME-VARIATION in volatility rather
   ! than its level.
   !------------------------------------------------------------------
   if (constant_vol) then
      sd_log_vol         = sqrt(variance_p_vol/(1d+0 - rho_p_vol**(2d+0)))
      p_vol_grid         = mean_p_vol + 0.5d+0*sd_log_vol**(2d+0)
      trans_matrix_p_vol = 1d+0/dble(p_vol_num)
      prob_vector_p_vol  = 1d+0/dble(p_vol_num)
      write(*,'(a,f12.6)') ' constant_vol (per-state grid): h held at ', p_vol_grid(1)
   end if
  end if

   do i=1,p_vol_num
      cdf_matrix_p_vol(i,1) = trans_matrix_p_vol(i,1)
      do j=2,p_vol_num
         cdf_matrix_p_vol(i,j) = cdf_matrix_p_vol(i,j-1) + trans_matrix_p_vol(i,j)
      end do
   end do
end if

! open (200, FILE='graphs_trans_matrix_p_vol.txt',STATUS='replace')
! do i=1,p_vol_num
!    do j=1,p_vol_num
!       WRITE(200,*) cdf_matrix_p_vol(i,j)
!    end do
! end do
! close(200)

open (1, FILE='graphs_p_vol_grid_dss.txt',STATUS='replace')
   WRITE(1, '(F12.8)') p_vol_grid
close(1)

open (100, FILE='graphs_trans_matrix_p_vol.txt',STATUS='replace')
do i=1,p_vol_num
   do j=1,p_vol_num
      WRITE(100,*) trans_matrix_p_vol(i,j)
   end do
end do
close(100)

open (2, FILE='graphs_pdf_p_vol.txt',STATUS='replace')
WRITE(2, '(F12.8)') prob_vector_p_vol
close(2)

!Next, do it for p_level:
if(p_vol_num < 2) then
   if(p_num < 2) then
      !------------------------------------------------------------------
      ! BASIC economy: the oil price is constant. Pin it at the ERGODIC MEAN
      ! of the SV economy,
      !
      !     E[p] = exp( mean_p + 0.5*Var(log p) ),
      !
      ! NOT at exp(mean_p). Var(log p) = Var(innovation)/(1 - rho_p^2), with
      ! the innovation variance evaluated at the variance-matched volatility
      ! h = mu_h + var_h (the same level the intermediate economy uses).
      !
      ! Without this the constant-price economy faces a CHEAPER average oil
      ! bill than the full model -- exp(0.12) = 1.1275 against E[p] = 1.1324 --
      ! and the welfare comparison would pick up a lower price level rather
      ! than the absence of uncertainty. 0.12435 is the value the existing
      ! wrun_basic run uses.
      !------------------------------------------------------------------
      var_log_vol    = (std_u_vol*eta)**(2d+0)/(1d+0 - rho_p_vol**(2d+0))
      mean_innov_var = std_u_p**(2d+0)*exp(mean_p_vol + 0.5d+0*var_log_vol)
      p_grid = mean_p + 0.5d+0*mean_innov_var/(1d+0 - rho_p**(2d+0))
      write(*,'(a,f12.6)') ' basic: log price pinned at ', p_grid(1,1)
      trans_matrix_p = 1d+0
      cdf_matrix_p= 1d+0
      prob_vector_p= 1d+0

      variance_p_level_epsilon_tomorrow = 0d+0
   else

      scale_int = exp(0.5d+0 * eta**(2d+0)/(1d+0 - rho_p_vol**(2d+0)))
      ! E[exp(h)] under the exp(h/2) convention (see header note)
      variance_p_innovation = std_u_p**(2d+0) * exp(mean_p_vol &
           + 0.5d+0*eta**(2d+0)/(1d+0 - rho_p_vol**(2d+0)))
      ! scale_int is the fix for the Jensen's inequality

      ! NOTE: previously this called tauchen (filling p_grid(:,1) AND trans_matrix_p(:,:,1))
      ! and then discretize_AR, whose `z` argument is intent(out). That OVERWROTE the grid
      ! with Rouwenhorst nodes while leaving Tauchen's transition matrix (built for its own
      ! wider grid) in place, freezing the oil price. Dead code at p_vol_num=5, but it is
      ! the branch a p_vol_num=1 run takes -- see the intermediate model. Use discretize_AR
      ! for BOTH grid and matrix, as the p_vol_num >= 2 branch below does.
      call discretize_AR(rho_p, mean_p , variance_p_innovation, p_grid(:, 1), trans_matrix_p(:,:,1), prob_vector_p(:,1))

      variance_p_level_epsilon_tomorrow = variance_p_innovation
      !variance_r_level_epsilon_tomorrow is the conditional variance of innovations to the world interest rate *tomorrow*, conditional on
      !observing the \sigma_r today.

   end if

else

   if (use_common_p_grid) then

      !------------------------------------------------------------------
      ! ONE physical log-price grid, shared by every volatility state.
      !
      ! Width is set from the UNCONDITIONAL sd of log p, integrating over the
      ! volatility process:
      !     E[v] = E[exp(2*x)] = exp(2*mean_p_vol + 2*Var(x)),  x = log sd_t
      !     Var(x) = eta^2 / (1 - rho_p_vol^2)
      !     sd(log p) = sqrt( E[v] / (1 - rho_p^2) )
      ! Volatility then enters ONLY through the conditional sd in the kernel,
      ! so the price index means the same physical price in every state.
      !------------------------------------------------------------------
      var_log_vol        = (std_u_vol*eta)**(2d+0) / (1d+0 - rho_p_vol**(2d+0))
      mean_innov_var     = std_u_p**(2d+0)*exp(mean_p_vol + 0.5d+0*var_log_vol)
      uncond_sd_log_p    = sqrt(mean_innov_var / (1d+0 - rho_p**(2d+0)))

      do i = 1, p_num
         p_grid_common(i) = mean_p - p_width_sd*uncond_sd_log_p &
              + 2d+0*p_width_sd*uncond_sd_log_p*dble(i-1)/dble(p_num-1)
      end do

      do i = 1, p_vol_num
         ! Same grid in every column: p_grid(i_p, k) no longer depends on k.
         p_grid(:, i) = p_grid_common
         ! Mean-preserving correction (both reports' lead comment), applied on the
         ! common grid:  -0.5*[v_k - v0],  v0 = E[v].  It is a drift on the
         ! conditional mean, so E[p'|p,sigma] stops varying with sigma while the
         ! conditional dispersion still does.
         if (mean_preserving) then
            mp_drift = -0.5d+0*((std_u_p*exp(p_vol_grid(i)/2d+0))**2 - mean_innov_var)
         else
            mp_drift = 0d+0
         end if
         call tauchen_fixed(p_num, p_grid_common, rho_p, mean_p, &
                            std_u_p*exp(p_vol_grid(i)/2d+0), trans_matrix_p(:,:,i), mp_drift)
         ! Stationary distribution of the price chain conditional on this
         ! volatility state, by power iteration on the kernel.
         prob_vector_p(:, i) = 1d+0/dble(p_num)
         do j = 1, 20000
            pv_new = matmul(prob_vector_p(:, i), trans_matrix_p(:,:,i))
            if (maxval(abs(pv_new - prob_vector_p(:, i))) < 1d-14) then
               prob_vector_p(:, i) = pv_new
               exit
            end if
            prob_vector_p(:, i) = pv_new
         end do
         prob_vector_p(:, i) = prob_vector_p(:, i)/sum(prob_vector_p(:, i))
      end do

      ! The per-volatility-state grids used by working_graphs_dec29.m. Under a
      ! common grid these are the SAME physical grid; only the kernel differs by
      ! the volatility state it is conditioned on. Filling them here keeps the
      ! plotting script consistent with what the model actually solved on --
      ! without this they stay on the old Rouwenhorst per-state construction and
      ! the figures plot solved objects against the wrong price axis.
      do i = 1, p_vol_num
         p_grid_1(:, i) = p_grid_common
         p_grid_2(:, i) = p_grid_common
         p_grid_3(:, i) = p_grid_common
         p_grid_4(:, i) = p_grid_common
         p_grid_5(:, i) = p_grid_common
         call tauchen_fixed(p_num, p_grid_common, rho_p, mean_p, &
                            std_u_p*exp(p_vol_grid(1)/2d+0), trans_matrix_p_1(:,:,i))
         call tauchen_fixed(p_num, p_grid_common, rho_p, mean_p, &
                            std_u_p*exp(p_vol_grid(2)/2d+0), trans_matrix_p_2(:,:,i))
         call tauchen_fixed(p_num, p_grid_common, rho_p, mean_p, &
                            std_u_p*exp(p_vol_grid(3)/2d+0), trans_matrix_p_3(:,:,i))
         call tauchen_fixed(p_num, p_grid_common, rho_p, mean_p, &
                            std_u_p*exp(p_vol_grid(4)/2d+0), trans_matrix_p_4(:,:,i))
         call tauchen_fixed(p_num, p_grid_common, rho_p, mean_p, &
                            std_u_p*exp(p_vol_grid(5)/2d+0), trans_matrix_p_5(:,:,i))
      end do

      write(*,*) 'common price grid: sd(log p) =', uncond_sd_log_p, &
                 ' range =', exp(p_grid_common(1)), exp(p_grid_common(p_num))

      !------------------------------------------------------------------
      ! Resolution check. The grid must span the UNCONDITIONAL range while
      ! still resolving a one-period move, whose sd is exp(p_vol_grid(k)/2d+0) and
      ! is smallest in the lowest volatility state. If the node spacing is not
      ! comfortably below that sd, the conditional distribution collapses onto
      ! a single node and the chain is frozen in low-volatility states -- the
      ! same pathology, arrived at from the opposite direction.
      !------------------------------------------------------------------
      grid_spacing = p_grid_common(2) - p_grid_common(1)
      write(*,*) 'grid spacing =', grid_spacing
      do i = 1, p_vol_num
         write(*,*) '  vol state', i, ' cond sd =', std_u_p*exp(p_vol_grid(i)/2d+0), &
                    ' sd/spacing =', std_u_p*exp(p_vol_grid(i)/2d+0)/grid_spacing
      end do
      if (std_u_p*exp(p_vol_grid(1)/2d+0) < 2d+0*grid_spacing) then
         write(*,*) '*** WARNING: p_num too small for this price process.'
         write(*,*) '*** The lowest-volatility conditional sd is under 2 grid cells,'
         write(*,*) '*** so that state cannot move. Raise p_num (the standalone'
         write(*,*) '*** validation in oil_price_validation uses 201 price nodes)'
         write(*,*) '*** or narrow p_width_sd.'
      end if

   else

      ! Average innovation variance of the stochastic-volatility process,
      !   v0 = E[exp(2*sigma)] = exp(2*mean_p_vol + 2*Var(sigma)),
      ! used as the reference point for the mean-preserving correction below.
      v0_innov = std_u_p**(2d+0)*exp(mean_p_vol &
                 + 0.5d+0*(std_u_vol*eta)**(2d+0)/(1d+0 - rho_p_vol**(2d+0)))

      do i=1,p_vol_num
         variance_p_innovation = (std_u_p * exp(p_vol_grid(i)/2d+0))**(2)
         ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
         ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).

         !-------------------------------------------------------------
         ! MEAN-PRESERVING CORRECTION (both referee reports' lead comment).
         !
         ! Under the paper's process the conditional mean of the LEVEL is
         !   E[p'] = exp(m + v/2),
         ! so a rise in conditional volatility raises it even with the
         ! conditional mean of log p held fixed. Subtracting half the
         ! deviation of the conditional variance from its average v0
         ! removes that, leaving volatility to act only through dispersion:
         !
         !   log p_t - pbar = rho*(log p_{t-1} - pbar) - 0.5*[v_t - v0] + e^{sigma_t} u_t
         !
         ! discretize_AR takes mu as the process mean and the correction is a
         ! constant shift of it, so it passes through one-for-one.
         !
         ! v0 is the AVERAGE innovation variance E[v], not exp(2*mean_p_vol).
         ! That keeps the average amount of price risk unchanged, so this
         ! economy differs from the benchmark only in the timing of risk.
         !-------------------------------------------------------------
         if (mean_preserving) then
            mean_p_adj = mean_p - 0.5d+0*(variance_p_innovation - v0_innov)
         else
            mean_p_adj = mean_p
         end if

         !call tauchen(p_num,rho_p, mean_p, variance_p_innovation, m, p_grid(:, i), trans_matrix_p(:,:,i))
         call discretize_AR(rho_p, mean_p_adj , variance_p_innovation, p_grid(:, i), trans_matrix_p(:,:,i), prob_vector_p(:,i))
      end do

   end if

 !! Creating price grid for different levels of volatilities.
 !! SKIPPED under the common grid: these legacy blocks rebuild p_grid_1..p_grid_5
 !! with per-state Rouwenhorst grids and would OVERWRITE the common-grid values
 !! assigned above. working_graphs_dec29.m takes dprice from p_grid_3, so leaving
 !! them in place makes the figures divide by a price interval from a grid the
 !! model never solved on.
 if (.not. use_common_p_grid) then

 ! vol_grid=1
 do i=1,p_vol_num
      variance_p_innovation1 = (std_u_p * exp(p_vol_grid(1)/2d+0))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
      ! call tauchen(p_num,rho_p, mean_p, variance_p_innovation1, m, p_grid_1(:, i), trans_matrix_p_1(:,:,i))
      call discretize_AR(rho_p, mean_p , variance_p_innovation1, p_grid_1(:, i), trans_matrix_p_1(:,:,i), prob_vector_p_1(:,i))
   end do

 !vol_grid=2
 do i=1,p_vol_num
      variance_p_innovation2 = (std_u_p * exp(p_vol_grid(2)/2d+0))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
      ! call tauchen(p_num,rho_p, mean_p, variance_p_innovation2, m, p_grid_2(:, i), trans_matrix_p_2(:,:,2))
      call discretize_AR(rho_p, mean_p , variance_p_innovation2, p_grid_2(:, i), trans_matrix_p_2(:,:,i), prob_vector_p_2(:,i))
   end do

 !vol_grid=3
do i=1,p_vol_num
      variance_p_innovation3 = (std_u_p * exp(p_vol_grid(3)/2d+0))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
      ! call tauchen(p_num,rho_p, mean_p, variance_p_innovation3, m, p_grid_3(:, i), trans_matrix_p_3(:,:,3))
      call discretize_AR(rho_p, mean_p , variance_p_innovation3, p_grid_3(:, i), trans_matrix_p_3(:,:,i), prob_vector_p_3(:,i))
   end do

!vol_grid=4
do i=1,p_vol_num
      variance_p_innovation4 = (std_u_p * exp(p_vol_grid(4)/2d+0))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
       !call tauchen(p_num,rho_p, mean_p, variance_p_innovation4, m, p_grid_4(:, i), trans_matrix_p_4(:,:,4))
      call discretize_AR(rho_p, mean_p , variance_p_innovation4, p_grid_4(:, i), trans_matrix_p_4(:,:,i), prob_vector_p_4(:,i))
   end do

 !vol_grid=5
 do i=1,p_vol_num
      variance_p_innovation5 = (std_u_p * exp(p_vol_grid(5)/2d+0))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
      ! call tauchen(p_num,rho_p, mean_p, variance_p_innovation5, m, p_grid_5(:, i), trans_matrix_p_5(:,:,5))
      call discretize_AR(rho_p, mean_p , variance_p_innovation5, p_grid_5(:, i), trans_matrix_p_5(:,:,i), prob_vector_p_5(:,i))
   end do

 end if

   do i=1,p_vol_num

      mu_sigma = exp((1d+0-rho_p_vol)*mean_p_vol + rho_p_vol *p_vol_grid(i) + 0.5d+0 * eta**(2))
      variance_p_level_epsilon_tomorrow(i) = mu_sigma**(2)* exp(2d+0*eta)
   end do
   !variance_r_level_epsilon_tomorrow is the conditional variance of innovations to the world interest rate *tomorrow*, conditional on
   !observing the \sigma_r today.
end if

open (3, FILE='graphs_p_grid_dss.txt',STATUS='replace')
do k=1,p_vol_num
   do i=1,p_num
      WRITE(3, *) p_grid(i, k), p_grid_1(i,k), p_grid_2(i,k)
   end do
end do
close(3)

open (3000, FILE='graphs_p_grid_2_dss.txt',STATUS='replace')
do k=1,p_vol_num
   do i=1,p_num
      WRITE(3000, *) p_grid_3(i, k), p_grid_4(i, k), p_grid_5(i, k)
   end do
end do
close(3000)

exp_p=exp(p_grid)

open (301, FILE='graphs_trans_matrix_p.txt',STATUS='replace')
do k=1,p_vol_num
   do i=1,p_num
      do j=1,p_num
         WRITE(301,*) trans_matrix_p(i,j,k), trans_matrix_p_1(i,j,k), trans_matrix_p_2(i,j,k)
      end do
   end do
end do

close(301)

open (30001, FILE='graphs_trans_matrix_joint.txt',STATUS='replace')
do k=1,p_vol_num !current vol
do i=1,p_num      !current price
do l=1,p_vol_num  !future vol

      do j=1,p_num   !future price

         WRITE(30001,*) trans_matrix_p_vol(k,l)*trans_matrix_p(i,j,k)
      end do
   end do
end do
end do
close(30001)


open (3001, FILE='graphs_trans_matrix_p_2.txt',STATUS='replace')
do k=1,p_vol_num
   do i=1,p_num
      do j=1,p_num
         WRITE(3001,*) trans_matrix_p_3(i,j,k), trans_matrix_p_4(i,j,k), trans_matrix_p_5(i,j,k)
      end do
   end do
end do

close(3001)

do k=1,p_vol_num
   do i=1,p_num
      cdf_matrix_p(i,1,k) = trans_matrix_p(i,1,k)
      do j=2,p_num
         cdf_matrix_p(i,j,k) = cdf_matrix_p(i,j-1,k) + trans_matrix_p(i,j,k)
      end do
   end do
end do

!---------------------------------------------------------------------
! SDF NORMALISER.
!
! The risk kernel is  m' = exp(-rstar) * exp(kappa*eps') / Z(p, sigma'),
! with  Z = E[ exp(kappa*eps') | p, sigma' ]  computed on the ACTUAL grid.
! That makes E[m'] = exp(-rstar) exactly, which is what makes kappa_risk a
! price of RISK rather than a shift in the risk-free rate.
!
! The previous code used the analytic lognormal Jensen term,
! -0.5*kappa^2*sigma^2. That is correct only for a continuous normal
! innovation. On the 7-node Rouwenhorst grid exp(kappa*eps) spans orders of
! magnitude at kappa = 3, and the discrete expectation missed badly:
! E[m]/exp(-rstar) ran from 0.0000 to 2559 across (p, sigma) cells instead of
! 1. Worse, in the constant-price economy (p_num = 1) eps is identically zero
! while the correction still applied, so E[m] = exp(-rstar - 0.5*kappa^2*
! sigma^2): a pure discount-rate shift. That economy then showed a 22% spread
! with ZERO defaults in 500,000 periods.
!
! kappa_risk = 0 gives Z = 1 and m' = exp(-rstar), reproducing the
! risk-neutral model exactly, including when p_num = 1.
!---------------------------------------------------------------------
do k = 1, p_vol_num
   do i = 1, p_num
      sdf_norm(i,k) = 0d+0
      do j = 1, p_num
         sdf_norm(i,k) = sdf_norm(i,k) + trans_matrix_p(i,j,k) &
              * EXP(kappa_risk*( p_grid(j,k) &
                    - ((1d+0-rho_p)*mean_p + rho_p*p_grid(i,k)) ))
      end do
      if (sdf_norm(i,k) <= 0d+0) then
         print *, 'SDF normaliser non-positive at i_p, i_p_vol =', i, k
         call exit
      end if
   end do
end do
write(*,'(a,2f14.6)') ' SDF normaliser Z: min, max = ', &
     minval(sdf_norm), maxval(sdf_norm)

open (302, FILE='graphs_cdf_matrix_p.txt',STATUS='replace')
do k=1,p_vol_num
   do i=1,p_num
      do j=1,p_num
         WRITE(302,*) cdf_matrix_p(i,j,k)
      end do
   end do
end do
close(302)

open (4, FILE='graphs_pdf_p.txt',STATUS='replace')

do k=1,p_vol_num
      do j=1,p_num
         WRITE(4,*) prob_vector_p(j,k), exp_p(j,k)
      end do
end do
close(4)



    !-----------------------------------------------------------
    ! console output
    !------------------------------------------------------------
    WRITE(column_num, '(i2)' ) p_num
    outFormat = '('//column_num//'f22.16)'

    OPEN(unit=11,	file='p_grid.txt', status = 'replace')
	WRITE (11, '(1f22.16)') p_grid
	CLOSE (11)

    open(unit=98,file='p_vol_grid.txt')
    write(98,'(7f16.8)') p_vol_grid
    close(98)

!     open(unit=98,file='transition matrix.txt')
!     write(98,*) 'we have 5 grids for sigma and 25 grids for z'
!     write(98,*) ''
!     write(98,*) 'grid for p'
!     do i = 1,p_vol_num
! 	    write(98,'(17f16.8)') p_grid(:,i)
! 	end do
!     write(98,*) ''
!     write(98,*) 'transition for p_vol'
!     write(98,'(7f16.8)') trans_matrix_p_vol
!     write(98,*) ''
!     do i = 1,p_vol_num
!         write(98,*) 'conditional on vol grid',i
! 	    write(98,*) 'transition for p'
! 	    do j = 1,p_num
! 	    write(98,'(17f16.8)') trans_matrix_p(j,:,i)
! 	    end do
! 	    write(98,*) ''
! 	end do
!
!     close(98)

! open (100, FILE='graphs_trans_matrix_p_vol.txt',STATUS='replace')
! do i=1,p_vol_num
!    do j=1,p_vol_num
!       WRITE(100,*) trans_matrix_p_vol(i,j)
!    end do
! end do
! close(100)


    open(unit=9800,file='transition_matrix_p_vol.txt')
do i=1,p_vol_num
    do j=1,p_vol_num
       WRITE(9800,*) trans_matrix_p_vol(i,j)
    end do
 end do



    close(9800)



open(unit=980,file='transition_matrix_p.txt',STATUS='replace')


 do k=1,p_vol_num
    do j=1,p_num
       do i=1,p_num
          WRITE(980,*) trans_matrix_p(i,j,k)
       end do
    end do
 end do


    close(980)

! open (301, FILE='graphs_trans_matrix_p.txt',STATUS='replace')
! do l=1,p_vol_num
! do k=1,p_vol_num
!    do i=1,p_num
!       do j=1,p_num
!          WRITE(301,*) trans_matrix_p(i,j,k), trans_matrix_p_vol(k, l)*trans_matrix_p(i, j, k)
!       end do
!    end do
! end do
! end do
!
! close(301)



    DO sigma_index = 1,p_vol_num
        WRITE(fileName0, '(i1)' ) sigma_index


    END DO


!  Grid for the endowment process:

variance_y = (std_eps)**(2d+0)


call tauchen(y_num,rho, zero, variance_y,m, y_grid, trans_matrix)

open (5, FILE='graphs_y_grid_dss.txt',STATUS='replace')
   WRITE(5, '(F12.8)') y_grid
close(5)
exp_y=exp(y_grid)


meany=sum(exp_y)/size(exp_y)
open (501, FILE='graphs_trans_matrix_y.txt',STATUS='replace')
do i=1,y_num
   do j=1,y_num
      WRITE(501,*) trans_matrix(i,j)
   end do
end do
close(501)

do i=1,y_num
   cdf_matrix(i,1) = trans_matrix(i,1)
   do j=2,y_num
      cdf_matrix(i,j) = cdf_matrix(i,j-1) + trans_matrix(i,j)
   end do
end do

open (6, FILE='graphs_pdf_y.txt',STATUS='replace')
WRITE(6, '(F12.8)') prob_vector
close(6)





!Grid for the assets (negative assets == debt)
b_inf = 0.0d+0*scale_y*meany
b_sup = 2d+0*scale_y*meany


open (7, FILE='graphs_b_grid_dss.txt',STATUS='replace')

do i=1,b_num
   b_grid(i) = b_inf + (b_sup - b_inf) * (i-1) / (b_num - 1)
   WRITE(7, '(F12.8)') b_grid(i)
end do
close(7)

i_b_zero = 1d+0 ! this is a fix for the grid specification that has no positive values.

!Default (indictor) grid
default_grid(1) = 0d+00
default_grid(2) = 1d+00

!Store the bounds and the value of delta (decay coupon)
open (0, FILE='graphs_bounds_dss.txt',STATUS='replace')
WRITE(0,*) b_inf, b_sup
WRITE(0,*) y_grid(1), y_grid(y_num)
WRITE(0,*) p_vol_grid(1), p_vol_grid(p_vol_num)

close(0)

open (201, FILE='graphs_delta.txt',STATUS='replace')
WRITE(201,*) delta
close(201)

end subroutine compute_grid


DOUBLE PRECISION function q_def_free_fun(i_y, i_p, i_p_vol)
USE param
INTEGER, INTENT(IN) :: i_y, i_p, i_p_vol
DOUBLE PRECISION :: exp_m, exp_q, y_next, m_next, coupon_next, argument
INTEGER :: i, i_p_vol_next, i_p_next

exp_m = 0d+0
exp_q = 0d+0

do i_p_vol_next = 1,p_vol_num
   do i_p_next = 1,p_num
      do i=1,y_num

         y_next = y_grid(i)

         ! risk-averse lenders; identical kernel to precompute_expectations
         ! numerically normalised kernel; see the SDF NORMALISER note
         argument = rstar &
              - kappa_risk*( p_grid(i_p_next, i_p_vol_next) &
                   - ((1d+0-rho_p)*mean_p + rho_p*p_grid(i_p, i_p_vol_next)) ) &
              + LOG(sdf_norm(i_p, i_p_vol_next))

         m_next = EXP(- argument)
         coupon_next = (rstar + delta )/ (1d+0 + rstar)

         exp_m   = exp_m + m_next * coupon_next * trans_matrix_p_vol(i_p_vol, i_p_vol_next)*&
        trans_matrix_p(i_p, i_p_next, i_p_vol_next)* trans_matrix(i_y, i)

        exp_q = exp_q + (1d+0 - delta) * m_next * q_def_free_paid_matrix(i, i_p_next, i_p_vol_next) * &
        trans_matrix_p_vol(i_p_vol, i_p_vol_next)* trans_matrix_p(i_p, i_p_next, i_p_vol_next)*&
        trans_matrix(i_y, i)
      end do
   end do
end do

q_def_free_fun = exp_m + exp_q

end function q_def_free_fun

!ZERO-PROFIT BOND PRICE FUNCTION
DOUBLE PRECISION function q_fun(i_b, i_y, i_p, i_p_vol)
USE param
INTEGER, INTENT(IN) :: i_b, i_y, i_p, i_p_vol
DOUBLE PRECISION :: exp_m, exp_q, y_next, m_next, coupon_next, argument
INTEGER :: i, i_p_vol_next, i_p_next

exp_m = 0d+0
exp_q = 0d+0

do i_p_vol_next = 1,p_vol_num
   do i_p_next = 1,p_num
      do i=1,y_num
         y_next = y_grid(i)

         ! risk-averse lenders; identical kernel to precompute_expectations
         ! numerically normalised kernel; see the SDF NORMALISER note
         argument = rstar &
              - kappa_risk*( p_grid(i_p_next, i_p_vol_next) &
                   - ((1d+0-rho_p)*mean_p + rho_p*p_grid(i_p, i_p_vol_next)) ) &
              + LOG(sdf_norm(i_p, i_p_vol_next))

         m_next = EXP(- argument)
         coupon_next = (rstar + delta )/ (1d+0 + rstar)

         exp_m   = exp_m + m_next * coupon_next * trans_matrix_p_vol(i_p_vol, i_p_vol_next)*&
         trans_matrix_p(i_p, i_p_next, i_p_vol_next)* trans_matrix(i_y, i)*&
         (1d+0 -default_grid(default_decision(i_b, i, i_p_next, i_p_vol_next )))

         exp_q   = exp_q + (1d+0 - delta) * m_next * q_paid_matrix(i_b, i, i_p_next, i_p_vol_next) * &
         trans_matrix_p_vol(i_p_vol, i_p_vol_next)* trans_matrix_p(i_p, i_p_next, i_p_vol_next)*&
         trans_matrix(i_y, i)* (1d+0 -default_grid(default_decision(i_b, i, i_p_next, i_p_vol_next )))
      end do
   end do
end do

q_fun = exp_m + exp_q
end function q_fun

DOUBLE PRECISION function objective_function(b)
USE param
DOUBLE PRECISION, INTENT(IN) :: b
INTEGER :: d
DOUBLE PRECISION ::exp_v_next, exp_v_excl, q, output, consumption, oil_spending,TFP, p_eff
DOUBLE PRECISION, EXTERNAL:: u_fun, q_fun

exp_v_next = exp_v_vector(i_b_next)      !0d+0
exp_v_excl = exp_v_excl_vector(i_b_next) !0d+0

d  = i_default_global
q = q_vector(i_b_next)


 TFP = (1d+0 - default_grid(i_excl_global)) * scale_y*EXP(y_initial) + &
          default_grid(i_excl_global) * scale_y*(EXP(y_initial)  - defloss(y_initial, p_initial))
         ! print*,'TFP_objective', TFP
!oil_spending= TFP*(alpha/exp(p_initial))**(1/(1-alpha))
! oil is disrupted exactly when the endowment loss applies, i.e. in default
p_eff = p_initial + default_grid(i_excl_global)*log(1d+0 + oil_disruption)
oil_spending=func_m(y_initial,p_eff)
!print*, 'oil_spending', oil_spending
output=((1-alpha)*TFP**theta+alpha*oil_spending**theta)**(1./theta)

consumption=output-oil_spending*exp(p_eff)-(b_initial *coupon - q * (b-(1d+0 - delta)*b_initial) )*(1-default_grid(i_excl_global))


objective_function = u_fun(consumption) + beta * &
( default_grid(i_excl_global) * (prob_excl_end *exp_v_next + &
(1d+0 -prob_excl_end) * exp_v_excl) + (1d+0 - default_grid(i_excl_global)) * exp_v_next)


end function objective_function

subroutine optimize(index_opt, v_value)
USE param
integer ::i, index_opt, index_vector(1)
DOUBLE PRECISION :: b_next, v_value,  vector(b_num)
DOUBLE PRECISION, EXTERNAL:: objective_function

do i=1,b_num
   i_b_next = i
   b_next   = b_grid(i)
   vector(i)  = objective_function(b_next)

end do

index_vector = maxloc(vector)
v_value = vector(index_vector(1))
index_opt = index_vector(1)

end subroutine optimize

subroutine iterate
USE param
DOUBLE PRECISION :: v_valor, convergence, criteria, deviation,deviation_q, b_next, v1_matrix_new(y_num,p_num,p_vol_num), expectation, &
                    exp_v_excl, exp_v_next, q_def_free_paid_matrix_new(y_num, p_num,p_vol_num)
! c1_matrix, output1_matrix, oil1_matrix, TFP1_matrix are now module-level (see module param)

DOUBLE PRECISION, DIMENSION(b_num, y_num, p_num,p_vol_num) :: v0_matrix_new, c0_matrix, oil0_matrix, &
                                            q_paid_matrix_new, output0_matrix, TFP0_matrix

DOUBLE PRECISION, DIMENSION(b_num, y_num, p_num,p_vol_num) :: v_matrix_new, dev_matrix, dev_matrix_q
INTEGER i_b, i_y,i_p, i_p_vol, i_p_next, i_p_vol_next, i_b_optimal0, i_b_optimal1, i_y_next, i_b_prime
DOUBLE PRECISION, EXTERNAL:: q_fun, objective_function, q_def_free_fun


criteria = 1.0d-3   !CRITERIA FOR CONVERGENCE
convergence = -1


do WHILE(convergence<0)
   deviation = 0
   deviation_q = 0
   counter = counter + 1


coupon = (rstar + delta )/ (1d+0 + rstar)

! All conditional expectations of v_matrix and v1_matrix for this sweep, built
! by factorized contraction instead of a triple sum per (b',y,p,sigma). See
! precompute_expectations for the algebra and the cost argument.
call precompute_expectations

do i_p_vol = 1,p_vol_num
      do i_p = 1,p_num
      p_initial=p_grid(i_p,i_p_vol)
     ! print*, 'p_initial-ITERATE', p_initial
         do i_y = 1,y_num
            i_y_global = i_y
            y_initial = y_grid(i_y)

! HERE WE COMPUTE THE EXPECTED VALUE FUNCTIONS, AND ALSO THE PRICE FOR EACH POSSIBLE LEVEL OF B_NEXT
            ! Expectations were built for every (b',y,p,sigma) by
            ! precompute_expectations above; exp_v_excl has no debt index.
            exp_v_vector(:)      = exp_v_matrix(:, i_y_global, i_p, i_p_vol)
            exp_v_excl_vector(:) = exp_v_excl_matrix(i_y_global, i_p, i_p_vol)

            do i_b_prime = 1,b_num
               q_vector(i_b_prime) = q_fun_matrix(i_b_prime, i_y_global, i_p, i_p_vol)
            end do


! NOW, COMPUTE THE VALUE FUNCTION OF DEFAULT (WHICH DEPENDS ONLY ON INCOME)

            i_default_global=2 !Country defaults
            i_excl_global=2

            i_b_next = i_b_zero
            i_b_optimal1 = i_b_zero
            b_next   = b_grid(i_b_next)
            v1_matrix_new(i_y, i_p, i_p_vol) = objective_function(b_next)

            TFP1_matrix(i_y, i_p, i_p_vol)= scale_y*(EXP(y_initial)  - defloss(y_initial, p_initial))
            oil1_matrix(i_y, i_p, i_p_vol)=func_m(y_initial,p_initial+log(1d+0+oil_disruption))
            output1_matrix(i_y, i_p, i_p_vol)=(((1.-alpha)*TFP1_matrix(i_y, i_p, i_p_vol)**theta)+(alpha*oil1_matrix(i_y, i_p, i_p_vol)**theta))**(1./theta)

            c1_matrix(i_y, i_p, i_p_vol) = output1_matrix(i_y, i_p, i_p_vol)-EXP(p_initial+log(1d+0+oil_disruption))*oil1_matrix(i_y, i_p, i_p_vol)

         q_def_free_paid_matrix_new(i_y, i_p, i_p_vol) = q_def_free_fun(i_y,i_p,i_p_vol)


            do i_b = 1, b_num
               i_b_global = i_b
               b_initial = b_grid(i_b)

               ! NOW, COMPUTE THE VALUE FUNCTION OF REPAYMENT (WHICH DEPENDS ON DEBT AND INCOME)

               i_default_global= 1   ! Country does not default and is not excluded for the next period
               i_excl_global= 1

               ! THIS STEP FINDS THE OPTIMAL B_NEXT FOR A GIVEN INITIAL DEBT AND INCOME REALIZATION:
               call optimize(i_b_optimal0, v_valor)

               b0_next_matrix(i_b, i_y, i_p, i_p_vol) = b_grid(i_b_optimal0)
               b0_next_matrix_indice(i_b, i_y, i_p, i_p_vol) = i_b_optimal0

               v0_matrix_new(i_b, i_y, i_p, i_p_vol) = v_valor


               TFP0_matrix(i_b, i_y, i_p, i_p_vol)=scale_y*exp(y_initial)
               oil0_matrix(i_b, i_y, i_p, i_p_vol)=func_m(y_initial,p_initial)
            output0_matrix(i_b, i_y, i_p, i_p_vol)=(((1-alpha)*TFP0_matrix(i_b, i_y, i_p, i_p_vol)**theta)+(alpha*oil0_matrix(i_b, i_y, i_p, i_p_vol)**theta))**(1./theta)

               c0_matrix(i_b, i_y, i_p, i_p_vol)=output0_matrix(i_b, i_y, i_p, i_p_vol)- b_initial * coupon +(b_grid(i_b_optimal0)-&
               (1d+0 - delta)*b_initial)* q_fun_matrix(i_b_optimal0, i_y,i_p,i_p_vol)-exp(p_initial)*oil0_matrix(i_b, i_y, i_p, i_p_vol)
!

               ! NOW, CHECK IF FOR THIS COMBINATION (b_initial,y_initial, i_r, i_r_vol) IT IS OPTIMAL TO DEFAULT OR NOT
               if (v1_matrix_new(i_y,i_p, i_p_vol) > v0_matrix_new( i_b, i_y,i_p, i_p_vol)) then
                  default_decision(i_b, i_y,i_p, i_p_vol) = 2
                  b_next_matrix(i_b, i_y,i_p, i_p_vol) = i_b_optimal1
                  v_matrix_new(i_b, i_y,i_p, i_p_vol) = v1_matrix_new(i_y,i_p, i_p_vol)
                  TFP_matrix(i_b, i_y,i_p, i_p_vol) = TFP1_matrix(i_y,i_p, i_p_vol)
                  oil_matrix(i_b, i_y,i_p, i_p_vol) = oil1_matrix(i_y,i_p, i_p_vol)
                  output_matrix(i_b,i_y,i_p, i_p_vol)=output1_matrix(i_y,i_p, i_p_vol)
                  c_matrix(i_b, i_y,i_p, i_p_vol) = c1_matrix(i_y,i_p, i_p_vol)


                  q_paid_matrix_new(i_b, i_y,i_p, i_p_vol) =  0d+0  !!I think this is correct

               else
                  default_decision( i_b, i_y,i_p, i_p_vol) = 1
                  b_next_matrix(i_b, i_y,i_p, i_p_vol) = i_b_optimal0  !SAVINGS IF NOT EXCLUDED
                  v_matrix_new(i_b, i_y,i_p, i_p_vol) = v0_matrix_new(i_b,i_y,i_p, i_p_vol)
                  TFP_matrix(i_b,i_y,i_p, i_p_vol)=TFP0_matrix(i_b,i_y,i_p, i_p_vol)
                  oil_matrix(i_b, i_y,i_p, i_p_vol) = oil0_matrix(i_b,i_y,i_p, i_p_vol)
                  output_matrix(i_b,i_y,i_p, i_p_vol)=output0_matrix(i_b,i_y,i_p, i_p_vol)
                  c_matrix(i_b, i_y,i_p, i_p_vol) = c0_matrix(i_b,i_y,i_p, i_p_vol)


                  q_paid_matrix_new(i_b, i_y,i_p, i_p_vol) =  q_fun_matrix(i_b_optimal0, i_y,i_p, i_p_vol)
!

               end if


!NOW, COMPUTE THE DEVIATION (I.E. HOW FAR WE ARE FROM CONVERGING):
               deviation = MAX(deviation, ABS(v_matrix_new( i_b, i_y,i_p, i_p_vol) - v_matrix(i_b, i_y,i_p, i_p_vol)))
               deviation_q = MAX(deviation_q, ABS(q_paid_matrix_new( i_b, i_y,i_p, i_p_vol) - q_paid_matrix(i_b, i_y,i_p, i_p_vol)))

               dev_matrix(i_b, i_y,i_p, i_p_vol) = ABS(v_matrix_new(i_b, i_y,i_p, i_p_vol)-v_matrix( i_b, i_y,i_p, i_p_vol))
               dev_matrix_q(i_b, i_y,i_p, i_p_vol) = ABS(q_paid_matrix_new(i_b, i_y,i_p, i_p_vol)-q_paid_matrix( i_b, i_y,i_p, i_p_vol))


           end do
         end do
      end do
   end do

   WRITE(*, *) counter, deviation, deviation_q

    !UPDATE VALUES OF MATRICES
   v0_matrix = v0_matrix_new
   v1_matrix = v1_matrix_new
   v_matrix = v_matrix_new
   q_paid_matrix = q_paid_matrix_new
    q_def_free_paid_matrix = q_def_free_paid_matrix_new



! FINALLY, CHECK WHETHER THE NEW DEVIATION IS SMALLER THAN THE TOLERANCE LEVEL (CALLED CRITERIA IN THIS CODE)
   if (deviation < criteria .or. counter > 1499) then

!3) SAVE RESULTS OF THE CURRENT ITERATION
      open (8, FILE='graphs_output_dss.txt',STATUS='replace')
       open (9, FILE='graphs_v_dss.txt',STATUS='replace')
      open (10, FILE='graphs_default_dss.txt',STATUS='replace')
      open (11, FILE='graphs_q_dss.txt',STATUS='replace')
      open (12, FILE='graphs_b_next_dss.txt',STATUS='replace')
      open (13, FILE='graphs_dev_dss.txt',STATUS='replace')
      open (14, FILE='graphs_q_paid_dss.txt',STATUS='replace')
      open (15, FILE='graphs_b0_next_dss.txt',STATUS='replace')
      open (16, FILE='graphs_cons_dss.txt',STATUS='replace')
      open (17, FILE='graphs_counter.txt', STATUS='replace')
      open (18, FILE='graphs_oil_dss.txt', STATUS='replace')
      open (19, FILE='graphs_q_def_free_dss.txt',STATUS='replace')
      !open (109, FILE='graphs_expectation_dss.txt',STATUS='replace')


WRITE(17, *) counter

      do i_p_vol = 1,p_vol_num
         do i_p = 1,p_num
        do i_y = 1,y_num

               i_p_global = i_p
               p_initial = p_grid(i_p, i_p_vol)

            i_y_global = i_y
            y_initial = y_grid(i_y)
            do i_b = 1,b_num

               b_initial = b_grid(i_b)
               i_b_global = i_b

            WRITE(8,*) output_matrix(i_b, i_y,i_p, i_p_vol), output0_matrix(i_b, i_y,i_p, i_p_vol), output1_matrix( i_y,i_p, i_p_vol)
               WRITE(9,*) v_matrix_new(i_b, i_y,i_p, i_p_vol), v0_matrix_new(i_b, i_y,i_p, i_p_vol), v1_matrix_new( i_y,i_p, i_p_vol)

               WRITE(10, '(F6.2)') default_grid(default_decision(i_b, i_y,i_p, i_p_vol))


               WRITE(11, '(F15.11)') q_fun_matrix(i_b, i_y,i_p, i_p_vol)

               WRITE(12, *) b_next_matrix(i_b, i_y,i_p, i_p_vol)

               WRITE(13, *) dev_matrix(i_b, i_y,i_p, i_p_vol), dev_matrix_q(i_b, i_y,i_p, i_p_vol)

               WRITE(14, '(F15.11)') q_paid_matrix_new(i_b, i_y,i_p, i_p_vol)
               WRITE(15,*) b0_next_matrix(i_b, i_y, i_p, i_p_vol), b0_next_matrix_indice(i_b, i_y, i_p, i_p_vol)

               WRITE(16,*) c_matrix(i_b, i_y,i_p, i_p_vol), c0_matrix(i_b, i_y,i_p, i_p_vol), c1_matrix( i_y,i_p, i_p_vol)

               WRITE(18,*) oil_matrix(i_b, i_y,i_p, i_p_vol), oil0_matrix(i_b, i_y,i_p, i_p_vol), oil1_matrix( i_y,i_p, i_p_vol)

               WRITE(19, *) q_def_free_paid_matrix(i_y,i_p, i_p_vol)
               !WRITE(109, *) expectation(i_b,i_y,i_p, i_p_vol)


            end do
            end do
         end do
      end do

    CLOSE(8)
    CLOSE(9)
   CLOSE(10)
   CLOSE(11)
   CLOSE(12)
   CLOSE(13)
   CLOSE(14)
   CLOSE(15)
   CLOSE(16)
   CLOSE(17)
   CLOSE(18)
   CLOSE(19)
  ! close(109)



   ! declare success:
   convergence=1
   end if
write(*,*) 'finished saving'


end do

end subroutine iterate

subroutine solve_q_nodef
USE param
DOUBLE PRECISION :: dev, criterion_q_nodef, q_nodef_new(y_num,p_num,p_vol_num), coupon_nodef,&
argument, sdf_value, q_nodef_scalar, q_nodef_scalar_new
INTEGER :: i_y, i_p, i_p_vol, i_y_next, i_p_vol_next, i_p_next

! 1. The stochastic discount factor.
!
! argument is identically rstar, so every element of what used to be a rank-6
! SDF_matrix(y,p,s,y,p,s) held the same number. That array is 6.9e8 doubles
! (5.6 GB) at p_num = 251, which simply cannot be allocated, so it is replaced
! by the scalar it always was. If a state-dependent SDF is introduced later --
! Referee 1's Major 5 asks about risk-averse lenders -- this is where it goes,
! and it should then be stored as a function of the states it actually varies
! over, not as a full rank-6 product space.
argument  = rstar
sdf_value = EXP(-argument)

!1.5 Intermediate step: compute the Expected SDF (I don't need it here, but I wanted for the simulations)
! The expected SDF. With a constant SDF and transition rows that each sum to
! one, the triple sum is identically sdf_value, so the (y*p*s)^2 loop that used
! to accumulate it -- 5.6e8 terms at p_num = 225 -- is replaced by an assignment.
expected_SDF_matrix = sdf_value

!2. Iterate on q_nodef
!
! q(s) = sum_s' P(s,s') * sdf * (coupon + (1-delta)*q(s'))
!
! sdf and coupon are constants and every transition row sums to one, so the
! right-hand side does not depend on s: q is the SAME NUMBER in every state.
! The original loop rediscovered that by summing over the full (y,p,sigma)
! product space on every sweep -- (y*p*s)^2 = 2.8e8 terms per sweep at
! p_num = 225, times ~300 sweeps -- to produce one scalar.
!
! The scalar recursion below is the same sequence from the same starting point
! with the same stopping rule, so it reproduces the previous value. Note that
! value is not the exact fixed point: stopping on a per-step change of 1e-6
! with a contraction factor of sdf*(1-delta) ~ 0.96 leaves a residual error of
! about 2.4e-5. The exact root is
!     q = sdf*coupon / (1 - sdf*(1-delta))
! which here is 0.9888588 against the iterate's 0.9888352. Tightening
! criterion_q_nodef, or using the closed form, is a separate decision because
! it would move the benchmark.

dev = 10d+0
criterion_q_nodef = 1d-6
q_nodef_scalar = 0d+0
coupon_nodef = (rstar + delta )/ (1d+0 + rstar)

do while(dev > criterion_q_nodef)
   q_nodef_scalar_new = sdf_value*(coupon_nodef + (1d+0-delta)*q_nodef_scalar)
   dev = abs(q_nodef_scalar_new - q_nodef_scalar)
   q_nodef_scalar = q_nodef_scalar_new
end do

q_nodef = q_nodef_scalar

!3. Save q_nodef and SDF_matrix

open (20, FILE='graphs_sdf_matrix.txt',STATUS='replace')
open (21, FILE='graphs_q_def_free.txt',STATUS='replace')
open (22, FILE='graphs_expected_sdf_matrix.txt',STATUS='replace')

do i_p_vol = 1,p_vol_num
   do i_p = 1,p_num
      do i_y = 1,y_num
         write(21, *) q_nodef(i_y, i_p, i_p_vol)
         write(22, *) expected_SDF_matrix(i_y, i_p, i_p_vol)
      end do
   end do
end do

! The SDF is a single constant, so write it once rather than dumping the same
! number over the whole (y,p,sigma)^2 product space. That loop wrote 5.6e8
! identical lines at p_num = 225 -- roughly 12 GB, and formatting them was
! consuming ~76% of total runtime, which is what stalled the first attempts at
! a large-grid solve. At the submitted p_num = 7 it was 14 MB of one repeated
! value. Nothing reads this file: working_graphs_dec29.m never references it.
write(20, *) sdf_value

close(20)
close(21)
close(22)

end subroutine solve_q_nodef



program main
USE param
USE shared_types
DOUBLE PRECISION ::  start_time, end_time, indicator_external
INTEGER  i_b, i_y, i_p, i_p_vol
DOUBLE PRECISION, EXTERNAL:: q_fun, u_fun
open (100, FILE='param_calib.txt')

 write(100, *) beta
 write(100, *) d0
 write(100, *) d1
 write(100, *) delta


close (100)


call cpu_time(start_time)
call compute_grid
call solve_q_nodef

indicator_external = 0 !IF SET TO 1 OR LARGER, CODE WILL START FROM PREVIOUSLY STORED ITERATION

if (indicator_external < 0.5d+0) then

!THIS PART IS THE COMPUTATION OF THE VALUE FUNCTIONS FOR THE LAST PERIOD
! --> THESE WILL BE THE INITIAL GUESSES FOR THE VFI ALGORITHM

counter = 0

do i_p_vol = 1,p_vol_num
      do i_p = 1,p_num
         coupon = (rstar + delta) / (1d+0 + rstar)
         p_initial = p_grid(i_p,i_p_vol)
         print*, 'p_initial', p_initial
         do i_y = 1,y_num

            y_initial = y_grid(i_y)
            print*,'i_y', i_y
        TFP1(i_y,i_p,i_p_vol)=scale_y*(EXP(y_initial)  - defloss(y_initial, p_initial))
        !print*, 'TFP1(i_y,i_p,i_p_vol)', TFP1(i_y,i_p,i_p_vol)
        m1(i_y,i_p,i_p_vol)=func_m(y_initial,p_initial+log(1d+0+oil_disruption))
       !m1(i_y,i_p,i_p_vol)=0d+0
        !print*, 'm1(i_y,i_p,i_p_vol)',m1(i_y,i_p,i_p_vol)
       !v1_matrix(i_y,i_p,i_p_vol) = u_fun((alpha**(alpha-(1/(1-alpha))))*(alpha*TFP1(i_y,i_p,i_p_vol)/(exp(p_initial)**alpha))**(1./(1-alpha)))
       v1_matrix(i_y,i_p,i_p_vol)=u_fun(((1-alpha)*TFP1(i_y,i_p,i_p_vol)**theta+alpha*m1(i_y,i_p,i_p_vol)**theta)**(1./theta)-&
       m1(i_y,i_p,i_p_vol)*exp(p_initial+log(1d+0+oil_disruption)))
            q_def_free_paid_matrix(i_y,i_p,i_p_vol) = 0d+0

            do i_b = 1,b_num

               b_initial = b_grid(i_b)

                TFP0(i_b,i_y,i_p,i_p_vol)=scale_y*EXP(y_initial)
                !print*, 'TFP0(i_b,i_y,i_p,i_p_vol)', TFP0(i_b,i_y,i_p,i_p_vol)
                !m0(i_b,i_y,i_p,i_p_vol)=0d+0
                m0(i_b,i_y,i_p,i_p_vol)=func_m(y_initial,p_initial)
               v0_matrix(i_b,i_y,i_p,i_p_vol)=u_fun(((1-alpha)*TFP0(i_b,i_y,i_p,i_p_vol)**theta+alpha*m0(i_b,i_y,i_p,i_p_vol)**theta)**(1./theta)-&
               m0(i_b,i_y,i_p,i_p_vol)*exp(p_initial)-b_grid(i_b) * coupon)
               ! v0_matrix(i_b,i_y,i_p,i_p_vol) = u_fun((alpha**(alpha-(1/(1-alpha))))*(alpha*TFP0(i_b,i_y,i_p,i_p_vol)/(exp(p_initial)**alpha))**(1./(1-alpha))-b_grid(i_b) * coupon)
               !v0_matrix(i_b,i_y,i_p,i_p_vol)=u_fun(scale_y*exp(y_initial)-b_grid(i_b) * coupon)


               if(v1_matrix(i_y,i_p,i_p_vol) > v0_matrix(i_b, i_y,i_p,i_p_vol) )then
                  default_decision(i_b,i_y,i_p,i_p_vol)=2
                  !print*,'default_decision', default_decision
                  v_matrix(i_b, i_y,i_p,i_p_vol) = v1_matrix(i_y,i_p,i_p_vol)
               else
                  default_decision(i_b,i_y,i_p,i_p_vol)=1
                  v_matrix(i_b, i_y,i_p,i_p_vol) = v0_matrix(i_b,i_y,i_p,i_p_vol)
               end if

               q_paid_matrix(i_b, i_y,i_p,i_p_vol) = 0d+0

            end do
         end do
      end do
   end do


else !READ DATA FROM EXTERNAL FILES

      open (9, FILE='graphs_v_dss.txt')

      open (11, FILE='graphs_q_def_free.txt')
      open (12, FILE='graphs_b_next_dss.txt')
      open (14, FILE='graphs_q_paid_dss.txt')
      open (17, FILE='graphs_counter.txt')
      open (19, FILE='graphs_q_def_free_dss.txt')


        READ(17,*) counter
        write(*,*) counter

          do i_p_vol = 1,p_vol_num
            do i_p = 1,p_num
               do i_y = 1,y_num

            READ(11, *) q_nodef(i_y,i_p, i_p_vol)

            READ(19, *) q_def_free_paid_matrix(i_y,i_p, i_p_vol)

            do i_b = 1,b_num


               READ(14, *) q_paid_matrix(i_b, i_y,i_p, i_p_vol)
               READ(12, *) b_next_matrix(i_b, i_y,i_p, i_p_vol)

               READ(9, *) v_matrix(i_b, i_y,i_p, i_p_vol), v0_matrix(i_b, i_y,i_p, i_p_vol), v1_matrix(i_y,i_p, i_p_vol)



               if (v0_matrix(i_b, i_y,i_p, i_p_vol)< v1_matrix(i_y,i_p, i_p_vol)) then
                  default_decision(i_b, i_y,i_p, i_p_vol) =2
               else
                  default_decision(i_b, i_y,i_p, i_p_vol) =1
               end if

            end do
         end do
      end do
   end do

   CLOSE(9)

   CLOSE(11)
   CLOSE(12)
   close (14)
   CLOSE(17)
   CLOSE(19)


end if

!write(*,*)'prob excl end', prob_excl_end
call iterate
call simulate



call cpu_time(end_time)
WRITE(*, *) 'Hours ', 'Minutes', 'Seconds'
WRITE(*, *) INT((end_time - start_time) / 3600d+0), &
     INT((end_time-start_time)/60d+0 - INT((end_time - start_time) / 3600d+0)*60d+0),&
     INT(end_time-start_time - INT((end_time - start_time) / 3600d+0)*3600d+0 - &
     INT((end_time-start_time)/60d+0 - INT((end_time - start_time) / 3600d+0)*60d+0)*60d+0)
end program main

subroutine simulate
USE param
USE shared_types
integer :: period_num, i,j, sample_num, default_num, i_y_previous, i_y_current, i_b_current ,i_p_previous,&
     i_p_current,i_p_vol_previous,i_p_vol_current

parameter (sample_num =500, period_num=1501)
DOUBLE PRECISION :: random_matrix(period_num, sample_num, 2), random_vector(1:2*sample_num*period_num), vol(period_num,sample_num), &
      random_matrix_rw(period_num, sample_num, 2), random_vector_rw(1:2*sample_num*period_num), &
      p(period_num,sample_num), p_vol_matrix(period_num,sample_num), &
     z_shock(period_num,sample_num), b(period_num+1,sample_num), c(period_num,sample_num), oil(period_num,sample_num), price(period_num,sample_num),&
     q(period_num,sample_num), qdef, b_zero,  p_shock(period_num,sample_num),tb(period_num,sample_num), y(period_num,sample_num), &
     q_default_free(period_num,sample_num), aux_real,  q_default_free_new(period_num,sample_num), gdp(period_num,sample_num)
INTEGER :: d(period_num, sample_num), excl(period_num,sample_num)
DOUBLE PRECISION, EXTERNAL:: q_fun, q_def_free_fun



b_zero = 0d+0  !IF THE COUNTRY IS NOT EXCLUDED AFTER A DEFAULT EPISODE ==> BORROWS AS IF IT STARTS WITH ZERO DEBT


CALL init_random_seed()         ! see example of RANDOM_SEED
CALL RANDOM_NUMBER(random_vector)
CALL RANDOM_NUMBER(random_vector_rw)

!First column of random_matrix is used to generate transitory shocks.
!Second column of random_matrix is used to generate type changes.
do j=1,sample_num
   do i=1,period_num
      random_matrix(i,j,1)=random_vector((j-1)*period_num+i)
      random_matrix(i,j,2)=random_vector(period_num*sample_num + (j-1)*period_num+i)

   end do
end do

!First column of random_matrix_rw is used to generate oil price level shocks
!Second column of random_matrix_rw is used to generate oil price volatility shocks.
!These are drawn PER SAMPLE: without the j dimension every simulated panel would
!share one identical oil-price path, so cross-sample averaging would not reduce
!price-shock sampling error at all.
do j=1,sample_num
   do i=1,period_num
      random_matrix_rw(i,j,1)=random_vector_rw((j-1)*period_num+i)
      random_matrix_rw(i,j,2)=random_vector_rw(period_num*sample_num + (j-1)*period_num+i)
   end do
end do


   open (UNIT=23, FILE="graphs_data_sim_dss.txt", status = 'replace')
   open (UNIT=24, FILE="graphs_def_per_dss.txt", status = 'replace')
   open (UNIT=25, FILE="graphs_param_dss.txt", status = 'replace')
   open (UNIT=26, FILE="graphs_def_num_dss.txt", status = 'replace')
!    open (UNIT=50, FILE="dy.txt", status = 'replace')
!    open (UNIT=51, FILE="s.txt", status = 'replace')
!    open (UNIT=52, FILE="sg.txt", status = 'replace')
!    open (UNIT=53, FILE="q_sim.txt", status = 'replace')
!    open (UNIT=54, FILE="q_default_free.txt", status = 'replace')


WRITE(25, '(I10)') period_num-1
WRITE(25, '(I10)') sample_num
CLOSE(25)

! !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
i_default_global = 1  !USED TO INVOKE WHICH CHEBYCHEV MATRIX TO USE

do j=1,sample_num   !SOLVE FOR SAMPLE j
   WRITE(*, *) j
   aux_real = y_num/2d+0
   i_y_previous = floor(aux_real)

   if (p_vol_num < 2) then
      i_p_vol_previous = 1

      if(p_num < 2) then
         i_p_previous = 1
      else
         aux_real = p_num/2d+0
         i_p_previous = floor(aux_real)
      end if

   else

      aux_real = p_vol_num/2d+0
      i_p_vol_previous =floor(aux_real)

      aux_real = p_num/2d+0
      i_p_previous = floor(aux_real)
   end if


   z_shock(1,j) = y_grid(i_y_previous)
   p(1,j) = exp(p_grid(i_p_previous, i_p_vol_previous))
   p_vol_matrix(1,j) = p_vol_grid(i_p_vol_previous)
   y(1,j) = scale_y*exp(z_shock(1,j))
   b(1,j) = zero
   i_b_next = b_next_matrix(i_b_zero, i_y_previous,i_p_previous, i_p_vol_previous)
   b(2,j) = b_grid(i_b_next)
   d(1,j) = 1    !NO DEFAULT IN FIRST PERIOD
   excl(1,j) = 1 !NO EXCLUSION IN FIRST PERIOD
   default_num =0  !variable that counts the number of defaults in each sample.


   do i=2,period_num

      qdef = 0d+0

      i_y_current = 1
      do WHILE(cdf_matrix(i_y_previous, i_y_current) < random_matrix(i,j,1))
         i_y_current = i_y_current + 1
      end do

      i_y_previous = i_y_current
      z_shock(i,j) = y_grid(i_y_current)

!THE FOLLOWING 4 LINES ARE A WAY OF GETTING A RANDOM DRAW FOR THE INTEREST SHOCK
      i_p_vol_current = 1
      do WHILE(cdf_matrix_p_vol(i_p_vol_previous, i_p_vol_current) < random_matrix_rw(i,j,2))
         i_p_vol_current = i_p_vol_current + 1
      end do
      i_p_vol_previous = i_p_vol_current

      i_p_current = 1
      do WHILE(cdf_matrix_p(i_p_previous, i_p_current,i_p_vol_current) < random_matrix_rw(i,j,1))
         i_p_current = i_p_current + 1
      end do
      i_p_previous = i_p_current
      p(i,j) = exp(p_grid(i_p_current, i_p_vol_current))
      p_vol_matrix(i,j) = p_vol_grid(i_p_vol_current)

      i_b_current = i_b_next  !CURRENT INDEX OF ASSET = PREVIOUS INDEX OF SAVING
      y_initial = z_shock(i,j)
      b_initial = b(i,j)



      if (excl(i-1,j) ==2 ) THEN  !COUNTRY WAS EXCLUDED IN THE PREVIOUS PERIOD

         if (random_matrix(i,j,2) < prob_excl_end) THEN  ! EXCLUSION ENDS THIS PERIOD
            d(i,j) = 1   !COUNTRY DOES NOT DEFAULT
            excl(i,j) = 1
            i_b_next = b_next_matrix(i_b_current, i_y_current, i_p_current, i_p_vol_current)
            b(i+1,j) = b_grid(i_b_next)
            q(i,j) = q_fun(i_b_next, i_y_current, i_p_current, i_p_vol_current)
            y(i,j) = scale_y*exp(z_shock(i,j))
            ! Allocations are indexed by the debt the country ENTERS with (i_b_current),
            ! not by the debt it chooses for next period (i_b_next): see c0_matrix at the
            ! b_initial = b_grid(i_b) definition in `iterate`.
            oil(i,j)=oil_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)
            gdp(i,j)=output_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)
            c(i,j)=c_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)
            tb(i,j) = gdp(i,j)-c(i,j)

            q_default_free(i,j) = q_nodef(i_y_current,i_p_current, i_p_vol_current)
            q_default_free_new(i,j) = q_def_free_fun(i_y_current,i_p_current, i_p_vol_current)
            price(i,j)=exp(p_grid(i_p_current, i_p_vol_current))
            vol(i,j)=p_vol_grid(i_p_vol_current)

         else ! EXCLUSION DOES NOT END THIS PERIOD
            d(i,j) = 1
            excl(i,j) = 2
            i_b_next = i_b_zero
            b(i+1,j) = b_grid(i_b_next)
            q(i,j) = q_fun(i_b_next, i_y_current,i_p_current, i_p_vol_current)
            y(i,j) = scale_y*(EXP(z_shock(i,j))  - defloss(z_shock(i,j), p_grid(i_p_current, i_p_vol_current)))
            ! Country is in autarky this period, so its allocation is the default-state
            ! one, which depends on (y,p,sigma) only. c_matrix/oil_matrix/output_matrix
            ! at a zero-debt index would return the REPAY allocation (incl. new bond
            ! proceeds) and overstate consumption.
            gdp(i,j)=output1_matrix(i_y_current,i_p_current, i_p_vol_current)
            oil(i,j)=oil1_matrix(i_y_current,i_p_current, i_p_vol_current)
            c(i,j)=c1_matrix(i_y_current,i_p_current, i_p_vol_current)
            price(i,j)=exp(p_grid(i_p_current, i_p_vol_current))
            vol(i,j)=p_vol_grid(i_p_vol_current)


            tb(i,j) = gdp(i,j)-c(i,j)


            q_default_free(i,j) = q_nodef(i_y_current, i_p_current, i_p_vol_current)
            q_default_free_new(i,j) = q_def_free_fun(i_y_current, i_p_current, i_p_vol_current)
         end if

      else !COUNTRY WAS NOT EXCLUDED IN THE PREVIOUS PERIOD

         !WRITE(nout, '(F12.8, X, F12.8, X, F12.8, X, F12.8)') b_initial, v_no_def, v_def, 100*random_matrix(i,j,1)
         if (default_decision(i_b_current, i_y_current,i_p_current, i_p_vol_current) > 1) then  !COUNTRY DEFAULTS
            d(i,j) = 2
            excl(i,j) = 2
            i_b_next = i_b_zero
            b(i+1,j) = b_grid(i_b_next)
            q(i,j) = q_fun(i_b_next, i_y_current,i_p_current, i_p_vol_current)  !q_paid
            y(i,j) = scale_y*(EXP(z_shock(i,j))  - defloss(z_shock(i,j), p_grid(i_p_current, i_p_vol_current)))
            ! Default is chosen at (i_b_current,...), so c_matrix/oil_matrix/output_matrix
            ! there already hold the autarky (c1/oil1/output1) values. Indexing by
            ! i_b_next (= zero debt) would instead return the repay allocation.
            gdp(i,j)=output_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)
            oil(i,j)=oil_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)
            c(i,j)=c_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)

           tb(i,j) = gdp(i,j)-c(i,j)
           price(i,j)=exp(p_grid(i_p_current, i_p_vol_current))
            vol(i,j)=p_vol_grid(i_p_vol_current)



           q_default_free(i,j) = q_nodef(i_y_current, i_p_current, i_p_vol_current)
            q_default_free_new(i,j) = q_def_free_fun(i_y_current, i_p_current, i_p_vol_current)

          qdef = zero
            WRITE(24, '(I10)') i-1 !NEED TO SUBSTRACT 1. REASON: files start saving data on period 2
            default_num = default_num + 1
          else
            d(i,j) = 1   !COUNTRY DOES NOT DEFAULT
            excl(i,j) = 1
            i_b_next = b_next_matrix(i_b_current, i_y_current,i_p_current, i_p_vol_current)
            b(i+1,j) = b_grid(i_b_next)
            !Compute the bond price paid when an amount b_next is issued.
            !the bond price depends on the current default decision and output (both will affect output tomorrow)

             q(i,j) = q_fun(i_b_next, i_y_current,i_p_current, i_p_vol_current)  !q_paid
            y(i,j) = scale_y*exp(z_shock(i,j))
            coupon = (rstar+delta)/(1d+0 +rstar)
            ! Indexed by entering debt (i_b_current), not the newly chosen b' (i_b_next).
            gdp(i,j)=output_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)
            oil(i,j)=oil_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)
            c(i,j)=c_matrix(i_b_current,i_y_current,i_p_current, i_p_vol_current)
            price(i,j)=exp(p_grid(i_p_current, i_p_vol_current))
            vol(i,j)=p_vol_grid(i_p_vol_current)

            tb(i,j) = gdp(i,j)-c(i,j)


            q_default_free(i,j) = q_nodef(i_y_current, i_p_current, i_p_vol_current)
            q_default_free_new(i,j) = q_def_free_fun(i_y_current, i_p_current, i_p_vol_current)



         end if
      end if

      !                  1         2         3         4         5        6       7          8        9                                 10     11         12       13
        WRITE(23, '(F20.8, X, F20.8, X, F20.8, X, F20.8, X, F20.8, X, F20.8, X,  I3, X, &
    I3, X, F20.8, X,  I3, X, F20.8, X, F20.8, X, F20.8, X, F20.8, X, F20.8, X, F20.8, X, I3, X, I3, F20.8, X, F20.8 )') &
 !        1      2       3       4       5     6                             8
      y(i,j), c(i,j), b(i,j), q(i,j), qdef, oil(i,j), &
      !  7       8      9                     10          11                        12            13                14        15
  excl(i,j), d(i,j), q_default_free(i,j),  i_y_current, q_default_free_new(i,j), tb(i,j)/gdp(i,j),  p_vol_matrix(i,j), p(i,j), oil(i,j)*p(i,j)/gdp(i,j), gdp(i,j), i_p_current, i_p_vol_current, price(i,j), vol(i,j)

!    WRITE(21, *) y(i,j), y_poor(i,j), b(i,j), q(i,j), qdef, c(i,j), c_poor(i,j), tb(i,j)/((1-lambda)*y(i,j)+lambda*y_poor), &
!     excl(i,j), d(i,j), q_default_free(i,j), tax(i,j), tax_poor(i,j), i_y_current, expected_SDF_matrix(i_y_current), q_default_free_new(i,j)
!




  end do
       !WRITE(25, '(I6, X, I6)') default_num
   WRITE(26, *) default_num
!
 end do
!
Close(23)
CLOSE(24)
CLOSE(25)
CLOSE(26)




end subroutine simulate




SUBROUTINE init_random_seed()
  INTEGER ::  n
  INTEGER, DIMENSION(:), ALLOCATABLE :: seed

  CALL RANDOM_SEED(size = n)
  ALLOCATE(seed(n))

  seed = 12345
  !          write(*,*) seed,n

  CALL RANDOM_SEED(PUT = seed)

  DEALLOCATE(seed)
END SUBROUTINE init_random_seed


subroutine nprob (z, p, q, pdf)

  implicit none
  DOUBLE PRECISION, parameter :: a0 = 0.5D+00
  DOUBLE PRECISION, parameter :: a1 = 0.398942280444D+00
  DOUBLE PRECISION, parameter :: a2 = 0.399903438504D+00
  DOUBLE PRECISION, parameter :: a3 = 5.75885480458D+00
  DOUBLE PRECISION, parameter :: a4 = 29.8213557808D+00
  DOUBLE PRECISION, parameter :: a5 = 2.62433121679D+00
  DOUBLE PRECISION, parameter :: a6 = 48.6959930692D+00
  DOUBLE PRECISION, parameter :: a7 = 5.92885724438D+00
  DOUBLE PRECISION, parameter :: b0 = 0.398942280385D+00
  DOUBLE PRECISION, parameter :: b1 = 0.000000038052D+00
  DOUBLE PRECISION, parameter :: b2 = 1.00000615302D+00
  DOUBLE PRECISION, parameter :: b3 = 0.000398064794D+00
  DOUBLE PRECISION, parameter :: b4 = 1.98615381364D+00
  DOUBLE PRECISION, parameter :: b5 = 0.151679116635D+00
  DOUBLE PRECISION, parameter :: b6 = 5.29330324926D+00
  DOUBLE PRECISION, parameter :: b7 = 4.8385912808D+00
  DOUBLE PRECISION, parameter :: b8 = 15.1508972451D+00
  DOUBLE PRECISION, parameter :: b9 = 0.742380924027D+00
  DOUBLE PRECISION, parameter :: b10 = 30.789933034D+00
  DOUBLE PRECISION, parameter :: b11 = 3.99019417011D+00
  DOUBLE PRECISION :: p, pdf, q, y, z, zabs

  zabs = abs (z)
  !
  !  |Z| between 0 and 1.28
  !
  if ( abs ( z ) <= 1.28D+00 ) then

     y = a0 * z * z
     pdf = exp ( - y ) * b0

     q = a0 - zabs * ( a1 - a2 * y/( y + a3 - a4/( y + a5 + a6/( y + a7 ))))
     !
     !  |Z| between 1.28 and 12.7
     !
  else if ( abs ( z ) <= 12.7D+00 ) then

     y = a0 * z * z
     pdf = exp ( - y ) * b0

     q = pdf &
          / ( zabs - b1 + b2 &
          / ( zabs + b3 + b4 &
          / ( zabs - b5 + b6 &
          / ( zabs + b7 - b8 &
          / ( zabs + b9 + b10 &
          / ( zabs + b11 ))))))
     !
     !  Z far out in tail.
     !
  else

     q = 0.0D+00
     pdf = 0.0D+00

  end if

  if ( z < 0.0D+00 ) then
     p = q
     q = 1.0D+00 - p
  else
     p = 1.0D+00 - q
  end if

  return
end subroutine nprob






