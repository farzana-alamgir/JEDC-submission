A=load('oil_bm.mat','spread_matrix','p_grid_matrix','b_grid','y_num','p_num','p_vol_num', ...
       'output_matrix','b_next_matrix','b_num','pdf_p');
p=exp(A.p_grid_matrix(:,3));
erg=zeros(A.p_num,1);
for v=1:A.p_vol_num, erg=erg+A.pdf_p((v-1)*A.p_num+(1:A.p_num)); end
erg=erg/sum(erg); imed=find(cumsum(erg)>=0.5,1); pm=p(imed);
[~,iLo]=min(abs(p-0.90*pm)); [~,iHi]=min(abs(p-1.10*pm)); dp=p(iHi)-p(iLo);
gdpm=mean(A.output_matrix(:)); vs=[2 3 4]; iy=11;
IBS=15:3:66;
R=nan(size(IBS)); DY=nan(size(IBS)); SLOPE=nan(size(IBS)); DS=nan(numel(IBS),3);
for t=1:numel(IBS)
  ib=IBS(t); DY(t)=A.b_grid(ib)/(4*gdpm);
  sl=nan(A.y_num,3);
  for k=1:3
    sl(:,k)=(squeeze(A.spread_matrix(ib,:,iHi,vs(k)))-squeeze(A.spread_matrix(ib,:,iLo,vs(k))))'/dp;
  end
  r=sl(:,3)./sl(:,1); ok=isfinite(r)&sl(:,1)>1e-8;
  if any(ok), R(t)=median(r(ok)); end
  s3=sl(:,2); f3=s3(isfinite(s3)); if ~isempty(f3), SLOPE(t)=1e4*median(f3); end
  % debt slope AT this debt level
  for k=1:3
    v=vs(k);
    bl=A.b_next_matrix(ib,iy,iLo,v); bh=A.b_next_matrix(ib,iy,iHi,v);
    if bl>=1 && bh>=1 && bl<=A.b_num && bh<=A.b_num
      gl=A.output_matrix(ib,iy,iLo,v); gh=A.output_matrix(ib,iy,iHi,v);
      if gl>0 && gh>0
        DS(t,k)=(A.b_grid(bh)/(4*gh)-A.b_grid(bl)/(4*gl))/dp;
      end
    end
  end
end
save('bysweep2.mat','IBS','R','DY','DS','SLOPE');
fprintf('%-6s %-10s %-10s %-10s %s\n','i_b','debt/GDP','ratio h/l','slope bp','debt slope low/mean/high');
for t=1:numel(IBS)
  fprintf('%-6d %-10.3f %-10.3f %-10.1f %+0.4f / %+0.4f / %+0.4f\n', IBS(t),DY(t),R(t),SLOPE(t),DS(t,1),DS(t,2),DS(t,3));
end
fprintf('\nstate-dependence ratio: min %.3f max %.3f  (paper 3.00)\n', min(R), max(R));
fprintf('debt slope mean vol   : min %+0.4f max %+0.4f  (paper 0.25)\n', min(DS(:,2)), max(DS(:,2)));
fprintf('debt slope high vol   : min %+0.4f max %+0.4f  (paper 0.70)\n', min(DS(:,3)), max(DS(:,3)));
