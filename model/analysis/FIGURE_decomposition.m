%FIGURE_DECOMPOSITION  The four panels for R2 Major 1 / R1 Major 2.
%
%   >> FIGURE_decomposition('../../results/decomposition_spdebt')
%
% Reads the CSVs that model/analysis/decomposition.py writes and draws
% FIGURE_decomposition.jpg beside them.
%
%   (a) E[p' | p = centre node, sigma] against the conditional sd of log p, for
%       the full model and the mean-preserving correction, with the closed-form
%       exp(v/2) overlaid. The validation: the full model's conditional expected
%       price rises with volatility exactly as the log-normal arithmetic
%       predicts, and the correction removes it exactly.
%
%   (b) the channel decomposition with 95% simulation intervals and a zero line.
%       The asymmetry is the message: the level of oil price risk is large and
%       precisely measured, while all three volatility channels straddle zero.
%
%   (c,d) high-minus-low volatility change in next-period debt across the debt
%       grid, at the baseline oil price and after a 10% rise. The full economy
%       deleverages at a set of states; under the correction those declines
%       disappear. One grid step is about 0.2 model units, so points on the zero
%       line mean the policy does not resolve a movement smaller than that.
%
% No dependencies beyond base MATLAB.

function FIGURE_decomposition(indir)

if nargin < 1, indir = '../../results/decomposition_spdebt'; end

A = readtable(fullfile(indir,'panelA_expected_price.csv'));
A = A(1:5,:);
sd = A.sd_log_p; full_ = A.E_p_next_full; mp = A.E_p_next_mean_preserving;
cf = A.closed_form_exp_v_over_2;

D = readtable(fullfile(indir,'table3_decomposition.csv'));
bp = D.spread_bp; ci = D.ci95_bp;
names = {'oil price risk','time-varying vol','pure dispersion','expected price'};

P.full = readtable(fullfile(indir,'panelCD_debt_policy_full.csv'));
P.mp   = readtable(fullfile(indir,'panelCD_debt_policy_meanpres.csv'));

c_full = [0.80 0.20 0.20];
c_mp   = [0.20 0.40 0.80];
c_big  = [0.20 0.45 0.75];
c_sml  = [0.85 0.45 0.15];

figure('Position',[60 60 1180 860],'Color','w');

%% ---- (a) the mean is preserved --------------------------------------
subplot(2,2,1); hold on;
h1 = plot(sd, full_, '-o','LineWidth',3,'Color',c_full,'MarkerFaceColor',c_full,'MarkerSize',7);
h2 = plot(sd, mp,   '-s','LineWidth',3,'Color',c_mp,  'MarkerFaceColor',c_mp,  'MarkerSize',7);
h3 = plot(sd, cf,   'k:','LineWidth',2);
xlabel('conditional sd of $\log p$','FontSize',13,'Interpreter','latex');
ylabel('$E[p'' \mid p = \bar{p}, \sigma]$','FontSize',13,'Interpreter','latex');
s1 = sprintf('%+.2f', 100*(full_(end)-full_(1))/full_(1));
s2 = sprintf('%+.2f', 100*(mp(end)-mp(1))/mp(1));
title(['(a) the mean is preserved: ' s1 '\% $\rightarrow$ ' s2 '\%'], ...
      'FontSize',12,'Interpreter','latex');
legend([h1 h2 h3],{'full SV','mean-preserving','closed form $e^{v/2}$'}, ...
       'Location','northwest','FontSize',11,'Interpreter','latex'); legend boxoff;
set(gca,'FontSize',11,'LineWidth',1.1,'Box','on','TickLabelInterpreter','latex');
grid on; set(gca,'GridAlpha',0.12);

%% ---- (b) the decomposition -------------------------------------------
subplot(2,2,2); hold on;
y = numel(bp):-1:1;
for k = 1:numel(bp)
    col = c_sml; if abs(bp(k)) > ci(k), col = c_big; end
    barh(y(k), bp(k), 0.55, 'FaceColor', col, 'EdgeColor','none');
end
errorbar(bp, y, ci, 'horizontal','k','LineStyle','none','LineWidth',1.5,'CapSize',9);
plot([0 0],[0.4 numel(bp)+0.6],'k-','LineWidth',1.2);
for k = 1:numel(bp)
    text(bp(k)+ci(k)+9, y(k), [sprintf('%+.1f',bp(k)) ' $\pm$' sprintf('%.1f',ci(k))], ...
         'FontSize',10,'Interpreter','latex','VerticalAlignment','middle');
end
set(gca,'YTick',y(end:-1:1),'YTickLabel',names(end:-1:1));
ylim([0.4 numel(bp)+0.6]); xlim([-30 335]);
xlabel('effect on the mean spread (basis points)','FontSize',13,'Interpreter','latex');
% Panel (b)'s title used to assert 'only the level is identified'. That was
% true at sigma_oil = 0.30 and false at 0.25, where three of the four channels
% exclude zero -- a hardcoded claim on a figure that the data had moved past.
% Derive it from the intervals instead, so it cannot go stale again.
ident = abs(bp) > ci;
if all(ident)
    tb = '(b) every channel excludes zero';
elseif ~any(ident)
    tb = '(b) no channel is distinguishable from zero';
else
    tb = sprintf('(b) %d of %d channels exclude zero (not: %s)', ...
                 sum(ident), numel(bp), strjoin(names(~ident), ', '));
end
title(tb,'FontSize',12,'Interpreter','latex');
set(gca,'FontSize',11,'LineWidth',1.1,'Box','on','TickLabelInterpreter','latex');
grid on; set(gca,'GridAlpha',0.12);

%% ---- (c,d) the debt policy -------------------------------------------
prices = {'baseline','oil_plus_10pct'};
titles = {'(c) next-period debt, baseline oil price', ...
          '(d) next-period debt, oil price +10\%'};
for pane = 1:2
    subplot(2,2,2+pane); hold on;
    sel = @(T) T(strcmp(T.price, prices{pane}), :);
    Tf = sel(P.full); Tm = sel(P.mp);
    plot([min(Tf.debt_pct_of_va)-2 max(Tf.debt_pct_of_va)+2],[0 0],'k-','LineWidth',1);
    % jitter the two series horizontally so coincident points stay visible
    g1 = plot(Tf.debt_pct_of_va - 0.18, Tf.delta_grid_nodes, 'o', ...
         'MarkerSize',7,'MarkerFaceColor',c_full,'MarkerEdgeColor','none');
    g2 = plot(Tm.debt_pct_of_va + 0.18, Tm.delta_grid_nodes, 's', ...
         'MarkerSize',7,'MarkerFaceColor',c_mp,'MarkerEdgeColor','none');
    nf = sum(Tf.delta_grid_nodes < 0);
    nm = sum(Tm.delta_grid_nodes < 0);
    xlabel('current debt (\% of annual value added)','FontSize',13,'Interpreter','latex');
    ylabel('$\Delta b''$ (grid nodes), high $-$ low vol','FontSize',13,'Interpreter','latex');
    title(titles{pane},'FontSize',12,'Interpreter','latex');
    legend([g1 g2], {['full SV (' num2str(nf) ' below zero)'], ...
                     ['mean-preserving (' num2str(nm) ' below zero)']}, ...
           'Location','southwest','FontSize',10,'Interpreter','latex'); legend boxoff;
    set(gca,'FontSize',11,'LineWidth',1.1,'Box','on','TickLabelInterpreter','latex');
    grid on; set(gca,'GridAlpha',0.12);
    ylim([-1.6 1.6]); set(gca,'YTick',-1:1);
end

set(findall(gcf,'Type','axes'),'Toolbar',[]);
out = fullfile(indir,'FIGURE_decomposition.jpg');
set(gcf,'PaperPositionMode','auto');
print(gcf, out, '-djpeg','-r200');
fprintf('wrote %s\n', out);
d = dir(out); fprintf('  %.1f kB\n', d.bytes/1000);
end
