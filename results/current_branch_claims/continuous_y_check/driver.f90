program check
use continuous_y_quadrature
implicit none
integer,parameter::n=21,nb=4,np=3,nh=2
integer::ic
double precision::grid(n),vr(nb,n,np,nh),va(n,np,nh),all(n,n),wl(n,n-1),wr(n,n-1),lower(n),upper(n),w(nb,n,n,np,nh),sigma
read(*,*)grid
read(*,*)vr
read(*,*)va
do ic=1,3
read(*,*)sigma
call gaussian_weight_tables(n,grid,.9d0,sigma,0d0,all,wl,wr,lower,upper)
call repayment_hat_weights(nb,n,np,nh,grid,.9d0,sigma,0d0,vr,va,all,wl,wr,lower,upper,w)
write(*,'(ES26.16E3)')all
write(*,'(ES26.16E3)')w
end do
end program check
