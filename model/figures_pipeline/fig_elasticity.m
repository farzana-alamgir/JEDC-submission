sig = [0.30 0.35 0.40 0.45 0.50 0.80 1.20 1.50 2.00];
cev = [0.4885 0.0774 -0.0021 -0.1182 -0.4920 -1.1399 -1.7708 -2.1975 -2.7785];
figure('Position',[100 100 820 600]);
plot(sig,cev,'-o','LineWidth',3,'MarkerSize',8,'Color',[0.2 0.4 0.8], ...
     'MarkerFaceColor',[0.2 0.4 0.8]); hold on
yline(0,'k-','LineWidth',1.2);
xl=xlim; fill([xl(1) 0.40 0.40 xl(1)],[0 0 3 3],[0.2 0.7 0.3], ...
     'FaceAlpha',0.10,'EdgeColor','none');
plot(0.40,0,'o','MarkerSize',12,'LineWidth',2.5,'Color',[0.8 0.2 0.2]);
text(0.46,0.33,'\sigma_{oil} \approx 0.40','FontSize',14,'Color',[0.8 0.2 0.2]);
text(0.33,1.05,sprintf('oil price risk\nis COSTLY\n(paper''s claim)'),'FontSize',12, ...
     'Color',[0.1 0.45 0.2],'HorizontalAlignment','left');
text(1.45,-0.75,sprintf('oil price risk\nis BENEFICIAL\n(Waugh: elastic demand)'),'FontSize',12, ...
     'Color',[0.35 0.35 0.35],'HorizontalAlignment','left');
plot(0.50,-0.4920,'s','MarkerSize',11,'LineWidth',2,'Color',[0.1 0.1 0.1]);
plot(2.00,-2.7785,'s','MarkerSize',11,'LineWidth',2,'Color',[0.1 0.1 0.1]);
text(1.76,-2.46,'paper''s \theta=0.5','FontSize',12);
xlabel('Oil substitution elasticity  \sigma_{oil} = 1/(1-\theta)','FontSize',15);
ylabel('Welfare of removing all oil price risk (% consumption)','FontSize',14);
set(gca,'FontSize',13,'LineWidth',1.2,'Box','on'); xlim([0.25 2.1]); ylim([-3.1 1.5]);
set(gca,'LooseInset',get(gca,'TightInset'));
saveas(gcf,'FIGURE_elasticity.jpg');
