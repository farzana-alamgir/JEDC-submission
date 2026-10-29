"""Independent analytic Gaussian integration of interpolated default cutoffs."""
import math
import numpy as np
_erfc=np.vectorize(math.erfc,otypes=[float])
def interval_moments(lo,hi,mean,sigma):
    a=(lo-mean)/sigma;b=(hi-mean)/sigma
    prob=np.where(a>=0,.5*(_erfc(a/np.sqrt(2))-_erfc(b/np.sqrt(2))),.5*(_erfc(-b/np.sqrt(2))-_erfc(-a/np.sqrt(2))))
    prob=np.maximum(prob,0)
    first=mean*prob+sigma*(np.exp(-.5*a*a)-np.exp(-.5*b*b))/np.sqrt(2*np.pi)
    return prob,first

def weight_tables(grid,rho,sigma,mean=0):
    mu=(1-rho)*mean+rho*grid
    lo=grid[:-1][None,:];hi=grid[1:][None,:]
    prob,first=interval_moments(lo,hi,mu[:,None],sigma)
    wl=np.maximum((hi*prob-first)/(hi-lo),0);wr=np.maximum((first-lo*prob)/(hi-lo),0)
    lower=.5*_erfc(-(grid[0]-mu)/(sigma*np.sqrt(2)));upper=.5*_erfc((grid[-1]-mu)/(sigma*np.sqrt(2)))
    all=np.zeros((len(grid),len(grid)));all[:,0]=lower;all[:,-1]=upper;all[:,:-1]+=wl;all[:,1:]+=wr
    return all,wl,wr,lower,upper,mu

def repayment_weights(vr,va,grid,rho,sigma,tables=None):
    """vr has (debt,y), va has y; output is (debt,current y,next y)."""
    all,wl,wr,lower,upper,mu=tables if tables is not None else weight_tables(grid,rho,sigma)
    gap=vr-va[None,:];nb,n=gap.shape;w=np.zeros((nb,n,n))
    w[gap[:,0]>=0,:,0]=lower;w[gap[:,-1]>=0,:,-1]=upper
    for j in range(n-1):
        full=(gap[:,j]>=0)&(gap[:,j+1]>=0)
        w[full,:,j]+=wl[:,j];w[full,:,j+1]+=wr[:,j]
        mixed=((gap[:,j]>=0)&(gap[:,j+1]<0))|((gap[:,j]<0)&(gap[:,j+1]>=0))
        ids=np.flatnonzero(mixed)
        if not len(ids):continue
        cut=grid[j]-gap[ids,j]*(grid[j+1]-grid[j])/(gap[ids,j+1]-gap[ids,j]);cut=np.clip(cut,grid[j],grid[j+1]);left_positive=gap[ids,j]>=0
        lo=np.where(left_positive,grid[j],cut)[:,None];hi=np.where(left_positive,cut,grid[j+1])[:,None]
        prob,first=interval_moments(lo,hi,mu[None,:],sigma)
        w[ids,:,j]+=np.maximum((grid[j+1]*prob-first)/(grid[j+1]-grid[j]),0)
        w[ids,:,j+1]+=np.maximum((first-grid[j]*prob)/(grid[j+1]-grid[j]),0)
    return np.minimum(all[None,:,:],np.maximum(w,0))

def repay_payoff_expectations(vr,va,payoff,grid,rho,sigma):
    """Input VR/payoff: (vol,price,y,debt); VA: (vol,price,y)."""
    tables=weight_tables(grid,rho,sigma);out=np.empty_like(payoff)
    for v in range(vr.shape[0]):
        for p in range(vr.shape[1]):
            w=repayment_weights(vr[v,p].T,va[v,p],grid,rho,sigma,tables)
            out[v,p]=np.einsum('bkj,jb->kb',w,payoff[v,p],optimize=True)
    return out

def max_value_expectations(vr,va,grid,rho,sigma):
    tables=weight_tables(grid,rho,sigma);out=np.empty_like(vr);excl=np.empty_like(va)
    for v in range(vr.shape[0]):
        for p in range(vr.shape[1]):
            w=repayment_weights(vr[v,p].T,va[v,p],grid,rho,sigma,tables)
            excl[v,p]=tables[0]@va[v,p]
            out[v,p]=excl[v,p,:,None]+np.einsum('bkj,bj->kb',w,vr[v,p].T-va[v,p][None,:],optimize=True)
    return out,excl
