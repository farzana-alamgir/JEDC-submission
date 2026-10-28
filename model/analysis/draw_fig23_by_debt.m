L=load('fig23_by_debt.mat');
sel = L.dgdp < 0.40;                      % beyond this the spread explodes past 20%
figure('Position',[100 100 1200 520]);

subplot(1,2,1); hold on
plot(L.dgdp(sel),L.sF(sel),'--','LineWidth',3,'Color',[0.2 0.7 0.3]);
plot(L.dgdp(sel),L.sI(sel),'-','LineWidth',2.5,'Color',[0.2 0.4 0.8]);
plot(L.dgdp(sel),L.sB(sel),'-','LineWidth',2.5,'Color',[0.8 0.2 0.2]);
legend({'Full','Intermediate','Basic'},'Location','northwest','FontSize',12); legend boxoff
xlabel('Debt/GDP','FontSize',14); ylabel('Annual Spread (%)','FontSize',14);
title('FIGURE2 schedules','FontSize',14); set(gca,'FontSize',12,'Box','on'); ylim([1.4 6])

subplot(1,2,2); hold on
yline(1,'k-','LineWidth',1.5);
yline(3,'-','LineWidth',2,'Color',[0.85 0.33 0.1]);
text(0.30,3.12,'paper claims 3.0','FontSize',12,'Color',[0.85 0.33 0.1]);
g=L.good; plot(L.dd(g),L.rat(g),'-o','LineWidth',3,'MarkerSize',7, ...
    'Color',[0.2 0.4 0.8],'MarkerFaceColor',[0.2 0.4 0.8]);
text(0.30,1.12,'no state dependence','FontSize',12);
xlabel('Debt/GDP','FontSize',14);
ylabel('Spread-slope ratio, high vol / low vol','FontSize',13);
title('FIGURE3 state dependence, by debt','FontSize',14);
set(gca,'FontSize',12,'Box','on'); ylim([0 3.4]); xlim([0 0.56])
saveas(gcf,'FIGURE_fig23_by_debt.jpg');
