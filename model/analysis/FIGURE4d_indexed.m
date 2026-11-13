%FIGURE4D_INDEXED  Figure 4d, drawn so the effect is actually visible.
%
%   >> FIGURE4d_indexed('FIGURE4d_index.csv')
%
% Reads the CSV that model/analysis/fig4d_index.py writes and draws
% FIGURE4d_indexed.jpg beside it.
%
%   (a) the published view: expected next-period oil price at three price
%       levels. The levels differ by a factor of five, so the axis must span
%       them and the real 1.94% rise is about 1% of the panel height. This is
%       why the panel reads as horizontal -- the effect is small, not absent.
%
%   (b) each series indexed to its own calmest-volatility value. The three
%       lines coincide exactly and sit on the closed-form log-normal
%       prediction exp((v-v_1)/2). That coincidence is the point: for a
%       log-normal the volatility lift MULTIPLIES expected price, so it is the
%       same percentage at every current price. The submitted panel's three
%       different slopes could not have been this effect at all -- they came
%       from hardcoded price nodes on per-volatility-state grids, where the
%       node being conditioned on was itself a far higher price in the
%       volatile states.
%
% No dependencies beyond base MATLAB.

function FIGURE4d_indexed(incsv)

if nargin < 1, incsv = 'FIGURE4d_index.csv'; end
T = readtable(incsv);

sd = T.cond_sd_log_p;
lev = [T.E_p_next_low, T.E_p_next_mean, T.E_p_next_high];
idx = [T.index_low,    T.index_mean,    T.index_high];
cf  = T.closed_form_index;

col = [0.80 0.20 0.20;      % low price
       0.20 0.40 0.80;      % mean price
       0.20 0.70 0.30];     % high price
names = {'low price','mean price','high price'};

figure('Position',[60 60 1180 460],'Color','w');

%% ---- (a) the published view ------------------------------------------
subplot(1,2,1); hold on;
for k = 1:3
    plot(sd, lev(:,k), '-', 'LineWidth', 3, 'Color', col(k,:));
end
xlabel('conditional sd of $\log p$','FontSize',13,'Interpreter','latex');
ylabel('$E[p'' \mid p, \sigma]$','FontSize',13,'Interpreter','latex');
title('(a) as published: three price levels on one axis', ...
      'FontSize',12,'Interpreter','latex');
legend(names,'Location','northwest','FontSize',11,'Interpreter','latex');
legend boxoff;
set(gca,'FontSize',11,'LineWidth',1.1,'Box','on','TickLabelInterpreter','latex');
grid on; set(gca,'GridAlpha',0.12);
xlim([sd(1) sd(end)]);

%% ---- (b) indexed ------------------------------------------------------
subplot(1,2,2); hold on;
hc = plot(sd, cf, 'k--', 'LineWidth', 3);
mk = {'o','s','^'};
h = gobjects(1,3);
for k = 1:3
    h(k) = plot(sd, idx(:,k), mk{k}, 'MarkerSize', 9, 'LineWidth', 1.6, ...
                'Color', col(k,:), 'MarkerFaceColor','none');
end
plot([sd(1) sd(end)],[100 100],'k-','LineWidth',0.8);
xlabel('conditional sd of $\log p$','FontSize',13,'Interpreter','latex');
ylabel('index, calmest state $= 100$','FontSize',13,'Interpreter','latex');
sw = sprintf('%+.2f', cf(end)-100);
title(['(b) indexed: the same ' sw '\% at every price level'], ...
      'FontSize',12,'Interpreter','latex');
legend([hc h], [{'closed form $e^{(v-v_1)/2}$'}, names], ...
       'Location','northwest','FontSize',11,'Interpreter','latex');
legend boxoff;
set(gca,'FontSize',11,'LineWidth',1.1,'Box','on','TickLabelInterpreter','latex');
grid on; set(gca,'GridAlpha',0.12);
xlim([sd(1) sd(end)]);
pad = 0.12*(max(cf)-100);
ylim([100-pad, max(cf)+pad]);

set(findall(gcf,'Type','axes'),'Toolbar',[]);
[d,~,~] = fileparts(incsv);
out = fullfile(d,'FIGURE4d_indexed.jpg');
set(gcf,'PaperPositionMode','auto');
print(gcf, out, '-djpeg','-r200');
fprintf('wrote %s\n', out);
end
