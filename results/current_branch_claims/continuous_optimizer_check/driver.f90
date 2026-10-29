program check
implicit none
integer::n,t,nt
 double precision::res,bc,bet,del,coup,bs,vs,qs
 double precision,allocatable::g(:),q(:),ev(:)
read(*,*)nt
do t=1,nt
read(*,*)n,res,bc,bet,del,coup
allocate(g(n),q(n),ev(n))
read(*,*)g
read(*,*)q
read(*,*)ev
call continuous_debt(n,g,q,ev,res,bc,bet,del,coup,bs,vs,qs)
write(*,'(3ES25.16)')bs,vs,qs
deallocate(g,q,ev)
end do
end program check
