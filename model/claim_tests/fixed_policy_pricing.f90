module fixed_policy_pricing
use, intrinsic :: ieee_arithmetic, only:ieee_is_finite
implicit none
contains
subroutine apply_policy_price(nb,ny,np,nh,ty,tp,th,decision,left,weight,q,coupon,discount,surviving,include_coupon,out,src,a,b,repay_weights,no_interpolation)
integer,intent(in)::nb,ny,np,nh,decision(nb,ny,np,nh),left(nb,ny,np,nh)
double precision,intent(in)::ty(ny,ny),tp(np,np,nh),th(nh,nh),weight(nb,ny,np,nh),q(nb,ny,np,nh),coupon,discount,surviving
logical,intent(in)::include_coupon
double precision,intent(out)::out(nb,ny,np,nh)
double precision,intent(inout)::src(nb,ny,np,nh),a(nb,ny,np,nh),b(nb,ny,np,nh)
double precision,intent(in),optional::repay_weights(nb,ny,ny,np,nh)
logical,intent(in),optional::no_interpolation
logical::interpolate
integer::ib,iy,ip,iv,iyn,ivn,j
double precision::w,payoff,constant
constant=0d0
interpolate=.true.
if(present(no_interpolation))interpolate=.not.no_interpolation
if(include_coupon)constant=coupon
do iv=1,nh
do ip=1,np
do iy=1,ny
do ib=1,nb
 src(ib,iy,ip,iv)=0d0
 if(present(repay_weights).or.decision(ib,iy,ip,iv)==1)then
  if(interpolate)then
   j=left(ib,iy,ip,iv);w=weight(ib,iy,ip,iv)
   payoff=(1d0-w)*q(j,iy,ip,iv)+w*q(j+1,iy,ip,iv)
  else
   payoff=q(ib,iy,ip,iv)
  end if
  src(ib,iy,ip,iv)=discount*(constant+surviving*payoff)
 end if
end do
end do
end do
end do
do iv=1,nh
 do ip=1,np
  do iy=1,ny
   a(:,iy,ip,iv)=0d0
   do iyn=1,ny
    if(present(repay_weights))then
     a(:,iy,ip,iv)=a(:,iy,ip,iv)+repay_weights(:,iy,iyn,ip,iv)*src(:,iyn,ip,iv)
    else
     a(:,iy,ip,iv)=a(:,iy,ip,iv)+ty(iy,iyn)*src(:,iyn,ip,iv)
    end if
   end do
  end do
 end do
 call dgemm('N','T',nb*ny,np,np,1d0,a(1,1,1,iv),nb*ny,tp(1,1,iv),np,0d0,b(1,1,1,iv),nb*ny)
end do
out=0d0
do iv=1,nh
 do ivn=1,nh
  out(:,:,:,iv)=out(:,:,:,iv)+th(iv,ivn)*b(:,:,:,ivn)
 end do
end do
end subroutine apply_policy_price

subroutine solve_fixed_policy_prices(nb,ny,np,nh,grid,policy,decision,ty,tp,th,qinitial,coupon,discount,surviving,tolerance, &
 qsolution,initial_residual,final_residual,iterations,success,repay_weights)
integer,intent(in)::nb,ny,np,nh,decision(nb,ny,np,nh)
double precision,intent(in)::grid(nb),policy(nb,ny,np,nh),ty(ny,ny),tp(np,np,nh),th(nh,nh),qinitial(nb,ny,np,nh)
double precision,intent(in)::coupon,discount,surviving,tolerance
double precision,intent(out)::qsolution(nb,ny,np,nh),initial_residual,final_residual
integer,intent(out)::iterations
logical,intent(out)::success
double precision,intent(in),optional::repay_weights(nb,ny,ny,np,nh)
integer,allocatable::left(:,:,:,:)
double precision,allocatable::weight(:,:,:,:),r(:,:,:,:),rhat(:,:,:,:),p(:,:,:,:),v(:,:,:,:),s(:,:,:,:),t(:,:,:,:)
double precision,allocatable::src(:,:,:,:),a(:,:,:,:),b(:,:,:,:)
double precision::rho,rho_old,alpha,omega,beta_k,denom,tt,db,qbound
integer::ib,iy,ip,iv,j,it,fallback
allocate(left(nb,ny,np,nh),weight(nb,ny,np,nh),r(nb,ny,np,nh),rhat(nb,ny,np,nh),p(nb,ny,np,nh),v(nb,ny,np,nh), &
 s(nb,ny,np,nh),t(nb,ny,np,nh),src(nb,ny,np,nh),a(nb,ny,np,nh),b(nb,ny,np,nh))
db=grid(2)-grid(1)
do iv=1,nh
do ip=1,np
do iy=1,ny
do ib=1,nb
 j=max(1,min(nb-1,int((policy(ib,iy,ip,iv)-grid(1))/db)+1))
 left(ib,iy,ip,iv)=j
 weight(ib,iy,ip,iv)=max(0d0,min(1d0,(policy(ib,iy,ip,iv)-grid(j))/(grid(j+1)-grid(j))))
end do
end do
end do
end do
qsolution=qinitial
call apply_policy_price(nb,ny,np,nh,ty,tp,th,decision,left,weight,qsolution,coupon,discount,surviving,.true.,r,src,a,b,repay_weights)
r=r-qsolution;initial_residual=maxval(abs(r));final_residual=initial_residual
iterations=0;success=initial_residual<tolerance
if(.not.success)then
 rhat=r;p=0d0;v=0d0;rho_old=1d0;alpha=1d0;omega=1d0
 do it=1,150
  iterations=it
  rho=sum(rhat*r)
  if(.not.ieee_is_finite(rho).or.abs(rho)<1d-280)exit
  if(it==1)then
   p=r
  else
   if(abs(omega)<1d-280)exit
   beta_k=(rho/rho_old)*(alpha/omega)
   p=r+beta_k*(p-omega*v)
  end if
  call apply_policy_price(nb,ny,np,nh,ty,tp,th,decision,left,weight,p,coupon,discount,surviving,.false.,v,src,a,b,repay_weights)
  v=p-v;denom=sum(rhat*v)
  if(.not.ieee_is_finite(denom).or.abs(denom)<1d-280)exit
  alpha=rho/denom;s=r-alpha*v
  if(maxval(abs(s))<tolerance)then
   qsolution=qsolution+alpha*p
   exit
  end if
  call apply_policy_price(nb,ny,np,nh,ty,tp,th,decision,left,weight,s,coupon,discount,surviving,.false.,t,src,a,b,repay_weights)
  t=s-t;tt=sum(t*t)
  if(.not.ieee_is_finite(tt).or.tt<1d-280)exit
  omega=sum(t*s)/tt
  if(.not.ieee_is_finite(omega))exit
  qsolution=qsolution+alpha*p+omega*s;r=s-omega*t
  if(maxval(abs(r))<tolerance)exit
  rho_old=rho
 end do
 ! Always test the actual pricing equation, not only the recursive Krylov residual.
 call apply_policy_price(nb,ny,np,nh,ty,tp,th,decision,left,weight,qsolution,coupon,discount,surviving,.true.,r,src,a,b,repay_weights)
 final_residual=maxval(abs(r-qsolution))
 if(.not.ieee_is_finite(final_residual))then
  qsolution=qinitial;final_residual=huge(1d0)
 end if
 ! Positive-contraction fallback if BiCGSTAB breaks down or its residual drifts.
 do fallback=1,2000
  if(final_residual<tolerance)exit
  call apply_policy_price(nb,ny,np,nh,ty,tp,th,decision,left,weight,qsolution,coupon,discount,surviving,.true.,r,src,a,b,repay_weights)
  final_residual=maxval(abs(r-qsolution));qsolution=r;iterations=iterations+1
 end do
 call apply_policy_price(nb,ny,np,nh,ty,tp,th,decision,left,weight,qsolution,coupon,discount,surviving,.true.,r,src,a,b,repay_weights)
 final_residual=maxval(abs(r-qsolution))
end if
qbound=discount*coupon/(1d0-discount*surviving)
success=ieee_is_finite(final_residual).and.final_residual<tolerance.and.minval(qsolution)>-1d-8.and.maxval(qsolution)<qbound+1d-8
end subroutine solve_fixed_policy_prices
end module fixed_policy_pricing
