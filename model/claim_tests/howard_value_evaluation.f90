module howard_value_evaluation
use fixed_policy_pricing, only:apply_policy_price
implicit none
contains
subroutine evaluate_policy_values(nb,ny,np,nh,steps,grid,policy,decision,ty,tp,th,repay_weights,cr,ca,beta,reentry,vr,va,value)
integer,intent(in)::nb,ny,np,nh,steps,decision(nb,ny,np,nh)
double precision,intent(in)::grid(nb),policy(nb,ny,np,nh),ty(ny,ny),tp(np,np,nh),th(nh,nh),repay_weights(nb,ny,ny,np,nh)
double precision,intent(in)::cr(nb,ny,np,nh),ca(ny,np,nh),beta,reentry
double precision,intent(inout)::vr(nb,ny,np,nh),va(ny,np,nh)
double precision,intent(out)::value(nb,ny,np,nh)
integer,allocatable::left(:,:,:,:)
double precision,allocatable::weight(:,:,:,:),ur(:,:,:,:),ua(:,:,:),diff(:,:,:,:),ev(:,:,:,:),src(:,:,:,:),a(:,:,:,:),b(:,:,:,:)
double precision,allocatable::aa(:,:,:),ba(:,:,:),ea(:,:,:)
integer::ib,iy,ip,iv,ivn,iyn,j,it
double precision::db,w
allocate(left(nb,ny,np,nh),weight(nb,ny,np,nh),ur(nb,ny,np,nh),ua(ny,np,nh),diff(nb,ny,np,nh),ev(nb,ny,np,nh), &
 src(nb,ny,np,nh),a(nb,ny,np,nh),b(nb,ny,np,nh),aa(ny,np,nh),ba(ny,np,nh),ea(ny,np,nh))
ur=-1d0/max(cr,1d-10);ua=-1d0/max(ca,1d-10);db=grid(2)-grid(1)
do iv=1,nh
do ip=1,np
do iy=1,ny
do ib=1,nb
 j=max(1,min(nb-1,int((policy(ib,iy,ip,iv)-grid(1))/db)+1));left(ib,iy,ip,iv)=j
 weight(ib,iy,ip,iv)=max(0d0,min(1d0,(policy(ib,iy,ip,iv)-grid(j))/(grid(j+1)-grid(j))))
end do
end do
end do
end do
do it=1,steps
 do iv=1,nh
 do ip=1,np
 do iy=1,ny
  diff(:,iy,ip,iv)=vr(:,iy,ip,iv)-va(iy,ip,iv)
 end do
 end do
 end do
 call apply_policy_price(nb,ny,np,nh,ty,tp,th,decision,left,weight,diff,0d0,1d0,1d0,.false.,ev,src,a,b,repay_weights,.true.)
 do iv=1,nh
  do ip=1,np
   do iy=1,ny
    aa(iy,ip,iv)=sum(ty(iy,:)*va(:,ip,iv))
   end do
  end do
  call dgemm('N','T',ny,np,np,1d0,aa(1,1,iv),ny,tp(1,1,iv),np,0d0,ba(1,1,iv),ny)
 end do
 ea=0d0
 do iv=1,nh
  do ivn=1,nh
   ea(:,:,iv)=ea(:,:,iv)+th(iv,ivn)*ba(:,:,ivn)
  end do
 end do
 do iv=1,nh
 do ip=1,np
 do iy=1,ny
  ev(:,iy,ip,iv)=ev(:,iy,ip,iv)+ea(iy,ip,iv)
 end do
 end do
 end do
 va=ua+beta*(reentry*ev(1,:,:,:)+(1d0-reentry)*ea)
 do iv=1,nh
 do ip=1,np
 do iy=1,ny
 do ib=1,nb
  j=left(ib,iy,ip,iv);w=weight(ib,iy,ip,iv)
  vr(ib,iy,ip,iv)=ur(ib,iy,ip,iv)+beta*((1d0-w)*ev(j,iy,ip,iv)+w*ev(j+1,iy,ip,iv))
 end do
 end do
 end do
 end do
end do
do iv=1,nh
do ip=1,np
do iy=1,ny
do ib=1,nb
 if(decision(ib,iy,ip,iv)==1)then
  value(ib,iy,ip,iv)=vr(ib,iy,ip,iv)
 else
  value(ib,iy,ip,iv)=va(iy,ip,iv)
 end if
end do
end do
end do
end do
end subroutine evaluate_policy_values
end module howard_value_evaluation
