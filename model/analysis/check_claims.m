A=load('oil_bm.mat','spread_matrix','p_grid_matrix','b_grid','y_num','p_num','p_vol_num', ...
       'output_matrix','b_next_matrix','b_num','pdf_p','pdf_p_vol','v_matrix');
p=exp(A.p_grid_matrix(:,3));
% LOCAL contrast: +/-10% around the ergodic median price (a derivative, not a chord)
erg=zeros(A.p_num,1);
for v=1:A.p_vol_num, erg=erg+A.pdf_p((v-1)*A.p_num+(1:A.p_num)); end
erg=erg/sum(erg); imed=find(cumsum(erg)>=0.5,1); pm=p(imed);
[~,iLo]=min(abs(p-0.90*pm)); [~,iHi]=min(abs(p-1.10*pm));
dp=p(iHi)-p(iLo);
gdpm=mean(A.output_matrix(:));
fprintf('LOCAL contrast around p50=%.4f : %.4f -> %.4f  (dp=%.4f, a %.0f%% price move)\n\n', ...
        pm, p(iLo), p(iHi), dp, 100*dp/pm);

ib=44; vs=[2 3 4]; sl=nan(A.y_num,3);
for k=1:3
  sl(:,k)=(squeeze(A.spread_matrix(ib,:,iHi,vs(k)))-squeeze(A.spread_matrix(ib,:,iLo,vs(k))))'/dp;
end
r=sl(:,3)./sl(:,1); ok=isfinite(r)&sl(:,1)>1e-8;
fprintf('[1] SPREAD SLOPE, state dependence  (paper: 3x)\n');
fprintf('    low/mean/high vol at median y: %.1f / %.1f / %.1f bp per unit price\n', 1e4*sl(11,1),1e4*sl(11,2),1e4*sl(11,3));
fprintf('    ratio high/low: median %.3f  max %.2f  >1 at %d of %d\n\n', median(r(ok)),max(r(ok)),sum(r(ok)>1),sum(ok));

fprintf('[2] DEBT AMPLIFICATION  (paper: more indebted -> larger spread increases)\n');
fprintf('    %-6s %-11s %s\n','i_b','debt/GDP','slope (bp per unit price, mean vol)');
for ib2=[20 30 40 44 50 60]
  s=(squeeze(A.spread_matrix(ib2,:,iHi,3))-squeeze(A.spread_matrix(ib2,:,iLo,3)))'/dp;
  f=s(isfinite(s));
  if ~isempty(f), fprintf('    %-6d %-11.3f %.1f\n', ib2, A.b_grid(ib2)/(4*gdpm), 1e4*median(f)); end
end

fprintf('\n[3] DEBT SLOPE d(Debt/GDP)/d(OilPrice)  (paper: 0.16 low / 0.25 mean / 0.70 high)\n');
iy=11; nm={'low','mean','high'};
for k=1:3
  v=vs(k); dd=[];
  for ib2=1:A.b_num
    bl=A.b_next_matrix(ib2,iy,iLo,v); bh=A.b_next_matrix(ib2,iy,iHi,v);
    if bl<1||bh<1||bl>A.b_num||bh>A.b_num, continue; end
    gl=A.output_matrix(ib2,iy,iLo,v); gh=A.output_matrix(ib2,iy,iHi,v);
    if gl<=0||gh<=0, continue; end
    dd(end+1)=(A.b_grid(bh)/(4*gh)-A.b_grid(bl)/(4*gl))/dp;
  end
  if ~isempty(dd), fprintf('    %-5s vol: mean %+0.4f  median %+0.4f  (n=%d)\n', nm{k}, mean(dd), median(dd), numel(dd)); end
end
