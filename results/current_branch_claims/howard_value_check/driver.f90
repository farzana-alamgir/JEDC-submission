program check
use howard_value_evaluation
implicit none
integer,parameter::nb=3,ny=3,np=4,nh=2
integer::ic,steps,d(nb,ny,np,nh)
double precision::g(nb),policy(nb,ny,np,nh),ty(ny,ny),tp(np,np,nh),th(nh,nh),w(nb,ny,ny,np,nh)
double precision::cr(nb,ny,np,nh),ca(ny,np,nh),vr(nb,ny,np,nh),va(ny,np,nh),value(nb,ny,np,nh)
do ic=1,9
read(*,*)steps
read(*,*)g
read(*,*)policy
read(*,*)d
read(*,*)ty
read(*,*)tp
read(*,*)th
read(*,*)w
read(*,*)cr
read(*,*)ca
read(*,*)vr
read(*,*)va
call evaluate_policy_values(nb,ny,np,nh,steps,g,policy,d,ty,tp,th,w,cr,ca,.96d0,.0833d0,vr,va,value)
write(*,'(ES26.16E3)')vr
write(*,'(ES26.16E3)')va
write(*,'(ES26.16E3)')value
end do
end program check
