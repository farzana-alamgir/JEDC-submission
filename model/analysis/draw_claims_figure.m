A=load('oil_bm.mat','spread_matrix','p_grid_matrix','b_grid','y_num','p_num','p_vol_num', ...
       'output_matrix','b_next_matrix','b_num','pdf_p');
p=exp(A.p_grid_matrix(:,3));
erg=zeros(A.p_num,1);
for v=1:A.p_vol_num, erg=erg+A.pdf_p((v-1)*A.p_num+(1:A.p_num)); end
erg=erg/sum(erg); imed=find(cumsum(erg)>=0.5,1); pm=p(imed);
[~,iLo]=min(abs(p-0.90*pm)); [~,iHi]=min(abs(p-1.10*pm)); dp=p(iHi)-p(iLo);
gdpm=mean(A.output_matrix(:));
cL=[0.8500 0.3250 0.0980]; cM=[0 0.4470 0.7410]; cH=[0.4660 0.6740 0.1880];
f=figure('Position',[60 60 1280 940]);

% (a) spread slope by volatility state
subplot(2,2,1); hold on; box on;
ib=44; vs=[2 3 4]; sl=nan(A.y_num,3);
for k=1:3
  sl(:,k)=(squeeze(A.spread_matrix(ib,:,iHi,vs(k)))-squeeze(A.spread_matrix(ib,:,iLo,vs(k))))'/dp;
end
out=squeeze(A.output_matrix(ib,:,iLo,3))'; ok=isfinite(sl(:,1))&sl(:,1)>1e-8;
cc={cL,cM,cH};
for k=1:3, plot(out(ok),1e4*sl(ok,k),'-','LineWidth',3,'Color',cc{k}); end
set(gca,'FontSize',12,'YScale','log'); box on;
xlabel('Output','FontSize',14,'Interpreter','latex');
ylabel('Spread slope (bp per unit price)','FontSize',13,'Interpreter','latex');
legend({'Low vol','Mean vol','High vol'},'FontSize',11,'Location','northeast'); legend boxoff;
title('(a) State dependence: ratio 1.03, paper claims 3','FontSize',13,'Interpreter','latex');

% (b) debt amplification
subplot(2,2,2); hold on; box on;
ibs=10:5:65; dy=[]; sv=[];
for ib2=ibs
  s=(squeeze(A.spread_matrix(ib2,:,iHi,3))-squeeze(A.spread_matrix(ib2,:,iLo,3)))'/dp;
  fi=s(isfinite(s));
  if ~isempty(fi), dy(end+1)=A.b_grid(ib2)/(4*gdpm); sv(end+1)=1e4*median(fi); end
end
plot(dy,sv,'-o','LineWidth',3,'Color',cM,'MarkerFaceColor',cM,'MarkerSize',6);
set(gca,'FontSize',12,'YScale','log');
xlabel('Debt / GDP','FontSize',14,'Interpreter','latex');
ylabel('Spread slope (bp per unit price)','FontSize',13,'Interpreter','latex');
title('(b) Debt amplification: CONFIRMED','FontSize',13,'Interpreter','latex');

% (c) debt slope by volatility state vs the paper's claim
subplot(2,2,3); hold on; box on;
iy=11; ds=zeros(1,3);
for k=1:3
  v=vs(k); dd=[];
  for ib2=1:A.b_num
    bl=A.b_next_matrix(ib2,iy,iLo,v); bh=A.b_next_matrix(ib2,iy,iHi,v);
    if bl<1||bh<1||bl>A.b_num||bh>A.b_num, continue; end
    gl=A.output_matrix(ib2,iy,iLo,v); gh=A.output_matrix(ib2,iy,iHi,v);
    if gl<=0||gh<=0, continue; end
    dd(end+1)=(A.b_grid(bh)/(4*gh)-A.b_grid(bl)/(4*gl))/dp;
  end
  ds(k)=mean(dd);
end
b=bar([0.16 0.25 0.70; ds],'grouped'); b(1).FaceColor=[0.6 0.6 0.6];
b(2).FaceColor=cM; b(3).FaceColor=cH;
set(gca,'FontSize',12,'XTick',1:2,'XTickLabel',{'paper claim','this model'});
ylabel('Debt slope  d(Debt/GDP)/d(p)','FontSize',13,'Interpreter','latex');
legend({'low vol','mean vol','high vol'},'FontSize',11,'Location','northeast'); legend boxoff;
title('(c) Debt slope: 0.02 vs 0.16--0.70 claimed','FontSize',13,'Interpreter','latex');

% (d) welfare
subplot(2,2,4); hold on; box on;
w=[0.2 1.1; 0.0642 -3.2397];
yline(0,'k-','LineWidth',1);
b2=bar(w,'grouped'); b2(1).FaceColor=[0.6 0.6 0.6]; b2(2).FaceColor=cL;
set(gca,'FontSize',12,'XTick',1:2,'XTickLabel',{'paper claim','this model'});
ylabel('Welfare gain (\% of consumption)','FontSize',13,'Interpreter','latex');
legend(b2,{'remove time-varying vol','remove all oil price risk'},'FontSize',10,'Location','southwest'); legend boxoff;
title('(d) Welfare: removing risk now COSTS 3.2\%','FontSize',13,'Interpreter','latex');
saveas(f,'/Users/farzanaalamgir/code/JEDC_submission/results/FIGURE_claims_check.jpg');
fprintf('debt slopes: %.4f %.4f %.4f\n', ds);
