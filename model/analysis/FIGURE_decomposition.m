%FIGURE_DECOMPOSITION  The two panels the referees' lead comment needs.
%
%   >> FIGURE_decomposition('../../results/decomposition_spdebt')
%
% Reads the CSVs that model/analysis/decomposition.py writes and draws
% FIGURE_decomposition.jpg beside them.
%
%   panel (a)  E[p' | p = centre node, sigma] against the conditional sd of
%              log p, for the full model and the mean-preserving correction,
%              with the closed-form exp(v/2) overlaid. This is the validation:
%              the full model's conditional expected price rises with
%              volatility exactly as the log-normal arithmetic predicts, and
%              the correction removes it exactly.
%
%   panel (b)  the channel decomposition with 95% intervals and a zero line.
%              The asymmetry is the message: oil price risk is large and
%              precisely estimated, while all three volatility channels have
%              intervals that straddle zero.
%
% No dependencies beyond base MATLAB.

function FIGURE_decomposition(indir)

if nargin < 1, indir = '../../results/decomposition_spdebt'; end

A = readtable(fullfile(indir,'panelA_expected_price.csv'));
A = A(1:5,:);                                  % drop the trailing swing row
sd    = A.sd_log_p;
full  = A.E_p_next_full;
mp    = A.E_p_next_mean_preserving;
cf    = A.closed_form_exp_v_over_2;

D = readtable(fullfile(indir,'table3_decomposition.csv'));
bp  = D.spread_bp;  ci = D.ci95_bp;
names = {'oil price risk', 'time-varying vol', 'pure dispersion', 'expected price'};

c_full = [0.80 0.20 0.20];
c_mp   = [0.20 0.40 0.80];
c_big  = [0.20 0.45 0.75];
c_sml  = [0.85 0.45 0.15];

figure('Position',[100 100 1150 450],'Color','w');

%% ---- panel (a) -------------------------------------------------------
subplot(1,2,1); hold on;
h1 = plot(sd, full, '-o', 'LineWidth', 3, 'Color', c_full, ...
          'MarkerFaceColor', c_full, 'MarkerSize', 7);
h2 = plot(sd, mp,   '-s', 'LineWidth', 3, 'Color', c_mp, ...
          'MarkerFaceColor', c_mp, 'MarkerSize', 7);
h3 = plot(sd, cf,   'k:', 'LineWidth', 2);
xlabel('conditional sd of $\log p$', 'FontSize', 14, 'Interpreter','latex');
ylabel('$E[p'' \mid p = \bar{p}, \sigma]$', 'FontSize', 14, 'Interpreter','latex');
% build by concatenation: sprintf would eat the backslash in \rightarrow, and
% a bare % is a comment to the LaTeX interpreter, so it has to be escaped
s1 = sprintf('%+.3f', 100*(full(end)-full(1))/full(1));
s2 = sprintf('%+.3f', 100*(mp(end)-mp(1))/mp(1));
title(['(a) the mean is preserved: ' s1 '\% $\rightarrow$ ' s2 '\%'], ...
      'FontSize', 13, 'Interpreter','latex');
legend([h1 h2 h3], {'full SV','mean-preserving','closed form $e^{v/2}$'}, ...
       'Location','northwest','FontSize',12,'Interpreter','latex');
legend boxoff;
set(gca,'FontSize',12,'LineWidth',1.1,'Box','on','TickLabelInterpreter','latex');
grid on; set(gca,'GridAlpha',0.12);

%% ---- panel (b) -------------------------------------------------------
subplot(1,2,2); hold on;
y = numel(bp):-1:1;
for k = 1:numel(bp)
    col = c_sml; if abs(bp(k)) > ci(k), col = c_big; end
    barh(y(k), bp(k), 0.55, 'FaceColor', col, 'EdgeColor','none');
end
errorbar(bp, y, ci, 'horizontal', 'k', 'LineStyle','none', ...
         'LineWidth', 1.6, 'CapSize', 10);
plot([0 0], [0.4 numel(bp)+0.6], 'k-', 'LineWidth', 1.2);
for k = 1:numel(bp)
    % clear the error-bar cap, which is wider on the big channel
    off = ci(k) + 9;
    text(bp(k) + off, y(k), ...
         [sprintf('%+.1f', bp(k)) ' $\pm$' sprintf('%.1f', ci(k))], ...
         'FontSize', 11, 'Interpreter','latex', 'VerticalAlignment','middle');
end
set(gca,'YTick', y(end:-1:1), 'YTickLabel', names(end:-1:1));
ylim([0.4 numel(bp)+0.6]);
xlim([-30 330]);
set(findall(gcf,'Type','axes'),'Toolbar',[]);   % keep it out of the export
xlabel('effect on the mean spread (basis points)', 'FontSize', 14, 'Interpreter','latex');
title('(b) only one channel is identified', 'FontSize', 13, 'Interpreter','latex');
set(gca,'FontSize',12,'LineWidth',1.1,'Box','on','TickLabelInterpreter','latex');
grid on; set(gca,'GridAlpha',0.12);

%% ---- save -----------------------------------------------------------
out = fullfile(indir,'FIGURE_decomposition.jpg');
set(gcf,'PaperPositionMode','auto');
print(gcf, out, '-djpeg', '-r200');
fprintf('wrote %s\n', out);
d = dir(out); fprintf('  %.1f kB\n', d.bytes/1000);
end
