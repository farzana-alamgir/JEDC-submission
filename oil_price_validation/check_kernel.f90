! Small driver used by validate.py to check Fortran against an independent CDF.
program check_kernel
  use iso_fortran_env, only: real64
  use validated_price_kernel, only: build_kernel
  implicit none
  integer :: nz,nh,i,j,k,l
  real(real64) :: center,rp,mh,rh,eh
  real(real64), allocatable :: z(:),h(:),s(:,:),p(:,:,:)
  read(*,*) nz,nh
  read(*,*) center,rp,mh,rh,eh
  allocate(z(nz),h(nh),s(nh,nh),p(nz,nz,nh))
  read(*,*) z
  read(*,*) h
  call build_kernel(z,h,center,rp,mh,rh,eh,s,p)
  do k=1,nh
    do l=1,nh
      write(*,'(ES26.17E3)') s(k,l)
    end do
  end do
  do l=1,nh
    do i=1,nz
      do j=1,nz
        write(*,'(ES26.17E3)') p(i,j,l)
      end do
    end do
  end do
end program
