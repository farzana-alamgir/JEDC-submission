program check
use fixed_policy_pricing
implicit none
integer::nt,ic,nb,ny,np,nh,iterations
integer,allocatable::decision(:,:,:,:)
double precision,allocatable::grid(:),policy(:,:,:,:),ty(:,:),tp(:,:,:),th(:,:),q0(:,:,:,:),q(:,:,:,:),weights(:,:,:,:,:)
double precision::coupon,discount,surviving,tol,r0,rf
logical::ok,has_weights
read(*,*)nt
do ic=1,nt
read(*,*)nb,ny,np,nh,coupon,discount,surviving,tol,has_weights
allocate(grid(nb),policy(nb,ny,np,nh),decision(nb,ny,np,nh),ty(ny,ny),tp(np,np,nh),th(nh,nh),q0(nb,ny,np,nh),q(nb,ny,np,nh))
read(*,*)grid
read(*,*)policy
read(*,*)decision
read(*,*)ty
read(*,*)tp
read(*,*)th
read(*,*)q0
if(has_weights)then
allocate(weights(nb,ny,ny,np,nh))
read(*,*)weights
call solve_fixed_policy_prices(nb,ny,np,nh,grid,policy,decision,ty,tp,th,q0,coupon,discount,surviving,tol,q,r0,rf,iterations,ok,weights)
deallocate(weights)
else
call solve_fixed_policy_prices(nb,ny,np,nh,grid,policy,decision,ty,tp,th,q0,coupon,discount,surviving,tol,q,r0,rf,iterations,ok)
end if
write(*,*)iterations,r0,rf,ok
write(*,'(ES25.16)')q
deallocate(grid,policy,decision,ty,tp,th,q0,q)
end do
end program check
