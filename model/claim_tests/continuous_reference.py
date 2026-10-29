"""Independent polynomial-root reference for piecewise-linear debt interpolation."""
import numpy as np

def polynomial_optimum(grid,q,ev,resources,current_b,beta,delta,coupon):
    cons=resources-current_b*coupon+q*(grid-(1-delta)*current_b)
    values=-1/np.maximum(cons,1e-10)+beta*ev
    jbest=int(np.argmax(values));best=float(values[jbest]);bstar=float(grid[jbest]);qstar=float(q[jbest])
    for j in range(len(grid)-1):
        width=grid[j+1]-grid[j];c2=(q[j+1]-q[j])/width;c1=q[j]+c2*(grid[j]-(1-delta)*current_b);c0=resources-current_b*coupon+q[j]*(grid[j]-(1-delta)*current_b);es=(ev[j+1]-ev[j])/width
        square=np.polynomial.polynomial.polymul([c0,c1,c2],[c0,c1,c2]);coeff=np.zeros(5);coeff[:len(square)]=beta*es*square;coeff[:2]+=[c1,2*c2]
        roots=np.polynomial.polynomial.polyroots(coeff) if np.any(coeff) else []
        floor=np.polynomial.polynomial.polyroots([c0-1e-10,c1,c2]) if c1!=0 or c2!=0 else []
        for root in [*roots,*floor]:
            if abs(root.imag)>1e-7 or root.real<0 or root.real>width:continue
            x=float(root.real);c=c0+c1*x+c2*x*x;value=-1/max(c,1e-10)+beta*(ev[j]+es*x)
            if value>best:best=float(value);bstar=float(grid[j]+x);qstar=float(q[j]+c2*x)
    return bstar,best,qstar
