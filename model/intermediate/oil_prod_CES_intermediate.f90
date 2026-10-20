!**************************************************************************************************
!cd /Users/farzanaalamgir/code/JEDC_submission/model/intermediate

! gfortran -O3 -march=native oil_prod_CES_intermediate.f90 -o oil_prod_CES_intermediate
!
! ./oil_prod_CES_intermediate
! INCLUDE 'link_fnl_static.h'  ! COMMENTED OUT - IMSL library not needed

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
     prob_excl_end =0.0833d+0, std_eps = 0.03d+0, rho = 0.9d+0, beta=0.96, alpha=0.3, theta=0.5,&          !A-m has been changed in order to capture the new specification of stealing function
     mean_y = -0.5d+0*std_eps**2,delta = 0.03d+0,  m=4d+0, scale_y=10d+0, d0= -0.246, d1=0.37, mmax_global=100d+0,&
     std_u_p = 1d+0, std_u_vol= 0d+0, rho_p = 0.98d+0, rho_p_vol = 0.66d+0 ,pprime=3.97d+0,mean_p = 0.12d+0, mean_p_vol = -4.33d+0, eta = 0.44d+0)

CHARACTER(LEN = 10) :: outFormat

! parameter (sigma = 2d+0, pi_number = 3.1415926535897932d+0, zero = 0d+0,  width = 1.5d+0,  rstar = 0.01d+0, kappa=0, epsilon=5.2, &
!      prob_excl_end =0.0385d+0, std_eps = 0.03d+0, rho = 0.9d+0, beta=0.97, tax_rate=1d+0, gamma=1.06, monitoring=2.64, A_m=0,theta=0.01,&             !A-m has been changed in order to capture the new specification of stealing function
!      mean_y = -0.5d+0*std_eps**2,delta = 0.07d+0, cost=0.92d+0, m=4d+0, monitoring_in_bc=0, scale_y=10d+0, d0= -0.15, d1=0.25,&
!      std_u_p = 1d+0, std_u_vol= 1d+0, rho_p = 0.98d+0, rho_p_vol = 0.66d+0, mean_p = 0.12d+0, mean_p_vol = -4.33d+0, eta = 0.49d+0)


INTEGER :: b_num, y_num, quad_num, nout, i_y_global, i_excl_global, p_num, p_vol_num,&
     i_b_global, i_default_global, indicator_2, i_b_next, i_b_zero, b_num_interm, counter


parameter (b_num= 100, y_num = 21, p_num=7, p_vol_num=1)
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

DOUBLE PRECISION, DIMENSION (y_num, p_num, p_vol_num) :: q_def_free_paid_matrix

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

!-----------------------------------------------------
! Bisection
!-----------------------------------------------------

function func_m(y_initial,p_initial)
!DOUBLE PRECISION function func_m(x)

implicit none
double precision, parameter :: tol_bi=1e-2
integer, parameter :: itmax_bi=5000
!double precision, intent(in):: x1,x2
double precision, intent(in):: p_initial, y_initial
double precision:: d_bi, m_opt, mmin, mmax,func_m,A
integer :: iter_bi

!Initializing
mmin = 1e-16
mmax = mmax_global
d_bi = 1.
iter_bi =0
! p_initial=x1
! y_initial=x2
 A=(1d+0 - default_grid(i_excl_global)) * scale_y*EXP(y_initial) + &
           default_grid(i_excl_global) * scale_y*(EXP(y_initial)  - max(zero, d0*EXP(y_initial) + d1*EXP(y_initial)**2))
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

do while(iter_bi .le. itmax_bi .and. d_bi .ge. tol_bi)
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

if (d_bi .ge. tol_bi) then
print *, 'iterations exceeded at bisection'
print*, 'd_bi', d_bi
call exit
end if


end function func_m


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
    variance_p_innovation3, variance_p_innovation4, variance_p_innovation5

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
    !call tauchen(y_num,rho, zero, variance_y,m, y_grid, trans_matrix)
    call tauchen(p_vol_num,rho_p_vol, mean_p_vol, variance_p_vol,m, p_vol_grid, trans_matrix_p_vol)

   call discretize_AR(rho_p_vol, mean_p_vol , variance_p_vol, p_vol_grid, trans_matrix_p_vol_AR, prob_vector_p_vol)

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
      p_grid = mean_p
      trans_matrix_p = 1d+0
      cdf_matrix_p= 1d+0
      prob_vector_p= 1d+0

      variance_p_level_epsilon_tomorrow = 0d+0
   else

      scale_int = exp(0.5d+0 * eta**(2d+0)/(1d+0 - rho_p_vol**(2d+0)))
      variance_p_innovation = (std_u_p * exp(mean_p_vol) * scale_int)**(2d+0)
      ! scale_int is the fix for the Jensen's inequality

      !call tauchen(y_num,rho, zero, variance_y,m, y_grid, trans_matrix)
    call tauchen(p_num,rho_p, mean_p, variance_p_innovation, m, p_grid(:, 1), trans_matrix_p(:,:,1))
     call discretize_AR(rho_p, mean_p , variance_p_innovation, p_grid(:, 1), trans_matrix_p_AR(:,:,1), prob_vector_p(:,1))

      variance_p_level_epsilon_tomorrow = variance_p_innovation
      !variance_r_level_epsilon_tomorrow is the conditional variance of innovations to the world interest rate *tomorrow*, conditional on
      !observing the \sigma_r today.

   end if

else

   do i=1,p_vol_num
      variance_p_innovation = (std_u_p * exp(p_vol_grid(i)))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
       !call tauchen(p_num,rho_p, mean_p, variance_p_innovation, m, p_grid(:, i), trans_matrix_p(:,:,i))
      call discretize_AR(rho_p, mean_p , variance_p_innovation, p_grid(:, i), trans_matrix_p(:,:,i), prob_vector_p(:,i))
   end do

 !! Creating price grid for different levels of volatilities:
 ! vol_grid=1
 do i=1,p_vol_num
      variance_p_innovation1 = (std_u_p * exp(p_vol_grid(i)))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
      ! call tauchen(p_num,rho_p, mean_p, variance_p_innovation1, m, p_grid_1(:, i), trans_matrix_p_1(:,:,i))
      call discretize_AR(rho_p, mean_p , variance_p_innovation1, p_grid_1(:, i), trans_matrix_p_1(:,:,i), prob_vector_p_1(:,i))
   end do

 !vol_grid=2
 do i=1,p_vol_num
      variance_p_innovation2 = (std_u_p * exp(p_vol_grid(2)))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
      ! call tauchen(p_num,rho_p, mean_p, variance_p_innovation2, m, p_grid_2(:, i), trans_matrix_p_2(:,:,2))
      call discretize_AR(rho_p, mean_p , variance_p_innovation2, p_grid_2(:, i), trans_matrix_p_2(:,:,i), prob_vector_p_2(:,i))
   end do

 !vol_grid=3
do i=1,p_vol_num
      variance_p_innovation3 = (std_u_p * exp(p_vol_grid(3)))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
      ! call tauchen(p_num,rho_p, mean_p, variance_p_innovation3, m, p_grid_3(:, i), trans_matrix_p_3(:,:,3))
      call discretize_AR(rho_p, mean_p , variance_p_innovation3, p_grid_3(:, i), trans_matrix_p_3(:,:,i), prob_vector_p_3(:,i))
   end do

!vol_grid=4
do i=1,p_vol_num
      variance_p_innovation4 = (std_u_p * exp(p_vol_grid(4)))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
       !call tauchen(p_num,rho_p, mean_p, variance_p_innovation4, m, p_grid_4(:, i), trans_matrix_p_4(:,:,4))
      call discretize_AR(rho_p, mean_p , variance_p_innovation4, p_grid_4(:, i), trans_matrix_p_4(:,:,i), prob_vector_p_4(:,i))
   end do

 !vol_grid=5
 do i=1,p_vol_num
      variance_p_innovation5 = (std_u_p * exp(p_vol_grid(5)))**(2)
      ! This is ok, because it's the conditional variance of the innovations to epsilon_r in period t, conditional on observing a realization
      ! of the volatility in that period (r_vol_grid(i) .or. \sigma_{r,t} using the model's notation).
      ! call tauchen(p_num,rho_p, mean_p, variance_p_innovation5, m, p_grid_5(:, i), trans_matrix_p_5(:,:,5))
      call discretize_AR(rho_p, mean_p , variance_p_innovation5, p_grid_5(:, i), trans_matrix_p_5(:,:,i), prob_vector_p_5(:,i))
   end do

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

         argument = rstar

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

         argument = rstar

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
DOUBLE PRECISION ::exp_v_next, exp_v_excl, q, output, consumption, oil_spending,TFP
DOUBLE PRECISION, EXTERNAL:: u_fun, q_fun

exp_v_next = exp_v_vector(i_b_next)      !0d+0
exp_v_excl = exp_v_excl_vector(i_b_next) !0d+0

d  = i_default_global
q = q_vector(i_b_next)


 TFP = (1d+0 - default_grid(i_excl_global)) * scale_y*EXP(y_initial) + &
          default_grid(i_excl_global) * scale_y*(EXP(y_initial)  - max(zero, d0*EXP(y_initial) + d1*EXP(y_initial)**2))
         ! print*,'TFP_objective', TFP
!oil_spending= TFP*(alpha/exp(p_initial))**(1/(1-alpha))
oil_spending=func_m(y_initial,p_initial)
!print*, 'oil_spending', oil_spending
output=((1-alpha)*TFP**theta+alpha*oil_spending**theta)**(1./theta)

consumption=output-oil_spending*exp(p_initial)-(b_initial *coupon - q * (b-(1d+0 - delta)*b_initial) )*(1-default_grid(i_excl_global))


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
                    exp_v_excl, exp_v_next, q_def_free_paid_matrix_new(y_num, p_num,p_vol_num), c1_matrix(y_num, p_num,p_vol_num),&
                    output1_matrix(y_num, p_num,p_vol_num), oil1_matrix(y_num, p_num,p_vol_num),TFP1_matrix(y_num, p_num,p_vol_num)

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

do i_p_vol = 1,p_vol_num
      do i_p = 1,p_num
      p_initial=p_grid(i_p,i_p_vol)
     ! print*, 'p_initial-ITERATE', p_initial
         do i_y = 1,y_num
            i_y_global = i_y
            y_initial = y_grid(i_y)

! HERE WE COMPUTE THE EXPECTED VALUE FUNCTIONS, AND ALSO THE PRICE FOR EACH POSSIBLE LEVEL OF B_NEXT
            do i_b_prime = 1,b_num
               exp_v_excl = 0d+0
               exp_v_next = 0d+0
               do i_p_vol_next =1,p_vol_num
                  do i_p_next = 1,p_num
                     do i_y_next=1,y_num
                        expectation=trans_matrix_p_vol(i_p_vol, i_p_vol_next)*trans_matrix_p(i_p, i_p_next, i_p_vol_next)
                        exp_v_next = exp_v_next + trans_matrix_p_vol(i_p_vol, i_p_vol_next)*&
                        trans_matrix_p(i_p, i_p_next, i_p_vol_next)*trans_matrix(i_y_global, i_y_next)*&
                        v_matrix(i_b_prime, i_y_next, i_p_next, i_p_vol_next)

                        exp_v_excl = exp_v_excl + trans_matrix_p_vol(i_p_vol, i_p_vol_next)*&
                        trans_matrix_p(i_p, i_p_next, i_p_vol_next)* trans_matrix(i_y_global, i_y_next)*&
                        v1_matrix(i_y_next, i_p_next, i_p_vol_next)
                     end do
                     end do
               end do

               exp_v_vector(i_b_prime) = exp_v_next
               exp_v_excl_vector(i_b_prime) = exp_v_excl
               q_vector(i_b_prime) = q_fun(i_b_prime, i_y_global,i_p, i_p_vol)

            end do


! NOW, COMPUTE THE VALUE FUNCTION OF DEFAULT (WHICH DEPENDS ONLY ON INCOME)

            i_default_global=2 !Country defaults
            i_excl_global=2

            i_b_next = i_b_zero
            i_b_optimal1 = i_b_zero
            b_next   = b_grid(i_b_next)
            v1_matrix_new(i_y, i_p, i_p_vol) = objective_function(b_next)

            TFP1_matrix(i_y, i_p, i_p_vol)= scale_y*(EXP(y_initial)  - max(zero, d0*EXP(y_initial) + d1*EXP(y_initial)**2))
            oil1_matrix(i_y, i_p, i_p_vol)=func_m(y_initial,p_initial)
            output1_matrix(i_y, i_p, i_p_vol)=(((1.-alpha)*TFP1_matrix(i_y, i_p, i_p_vol)**theta)+(alpha*oil1_matrix(i_y, i_p, i_p_vol)**theta))**(1./theta)

            c1_matrix(i_y, i_p, i_p_vol) = output1_matrix(i_y, i_p, i_p_vol)-EXP(p_initial)*oil1_matrix(i_y, i_p, i_p_vol)

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
               (1d+0 - delta)*b_initial)* q_fun(i_b_optimal0, i_y,i_p,i_p_vol)-exp(p_initial)*oil0_matrix(i_b, i_y, i_p, i_p_vol)
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


                  q_paid_matrix_new(i_b, i_y,i_p, i_p_vol) =  q_fun( i_b_optimal0, i_y,i_p, i_p_vol)
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


               WRITE(11, '(F15.11)') q_fun(i_b, i_y,i_p, i_p_vol)

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
SDF_matrix(y_num,p_num, p_vol_num, y_num, p_num, p_vol_num), argument
INTEGER :: i_y, i_p, i_p_vol, i_y_next, i_p_vol_next, i_p_next

! 1. First, compute the SDF_matrix
do i_p_vol = 1,p_vol_num
   do i_p = 1,p_num
      do i_y = 1,y_num
         y_initial = y_grid(i_y)

         do i_p_vol_next = 1,p_vol_num
            do i_p_next = 1,p_num
               do i_y_next = 1,y_num

                  argument = (rstar)

                  SDF_matrix(i_y_next,i_p_next,i_p_vol_next,i_y,i_p,i_p_vol)= EXP(-argument)

               end do
            end do
         end do
      end do
   end do
end do

!1.5 Intermediate step: compute the Expected SDF (I don't need it here, but I wanted for the simulations)
expected_SDF_matrix(i_y, i_p, i_p_vol) = 0d+0

do i_p_vol = 1,p_vol_num
   do i_p = 1,p_num
      do i_y = 1,y_num
         y_initial = y_grid(i_y)
         do i_p_vol_next = 1,p_vol_num
            do i_p_next = 1,p_num
               do i_y_next = 1,y_num
                 expected_SDF_matrix(i_y, i_p, i_p_vol) = expected_SDF_matrix(i_y, i_p, i_p_vol) + &
                 SDF_matrix(i_y_next,i_p_next,i_p_vol_next,i_y,i_p, i_p_vol) *&
                 trans_matrix_p_vol(i_p_vol, i_p_vol_next)* trans_matrix_p(i_p, i_p_next, i_p_vol_next)*&
                 trans_matrix(i_y, i_y_next)
               end do
            end do
         end do
      end do
   end do
end do


!2. Iterate on the q_nodef

dev = 10d+0
criterion_q_nodef = 1d-6
q_nodef = 0d+0

do while(dev > criterion_q_nodef)
   q_nodef_new = 0d+0
   dev = 0d+0
   !calculate long-term bond price

   do i_p_vol = 1,p_vol_num
      do i_p = 1,p_num
         do i_y = 1,y_num
            y_initial = y_grid(i_y)
            do i_p_vol_next = 1,p_vol_num
               do i_p_next = 1,p_num
                  do i_y_next = 1,y_num
                     coupon_nodef = (rstar + delta )/ (1d+0 + rstar)

                     q_nodef_new(i_y, i_p, i_p_vol) = q_nodef_new(i_y, i_p, i_p_vol) + &
                     SDF_matrix(i_y_next,i_p_next,i_p_vol_next,i_y,i_p, i_p_vol) *&
                     (coupon_nodef+(1d+0-delta)*q_nodef(i_y_next,i_p_next,i_p_vol_next))*&
                     trans_matrix_p_vol(i_p_vol, i_p_vol_next)*&
                     trans_matrix_p(i_p, i_p_next, i_p_vol_next)*trans_matrix(i_y, i_y_next)
                  end do
               end do
            end do
            dev = max(abs(q_nodef_new(i_y,i_p,i_p_vol)-q_nodef(i_y,i_p,i_p_vol)), dev)

         end do
      end do
   end do
   q_nodef = q_nodef_new

end do

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

do i_p_vol = 1,p_vol_num
   do i_p = 1,p_num
      do i_y = 1,y_num
         do i_p_vol_next = 1,p_vol_num
            do i_p_next = 1,p_num
               do i_y_next = 1,y_num

                  write(20, *) SDF_matrix(i_y_next,i_p_next,i_p_vol_next,i_y,i_p, i_p_vol)

               end do
            end do
         end do
      end do
   end do
end do

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
        TFP1(i_y,i_p,i_p_vol)=scale_y*(EXP(y_initial)  - max(zero, d0*EXP(y_initial) + d1*EXP(y_initial)**2))
        !print*, 'TFP1(i_y,i_p,i_p_vol)', TFP1(i_y,i_p,i_p_vol)
        m1(i_y,i_p,i_p_vol)=func_m(y_initial,p_initial)
       !m1(i_y,i_p,i_p_vol)=0d+0
        !print*, 'm1(i_y,i_p,i_p_vol)',m1(i_y,i_p,i_p_vol)
       !v1_matrix(i_y,i_p,i_p_vol) = u_fun((alpha**(alpha-(1/(1-alpha))))*(alpha*TFP1(i_y,i_p,i_p_vol)/(exp(p_initial)**alpha))**(1./(1-alpha)))
       v1_matrix(i_y,i_p,i_p_vol)=u_fun(((1-alpha)*TFP1(i_y,i_p,i_p_vol)**theta+alpha*m1(i_y,i_p,i_p_vol)**theta)**(1./theta)-&
       m1(i_y,i_p,i_p_vol)*exp(p_initial))
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
      random_matrix_rw(period_num, 2), random_vector_rw(1:2*period_num),p(period_num,sample_num), p_vol_matrix(period_num,sample_num), &
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

!First column of random_matrix is used to generate rw level shocks
!Second column of random_matrix is used to generate rw volatility shocks.
do i=1,period_num
   random_matrix_rw(i,1)=random_vector_rw(i)
   random_matrix_rw(i,2)=random_vector_rw(period_num+i)
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
      do WHILE(cdf_matrix_p_vol(i_p_vol_previous, i_p_vol_current) < random_matrix_rw(i,2))
         i_p_vol_current = i_p_vol_current + 1
      end do
      i_p_vol_previous = i_p_vol_current

      i_p_current = 1
      do WHILE(cdf_matrix_p(i_p_previous, i_p_current,i_p_vol_current) < random_matrix_rw(i,1))
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
            oil(i,j)=oil_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            gdp(i,j)=output_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            c(i,j)=c_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
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
            y(i,j) = scale_y*(EXP(z_shock(i,j))  - max(zero, d0*EXP(z_shock(i,j)) + d1*EXP(z_shock(i,j))**2))
            gdp(i,j)=output_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            oil(i,j)=oil_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            c(i,j)=c_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
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
            y(i,j) = scale_y*(EXP(z_shock(i,j))  - max(zero, d0*EXP(z_shock(i,j)) + d1*EXP(z_shock(i,j))**2))
            gdp(i,j)=output_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            oil(i,j)=oil_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            c(i,j)=c_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)

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
            gdp(i,j)=output_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            oil(i,j)=oil_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            c(i,j)=c_matrix(i_b_next,i_y_current,i_p_current, i_p_vol_current)
            price(i,j)=exp(p_grid(i_p_current, i_p_vol_current))
            vol(i,j)=p_vol_grid(i_p_vol_current)

            tb(i,j) = gdp(i,j)-c(i,j)


            q_default_free(i,j) = q_nodef(i_y_current, i_p_current, i_p_vol_current)
            q_default_free_new(i,j) = q_def_free_fun(i_y_current, i_p_current, i_p_vol_current)



         end if
      end if

      !                  1         2         3         4         5        6       7          8        9                                 10     11         12       13
        WRITE(23, '(F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X,  I3, X, &
    I3, X, F12.8, X,  I3, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X, F12.8, X, I3, X, I3, F12.8, X, F12.8 )') &
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






