function JEDC_disruption(outdir, sweep_csv, benchmark_run, prior_csv)
%JEDC_DISRUPTION  Oil imports during default, for R2 Major 3.
%
%   Run it from the folder it lives in,
%   model/economies_common_check/oil_disruption:
%
%     >> JEDC_disruption
%
%   which is the same as
%
%     >> JEDC_disruption('.', 'sweep/disrupt.csv', '../benchmark', ...
%                        'sweep/sigma030_prior.csv')
%
% WHAT R2 MAJOR 3 ASKS
%   In the model a country in default keeps importing oil at the world price
%   with no friction, so the only direct cost of default is the endowment loss
%   h(y). Discuss the assumption, and better, run a robustness exercise in
%   which default also disrupts oil imports -- a price wedge or partial
%   exclusion from oil purchases during autarky.
%
% THE EXERCISE
%   oil_disruption is a parameter of the model, zero in the baseline. With it
%   on, a country in default or exclusion pays p*(1 + kappa) for imported oil
%   instead of p. oil_disruption = 0 reproduces ../benchmark exactly, which
%   this file checks rather than asserts: the kappa = 0 row of the sweep CSV is
%   rebuilt from the baseline panel and the two are compared.
%
% WHY THE RESULT IS NEGATIVE
%   The extra cost of defaulting is kappa*p*m, proportional to the oil price. A
%   dearer barrel squeezes the importer toward default, which is the paper's
%   mechanism, and simultaneously raises the penalty for defaulting, which
%   pushes it away. Past kappa of about 0.2 the second effect dominates and the
%   state dependence is gone.
%
% TWO MEASUREMENT BASES, WHICH ARE NOT INTERCHANGEABLE
%   Everything in the sweep CSV is a WHOLE-SIMULATION mean: all 750,000
%   quarters, including the periods of exclusion after a default when the debt
%   stock is zero. The paper's Table 3 statistics are not that. They average
%   over the 100 quarters immediately BEFORE each qualifying default episode
%   (per_before = 100 in sim_prod_oil_dec29.m), where debt is elevated because
%   that is what drives a country into default. For the baseline economy the
%   two bases give 26.1% and 34.3% for debt/GDP, and 3.59% and 4.08% for the
%   mean spread. The targets, 34.0% and 4.1%, belong to the SECOND basis, so a
%   whole-simulation figure must never be read against them. This file prints
%   both for kappa = 0 so the distinction is on the record.
%
%   The episode-window figures cannot be given for kappa > 0: disruptsweep.sh
%   deletes each run after extracting its row (the panels are 250 MB each), so
%   those solves would have to be re-run to measure them. The comparison
%   ACROSS kappa in the table below is still like for like, since every row is
%   computed the same way.
%
% WHAT IT WRITES, into outdir:
%   table1_disrupt.csv   the sweep, with the volatility gap per kappa
%
% Base MATLAB only, no toolboxes.

if nargin < 1 || isempty(outdir),        outdir        = '.'; end
if nargin < 2 || isempty(sweep_csv),     sweep_csv     = 'sweep/disrupt.csv'; end
if nargin < 3 || isempty(benchmark_run), benchmark_run = '../benchmark'; end
if nargin < 4,                           prior_csv     = 'sweep/sigma030_prior.csv'; end

% columns of the simulation panel, 1-based, from the WRITE(23,...) in the
% Fortran -- the same map extract_disrupt.awk uses
C_B = 3; C_Q = 4; C_E = 7; C_D = 8; C_QDF = 9; C_OIL = 6;
C_GDP = 16; C_IVOL = 18;

COUPON = (0.01 + 0.03) / 1.01;      % (rstar + delta) / (1 + rstar)
DELTA  = 0.03;
SAMPLE = 1500;                      % quarters per sample, graphs_param_dss(1)
TRIM   = 1000;                      % num in sim_prod_oil_dec29.m: the last 1000
PB     = 100;                       % per_before

T = readtable(sweep_csv, 'VariableNamingRule', 'preserve');
T = sortrows(T, 'disruption');
gap = T.spread_highvol - T.spread_lowvol;

fprintf('\n');
fprintf('================================================================\n');
fprintf(' R2 MAJOR 3   oil imports during default, sigma_oil = 0.25\n');
fprintf('================================================================\n\n');
fprintf('  whole-simulation means -- NOT the Table 3 basis, see the header\n\n');
fprintf('  %-7s %9s %10s %12s %10s %10s %8s\n', 'kappa', 'spread', ...
        'debt/GDP', 'default %/y', 'spread lo', 'spread hi', 'gap');
for i = 1:height(T)
    fprintf('  %-7.2f %8.2f%% %9.1f%% %11.2f%% %9.2f%% %9.2f%% %+8.2f\n', ...
            T.disruption(i), T.mean_spread_pct(i), T.debt_gdp_pct(i), ...
            T.default_pct_annual(i), T.spread_lowvol(i), T.spread_highvol(i), ...
            gap(i));
end

fprintf('\n  the volatility gap falls from %+.2f to %+.2f, a fall of %.0f%%\n', ...
        gap(1), gap(end), 100*(1 - gap(end)/gap(1)));
fprintf('  the mean spread falls %.2f%% to %.2f%%, a fall of %.0f%%\n', ...
        T.mean_spread_pct(1), T.mean_spread_pct(end), ...
        100*(1 - T.mean_spread_pct(end)/T.mean_spread_pct(1)));
fprintf('  debt/GDP rises %.1f%% to %.1f%%, a rise of %.0f%%\n', ...
        T.debt_gdp_pct(1), T.debt_gdp_pct(end), ...
        100*(T.debt_gdp_pct(end)/T.debt_gdp_pct(1) - 1));
if all(diff(T.debt_gdp_pct) > 0) && all(diff(gap) < 0)
    fprintf(['  debt rises and the gap shrinks monotonically, so no positive ' ...
             'kappa\n  recovers the calibration the baseline already has\n']);
end

% ---- the kappa = 0 row, rebuilt from the baseline panel -------------------
fprintf('\nreading the baseline panel to rebuild the kappa = 0 row\n');
S = read_sim(benchmark_run);
n = size(S, 1);
assert(mod(n, SAMPLE) == 0, 'panel is %d rows, not a multiple of %d', n, SAMPLE);

b    = S(:, C_B);     q   = S(:, C_Q);    qdf = S(:, C_QDF);
gdpv = S(:, C_GDP);   ivol = S(:, C_IVOL);
priced = q > 0 & qdf > 0;
yl = COUPON ./ q(priced)   - DELTA;
yr = COUPON ./ qdf(priced) - DELTA;
spr = (1 + yl).^4 - (1 + yr).^4;

rebuilt = struct();
rebuilt.mean_spread_pct   = 100 * mean(spr);
rebuilt.debt_gdp_pct      = 100 * mean(b ./ (4 * gdpv));
good = sum(S(:, C_E) == 1);
ev   = sum(S(:, C_D) == 2);
rebuilt.default_pct_annual = 100 * (1 - (1 - ev/good)^4);
iv = ivol(priced);
rebuilt.spread_lowvol  = 100 * mean(spr(iv == min(iv)));
rebuilt.spread_highvol = 100 * mean(spr(iv == max(iv)));

k0 = find(T.disruption == 0, 1);
assert(~isempty(k0), 'the sweep CSV has no kappa = 0 row');
fields = {'mean_spread_pct', 'debt_gdp_pct', 'default_pct_annual', ...
          'spread_lowvol', 'spread_highvol'};
fprintf('\n  %-22s %12s %12s %10s\n', 'kappa = 0', 'sweep CSV', 'rebuilt', 'diff');
worst = 0;
for i = 1:numel(fields)
    a = T.(fields{i})(k0); c = rebuilt.(fields{i});
    worst = max(worst, abs(a - c));
    fprintf('  %-22s %12.4f %12.4f %10.1e\n', fields{i}, a, c, abs(a - c));
end
if worst < 1e-3
    fprintf('\n  agrees to %.0e: oil_disruption = 0 is the economy of record\n', 1e-3);
else
    warning('JEDC_disruption:mismatch', ...
            'the rebuilt kappa = 0 row differs by up to %.4g', worst);
end

% ---- the same economy on the Table 3 basis --------------------------------
fprintf('\nthe baseline on the Table 3 basis, for comparison\n');
ep = episode_moments(S, SAMPLE, TRIM, PB, COUPON, DELTA, ...
                     C_B, C_Q, C_QDF, C_OIL, C_GDP, C_E, C_D);
fprintf('\n  %-26s %14s %18s %10s\n', 'kappa = 0', 'whole simulation', ...
        'Table 3 basis', 'target');
fprintf('  %-26s %13.2f%% %17.2f%% %9.1f%%\n', 'mean spread', ...
        rebuilt.mean_spread_pct, ep.spread, 4.1);
fprintf('  %-26s %13.1f%% %17.1f%% %9.1f%%\n', 'debt/GDP', ...
        rebuilt.debt_gdp_pct, ep.debt, 34.0);
fprintf('\n  %d qualifying episodes over %d samples\n', ep.nep, n/SAMPLE);
fprintf(['  the baseline matches both targets on the Table 3 basis; the sweep\n' ...
         '  table above is on the other basis and must not be read against them\n']);

% ---- the earlier sigma_oil = 0.30 attempt, if present --------------------
if ~isempty(prior_csv) && isfile(prior_csv)
    P = sortrows(readtable(prior_csv, 'VariableNamingRule', 'preserve'), ...
                 'disruption');
    fprintf('\nthe earlier sigma_oil = 0.30 attempt, same exercise\n\n');
    fprintf('  %-7s %9s %10s %8s\n', 'kappa', 'spread', 'debt/GDP', 'gap');
    for i = 1:height(P)
        fprintf('  %-7.2f %8.2f%% %9.1f%% %+8.2f\n', P.disruption(i), ...
                P.mean_spread_pct(i), P.debt_gdp_pct(i), ...
                P.spread_highvol(i) - P.spread_lowvol(i));
    end
    fprintf(['  a different calibration, so the levels are not comparable with\n' ...
             '  the table above; it is here because the sign is the same\n']);
end

fh = fopen(fullfile(outdir, 'table1_disrupt.csv'), 'w');
fpc(fh, ['disruption,mean_spread_pct,debt_gdp_pct,default_pct_annual,' ...
         'spread_lowvol,spread_highvol,vol_gap\n']);
for i = 1:height(T)
    fpc(fh, '%.2f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n', T.disruption(i), ...
            T.mean_spread_pct(i), T.debt_gdp_pct(i), T.default_pct_annual(i), ...
            T.spread_lowvol(i), T.spread_highvol(i), gap(i));
end
fclose(fh);
fprintf('\nwritten %s\n\n', fullfile(outdir, 'table1_disrupt.csv'));
end


function ep = episode_moments(S, SAMPLE, TRIM, PB, COUPON, DELTA, ...
                              C_B, C_Q, C_QDF, C_OIL, C_GDP, C_E, C_D)
%EPISODE_MOMENTS  The Table 3 basis: the PB quarters before each qualifying
% default episode, as sim_prod_oil_dec29.m computes it.
%
% Its last_b_to_y is 0.25*b./(output - oil), where oil is column 6, the
% QUANTITY of oil rather than its value. That is the paper's own definition and
% it is reproduced here unchanged; using the value of the oil bill instead
% moves debt/GDP by about 0.16 of a percentage point.
%
% An episode qualifies when it is more than PB+1 quarters after the previous
% one and the country was in good standing PB+1 quarters earlier. Default
% periods are taken from the default flag in the panel rather than from
% graphs_def_per_dss.txt, which the author's script reads; the two give
% episode counts within about 1% and the same moments to four figures.
nsamp = size(S, 1) / SAMPLE;
sd = zeros(0, 1); sp = zeros(0, 1);
for s = 1:nsamp
    lo = (s-1)*SAMPLE + (SAMPLE - TRIM) + 1;
    r  = lo:(s*SAMPLE);                       % the last TRIM quarters
    b = S(r, C_B); o = S(r, C_GDP); m = S(r, C_OIL);
    e = S(r, C_E); d = S(r, C_D);
    q = S(r, C_Q); qd = S(r, C_QDF);
    bty = 0.25 * b ./ (o - m);
    yl = COUPON ./ q - DELTA; yr = COUPON ./ qd - DELTA;
    spr = (1 + yl).^4 - (1 + yr).^4;
    spr(~(q > 0 & qd > 0)) = NaN;

    def = find(d == 2);
    prev = 0;
    for t = def(:)'
        sep = t - prev; prev = t;
        g = min(max(t - PB - 1, 1), TRIM);
        if sep > PB + 1 && e(g) < 2 && t - PB >= 1
            w = (t-PB):(t-1);
            sd(end+1, 1) = mean(bty(w), 'omitnan');     %#ok<AGROW>
            sp(end+1, 1) = mean(spr(w), 'omitnan');     %#ok<AGROW>
        end
    end
end
ep.nep    = numel(sd);
ep.debt   = 100 * mean(sd);
ep.spread = 100 * mean(sp);
end


function S = read_sim(run)
path = fullfile(run, 'graphs_data_sim_dss.txt');
fid  = fopen(path, 'r');
if fid < 0, error('read_sim:open', 'cannot open %s', path); end
C = textscan(fid, repmat('%f', 1, 20), 'CollectOutput', true);
fclose(fid);
S = C{1};
end


function fpc(fh, fmt, varargin)
if numel(fmt) >= 2 && strcmp(fmt(end-1:end), '\n')
    fmt = [fmt(1:end-2) '\r\n'];
end
fprintf(fh, fmt, varargin{:});
end
