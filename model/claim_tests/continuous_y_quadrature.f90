module continuous_y_quadrature
implicit none
contains
pure double precision function gaussian_cell(lo,hi)
double precision,intent(in)::lo,hi
double precision,parameter::root2=1.4142135623730950488d0
if(lo>=0d0)then
 gaussian_cell=.5d0*(erfc(lo/root2)-erfc(hi/root2))
else
 gaussian_cell=.5d0*(erfc(-hi/root2)-erfc(-lo/root2))
end if
gaussian_cell=max(0d0,gaussian_cell)
end function gaussian_cell
pure double precision function gaussian_pdf(z)
double precision,intent(in)::z
if(abs(z)>38d0)then
 gaussian_pdf=0d0
else
 gaussian_pdf=exp(-.5d0*z*z)/2.5066282746310005024d0
end if
end function gaussian_pdf
pure subroutine affine_interval(lo,hi,yl,yr,mu,sigma,left,right)
double precision,intent(in)::lo,hi,yl,yr,mu,sigma
double precision,intent(out)::left,right
double precision::a,b,prob,moment
a=(lo-mu)/sigma;b=(hi-mu)/sigma
prob=gaussian_cell(a,b)
moment=mu*prob+sigma*(gaussian_pdf(a)-gaussian_pdf(b))
left=max(0d0,(yr*prob-moment)/(yr-yl))
right=max(0d0,(moment-yl*prob)/(yr-yl))
end subroutine affine_interval
subroutine gaussian_weight_tables(n,grid,rho,sigma,mean,all,wl,wr,lower,upper)
integer,intent(in)::n
double precision,intent(in)::grid(n),rho,sigma,mean
double precision,intent(out)::all(n,n),wl(n,n-1),wr(n,n-1),lower(n),upper(n)
integer::iy,j
double precision::mu
all=0d0
do iy=1,n
 mu=(1d0-rho)*mean+rho*grid(iy)
 lower(iy)=.5d0*erfc(-(grid(1)-mu)/(sigma*sqrt(2d0)))
 upper(iy)=.5d0*erfc((grid(n)-mu)/(sigma*sqrt(2d0)))
 all(iy,1)=lower(iy);all(iy,n)=upper(iy)
 do j=1,n-1
  call affine_interval(grid(j),grid(j+1),grid(j),grid(j+1),mu,sigma,wl(iy,j),wr(iy,j))
  all(iy,j)=all(iy,j)+wl(iy,j)
  all(iy,j+1)=all(iy,j+1)+wr(iy,j)
 end do
end do
end subroutine gaussian_weight_tables
subroutine repayment_hat_weights(nb,n,np,nh,grid,rho,sigma,mean,vr,va,all,wl,wr,lower,upper,w)
integer,intent(in)::nb,n,np,nh
double precision,intent(in)::grid(n),rho,sigma,mean,vr(nb,n,np,nh),va(n,np,nh),all(n,n),wl(n,n-1),wr(n,n-1),lower(n),upper(n)
double precision,intent(out)::w(nb,n,n,np,nh)
integer::iv,ip,ib,iy,j
double precision::gap(n),cut,lo,hi,mu,left,right
!$omp parallel do collapse(2) default(shared) private(iv,ip,ib,iy,j,gap,cut,lo,hi,mu,left,right) schedule(static)
do iv=1,nh
do ip=1,np
do ib=1,nb
 gap=vr(ib,:,ip,iv)-va(:,ip,iv)
 if(minval(gap)>=0d0)then
  w(ib,:,:,ip,iv)=all
  cycle
 end if
 if(maxval(gap)<0d0)then
  w(ib,:,:,ip,iv)=0d0
  cycle
 end if
 w(ib,:,:,ip,iv)=0d0
 ! Same clipped-tail convention as the original finite grid.
 if(gap(1)>=0d0)w(ib,:,1,ip,iv)=lower
 if(gap(n)>=0d0)w(ib,:,n,ip,iv)=upper
 do j=1,n-1
  if(gap(j)>=0d0.and.gap(j+1)>=0d0)then
   w(ib,:,j,ip,iv)=w(ib,:,j,ip,iv)+wl(:,j)
   w(ib,:,j+1,ip,iv)=w(ib,:,j+1,ip,iv)+wr(:,j)
  else if(gap(j)<0d0.and.gap(j+1)<0d0)then
   cycle
  else
   cut=grid(j)-gap(j)*(grid(j+1)-grid(j))/(gap(j+1)-gap(j))
   cut=max(grid(j),min(grid(j+1),cut))
   if(gap(j)>=0d0)then
    lo=grid(j);hi=cut
   else
    lo=cut;hi=grid(j+1)
   end if
   do iy=1,n
    mu=(1d0-rho)*mean+rho*grid(iy)
    call affine_interval(lo,hi,grid(j),grid(j+1),mu,sigma,left,right)
    w(ib,iy,j,ip,iv)=w(ib,iy,j,ip,iv)+left
    w(ib,iy,j+1,ip,iv)=w(ib,iy,j+1,ip,iv)+right
   end do
  end if
 end do
 w(ib,:,:,ip,iv)=max(0d0,min(all,w(ib,:,:,ip,iv)))
end do
end do
end do
!$omp end parallel do
end subroutine repayment_hat_weights
end module continuous_y_quadrature
