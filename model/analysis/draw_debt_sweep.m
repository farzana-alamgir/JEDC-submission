load bysweep2.mat
cL=[0.8500 0.3250 0.0980]; cM=[0 0.4470 0.7410]; cH=[0.4660 0.6740 0.1880]; cG=[0.55 0.55 0.55];
f=figure('Position',[60 60 1300 420]);

subplot(1,3,1); hold on; box on;
plot(DY,R,'-o','LineWidth',3,'Color',cM,'MarkerFaceColor',cM,'MarkerSize',5);
yline(3,'--','LineWidth',2,'Color',cL); yline(1,':','LineWidth',1.5,'Color',cG);
text(0.085,2.85,'paper: 3.0','FontSize',11,'Color',cL);
set(gca,'FontSize',12); ylim([0 3.3]);
xlabel('Debt / GDP','FontSize',14,'Interpreter','latex');
ylabel('Spread slope ratio, high / low vol','FontSize',12,'Interpreter','latex');
title('(a) State dependence','FontSize',13,'Interpreter','latex');

subplot(1,3,2); hold on; box on;
plot(DY,SLOPE,'-o','LineWidth',3,'Color',cM,'MarkerFaceColor',cM,'MarkerSize',5);
set(gca,'FontSize',12,'YScale','log');
xlabel('Debt / GDP','FontSize',14,'Interpreter','latex');
ylabel('Spread slope (bp per unit price)','FontSize',12,'Interpreter','latex');
title('(b) Debt amplification: 13 to 543 bp','FontSize',13,'Interpreter','latex');

subplot(1,3,3); hold on; box on;
plot(DY,DS(:,1),'-o','LineWidth',2.5,'Color',cL,'MarkerSize',4);
plot(DY,DS(:,2),'-s','LineWidth',2.5,'Color',cM,'MarkerSize',4);
plot(DY,DS(:,3),'-^','LineWidth',2.5,'Color',cH,'MarkerSize',4);
yline(0.16,'--','LineWidth',1.5,'Color',cG);
yline(0.25,'--','LineWidth',1.5,'Color',cG);
yline(0.70,'--','LineWidth',1.5,'Color',cG);
text(0.30,0.73,'paper 0.70','FontSize',10,'Color',cG);
text(0.30,0.28,'0.25','FontSize',10,'Color',cG);
text(0.30,0.19,'0.16','FontSize',10,'Color',cG);
set(gca,'FontSize',12); ylim([-0.05 0.8]);
xlabel('Debt / GDP','FontSize',14,'Interpreter','latex');
ylabel('Debt slope  d(Debt/GDP)/d(p)','FontSize',12,'Interpreter','latex');
legend({'low vol','mean vol','high vol'},'FontSize',10,'Location','northwest'); legend boxoff;
title('(c) Borrowing response (3 curves coincide)','FontSize',13,'Interpreter','latex');
saveas(f,'/Users/farzanaalamgir/code/JEDC_submission/results/FIGURE_debt_sweep.jpg');
fprintf('written\n');
