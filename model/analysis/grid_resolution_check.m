A=load('oil_bm.mat','b_grid','output_matrix','b_next_matrix','p_grid_matrix','p_num','p_vol_num','pdf_p','b_num');
p=exp(A.p_grid_matrix(:,3));
erg=zeros(A.p_num,1);
for v=1:A.p_vol_num, erg=erg+A.pdf_p((v-1)*A.p_num+(1:A.p_num)); end
erg=erg/sum(erg); imed=find(cumsum(erg)>=0.5,1); pm=p(imed);
[~,iLo]=min(abs(p-0.90*pm)); [~,iHi]=min(abs(p-1.10*pm)); dp=p(iHi)-p(iLo);
gdpm=mean(A.output_matrix(:));
step=(A.b_grid(2)-A.b_grid(1))/(4*gdpm);
fprintf('b_grid: %d points, spacing %.4f in debt, %.5f in debt/GDP\n', A.b_num, A.b_grid(2)-A.b_grid(1), step);
fprintf('one grid step over dp=%.4f gives a debt slope of %.4f\n', dp, step/dp);
fprintf('  -> the debt slope is QUANTISED in units of %.4f\n', step/dp);
fprintf('  -> the paper claims low 0.16 / high 0.70, a gap of 0.54 = %.1f grid steps\n\n', 0.54/(step/dp));
iy=11;
fprintf('does the borrowing policy differ across volatility states at all?\n');
nd=0; tot=0;
for ib=1:A.b_num
  for ip=[iLo iHi]
    b2=A.b_next_matrix(ib,iy,ip,2); b4=A.b_next_matrix(ib,iy,ip,4);
    tot=tot+1; if b2~=b4, nd=nd+1; end
  end
end
fprintf('  b_next differs between low and high vol at %d of %d (b, p) states\n', nd, tot);
