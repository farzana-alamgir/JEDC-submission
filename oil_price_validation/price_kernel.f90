! Standalone oil-price kernel. This module does not solve the sovereign model.
! h is LOG VARIANCE, so the price innovation standard deviation is exp(h/2).
! Timing: draw h' first, then z' = center + rho_p*(z-center) + exp(h'/2)*u.
module validated_price_kernel
  use iso_fortran_env, only: real64
  implicit none
  private
  public :: build_kernel
contains
  pure real(real64) function normal_cell(lo, hi) result(prob)
    real(real64), intent(in) :: lo, hi
    real(real64), parameter :: root2 = sqrt(2.0_real64)
    if (lo >= 0.0_real64) then
      prob = 0.5_real64 * (erfc(lo/root2) - erfc(hi/root2))
    else
      prob = 0.5_real64 * (erfc(-hi/root2) - erfc(-lo/root2))
    end if
    prob = max(0.0_real64, prob)
  end function

  subroutine edges(grid, bounds)
    real(real64), intent(in) :: grid(:)
    real(real64), intent(out) :: bounds(size(grid)+1)
    integer :: j, n
    n = size(grid)
    ! Finite surrogates for infinity avoid overflow when dividing by small scales.
    bounds(1) = -1.0e100_real64
    bounds(n+1) = 1.0e100_real64
    do j=2,n
      bounds(j) = 0.5_real64*(grid(j-1)+grid(j))
    end do
  end subroutine

  subroutine build_kernel(z, h, center, rho_p, mu_h, rho_h, eta_h, s, p)
    real(real64), intent(in) :: z(:), h(:), center, rho_p, mu_h, rho_h, eta_h
    real(real64), intent(out) :: s(size(h),size(h)), p(size(z),size(z),size(h))
    real(real64) :: ze(size(z)+1), he(size(h)+1), location, scale
    integer :: i,j,k,l
    if (size(z)<2 .or. size(h)<2) error stop 'At least two nodes required'
    if (any(z(2:)<=z(:size(z)-1))) error stop 'Price grid must increase'
    if (any(h(2:)<=h(:size(h)-1))) error stop 'Volatility grid must increase'
    if (abs(rho_p)>=1 .or. abs(rho_h)>=1 .or. eta_h<=0) error stop 'Invalid parameters'
    call edges(z,ze)
    call edges(h,he)
    do k=1,size(h)
      location = mu_h + rho_h*(h(k)-mu_h)
      do l=1,size(h)
        s(k,l) = normal_cell((he(l)-location)/eta_h,(he(l+1)-location)/eta_h)
      end do
    end do
    do l=1,size(h)
      scale = exp(h(l)/2.0_real64)
      do i=1,size(z)
        location = center + rho_p*(z(i)-center)
        do j=1,size(z)
          p(i,j,l) = normal_cell((ze(j)-location)/scale,(ze(j+1)-location)/scale)
        end do
      end do
    end do
    ! Joint probability: K((i,k),(j,l)) = s(k,l)*p(i,j,l).
    ! The SAME z grid applies to every volatility regime.
  end subroutine
end module
