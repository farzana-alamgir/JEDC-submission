! Global maximization with linearly interpolated price and continuation value.
! On each debt interval, consumption is quadratic and continuation is linear.
! Split at consumption-floor crossings and utility-curvature roots; the first
! derivative is monotone on each remaining piece, so every interior maximum is
! found by a bracketed derivative root. No local-unimodality assumption is used.
subroutine continuous_debt(n,grid,q,ev,resources,current_b,beta,delta,coupon,bstar,vstar,qstar)
implicit none
integer,intent(in)::n
double precision,intent(in)::grid(n),q(n),ev(n),resources,current_b,beta,delta,coupon
double precision,intent(out)::bstar,vstar,qstar
double precision::aa,bb,cc,es,el,ql,width,issuance,x,c,vc,cmax,upper
 double precision::points(8),left,right,dl,dr,mid,dm,tmp,root,curvature,trial,cons_root,slope_root
integer::j,k,l,np,it
vstar=-huge(1d0);bstar=grid(1);qstar=q(1)
do j=1,n
 c=resources-current_b*coupon+q(j)*(grid(j)-(1d0-delta)*current_b)
 vc=-1d0/max(c,1d-10)+beta*ev(j)
 if(vc>vstar)then
  vstar=vc;bstar=grid(j);qstar=q(j)
 end if
end do
do j=1,n-1
 width=grid(j+1)-grid(j)
 ql=q(j);cc=(q(j+1)-q(j))/width
 es=(ev(j+1)-ev(j))/width;el=ev(j)
 issuance=grid(j)-(1d0-delta)*current_b
 aa=resources-current_b*coupon+ql*issuance
 bb=ql+cc*issuance
 cmax=max(aa,aa+bb*width+cc*width*width)
 if(cc<0d0)then
  x=-bb/(2d0*cc)
  if(x>0d0.and.x<width)cmax=max(cmax,aa+bb*x+cc*x*x)
 end if
 upper=-1d0/max(cmax,1d-10)+beta*max(ev(j),ev(j+1))
 if(upper<=vstar)cycle
 np=2;points(1)=0d0;points(2)=width
 call add_roots(cc,bb,aa-1d-10)
 call add_roots(-6d0*cc*cc,-6d0*bb*cc,2d0*cc*aa-2d0*bb*bb)
 do k=2,np
  tmp=points(k);l=k-1
  do while(l>=1)
   if(points(l)<=tmp)exit
   points(l+1)=points(l);l=l-1
  end do
  points(l+1)=tmp
 end do
 do k=1,np
  call consider(points(k))
 end do
 do k=1,np-1
  left=points(k);right=points(k+1)
  if(right-left<1d-13*max(1d0,width))cycle
  mid=.5d0*(left+right)
  if(aa+bb*mid+cc*mid*mid<=1d-10)cycle
  dl=deriv(left);dr=deriv(right)
  if(dl*dr>=0d0)cycle
  mid=.5d0*(left+right);root=mid
  do it=1,60
   dm=deriv(mid)
   if(dm==0d0)then
    root=mid;exit
   end if
   if((dm>0d0).eqv.(dl>0d0))then
    left=mid;dl=dm
   else
    right=mid
   end if
   if(right-left<1d-11*max(1d0,width))then
    root=.5d0*(left+right);exit
   end if
   cons_root=max(aa+bb*mid+cc*mid*mid,1d-10)
   slope_root=bb+2d0*cc*mid
   curvature=(2d0*cc*cons_root-2d0*slope_root*slope_root)/(cons_root**3)
   trial=.5d0*(left+right)
   if(abs(curvature)>1d-30)then
    tmp=mid-dm/curvature
    if(tmp>left.and.tmp<right)then
     trial=tmp
     if(abs(trial-mid)<1d-11*max(1d0,width))then
      root=trial;exit
     end if
    end if
   end if
   mid=trial;root=mid
  end do
  call consider(root)
 end do
end do
contains
subroutine add_roots(a,b,c0)
double precision,intent(in)::a,b,c0
double precision::disc,r1,r2,stable
if(abs(a)<1d-25)then
 if(abs(b)>1d-25)then
  r1=-c0/b
  if(r1>0d0.and.r1<width)then
   np=np+1;points(np)=r1
  end if
 end if
else
 disc=b*b-4d0*a*c0
 if(disc>=0d0)then
  stable=-.5d0*(b+sign(sqrt(disc),b))
  if(abs(stable)>1d-300)then
   r1=stable/a;r2=c0/stable
  else
   r1=-b/(2d0*a);r2=r1
  end if
  if(r1>0d0.and.r1<width)then
   np=np+1;points(np)=r1
  end if
  if(r2>0d0.and.r2<width)then
   np=np+1;points(np)=r2
  end if
 end if
end if
end subroutine add_roots
subroutine consider(xx)
double precision,intent(in)::xx
double precision::vv,cons
cons=aa+bb*xx+cc*xx*xx
vv=-1d0/max(cons,1d-10)+beta*(el+es*xx)
if(vv>vstar)then
 vstar=vv;bstar=grid(j)+xx;qstar=ql+cc*xx
end if
end subroutine consider
double precision function deriv(xx)
double precision,intent(in)::xx
double precision::cons
cons=max(aa+bb*xx+cc*xx*xx,1d-10)
deriv=(bb+2d0*cc*xx)/(cons*cons)+beta*es
end function deriv
end subroutine continuous_debt
