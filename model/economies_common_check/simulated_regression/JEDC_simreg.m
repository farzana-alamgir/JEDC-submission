function JEDC_simreg(outdir, runs, labels, data_csv)
%JEDC_SIMREG  Regression (1) estimated on model-simulated data, for R2 Major 6.
%
%   Run it from the folder it lives in,
%   model/economies_common_check/simulated_regression:
%
%     >> JEDC_simreg
%
%   which is the same as
%
%     >> JEDC_simreg('.', {'../benchmark','../mean_preserving', ...
%                          '../intermediate','../basic'}, ...
%                    {'full SV','mean-preserving SV', ...
%                     'constant volatility','constant price'})
%
% WHAT R2 MAJOR 6 ASKS
%   "the author could estimate regression (1) on model-simulated data, with
%   volatility in the same units as the empirical measure, so that the model's
%   coefficients can be compared with the empirical ones."
%
% THE UNITS, WHICH ARE THE WHOLE POINT
%   The empirical volatility measure is 100 times the posterior mean standard
%   deviation of the log real oil price, from the stochastic-volatility model in
%   the paper's own script. It runs from 8.86 to 31.58 with a mean of 12.90.
%
%   The simulation records the log variance state, column 20. The conditional
%   standard deviation of the log price is therefore exp(col20/2), and
%   100*exp(col20/2) is the same object in the same units. Over the benchmark
%   panel it takes five values from 8.77 to 20.64 with a mean of 13.79. So the
%   two measures are on one scale without any rescaling, and the coefficients
%   below can be read against Table 1 directly.
%
%   The simulated range is narrower at the top -- 20.6 against 31.6 -- because
%   the data contain 2008 and the volatility grid does not reach that far. That
%   matters for the comparison and is stated in the reply.
%
% THE REGRESSION, AND A TIMING DETAIL THAT MATTERS
%   Regression (1) is the change in the log spread on the volatility level and
%   the change in the log oil price. Here each of the 500 independent simulated
%   histories plays the role a country plays in the panel, so the specification
%   carries history fixed effects and standard errors clustered by history.
%
%   The paper's own regressor is not the contemporaneous price change. In
%   oil_empirical_quarterly_claude.R the variable is built as
%
%       lag_price = lag(log_real_price, 1)
%       op_diff   = c(NA, diff(lag_price))
%
%   so op_diff at t is log p(t-1) - log p(t-2): the price change of the previous
%   quarter. The dependent variable is the contemporaneous change in the log
%   spread. Regression (1) therefore relates this quarter's spread change to
%   last quarter's price change, and a simulated counterpart has to use the same
%   timing or the two coefficients are not comparable. Both are reported below:
%   the lagged one is the comparison the comment asks for, the contemporaneous
%   one is there because the difference between them is itself informative.
%
%   There is no analogue of clustering by quarter. In the data the oil price is
%   one global series shared by every country in a given quarter, which is what
%   makes two-way clustering necessary (R1 Major 1c). Each simulated history
%   draws its own price path, so the regressor is independent across histories
%   and one-way clustering is the right adjustment. That is also why the
%   simulated coefficients are far more precisely estimated than the empirical
%   ones, which is part of the answer to this comment.
%
% WHAT IT WRITES, into outdir:
%   table1_simreg.csv      the coefficients, per economy and per timing
%   table2_comparison.csv  model against data, timing for timing, with the
%                          basis-point translation the comment uses
%
% Base MATLAB only, no toolboxes.

if nargin < 1 || isempty(outdir), outdir = '.'; end
if nargin < 4 || isempty(data_csv)
    data_csv = '../oil_dependence/table6_timing.csv';
end
if nargin < 2 || isempty(runs)
    runs   = {'../benchmark', '../mean_preserving', '../intermediate', '../basic'};
end
if nargin < 3 || isempty(labels)
    labels = {'full SV', 'mean-preserving SV', 'constant volatility', ...
              'constant price'};
end
if ~exist(outdir, 'dir'), mkdir(outdir); end

RSTAR = 0.01; DELTA = 0.03; COUPON = (RSTAR + DELTA)/(1 + RSTAR);
SAMPLE = 1500;            % quarters per independent history; 500 of them
C_Q = 4; C_EXCL = 7; C_D = 8; C_QDF = 9; C_P = 14; C_GDP = 16; C_VOL = 20;
C_B = 3;

% The empirical counterparts are read from the data-side run rather than typed
% in, so the two halves of the comparison cannot drift apart. Run
% JEDC_dependence first; it writes table6_timing.csv.
EMP_SPREAD_BP = 410;        % the mean spread the comment itself uses
if ~exist(data_csv, 'file')
    error('JEDC_simreg:data', ...
          ['%s not found. Run JEDC_dependence in ../oil_dependence first; ' ...
           'it writes the empirical coefficients this file compares against.'], ...
          data_csv);
end
DT = readtable(data_csv, 'VariableNamingRule', 'preserve');

fprintf('\n');
fprintf('================================================================\n');
fprintf(' R2 MAJOR 6   regression (1) on model-simulated data\n');
fprintf('================================================================\n');

R = struct('label', {}, 'timing', {}, 'b', {}, 'se', {}, 'n', {}, 'g', {}, ...
           'spread_bp', {}, 'volmin', {}, 'volmax', {}, 'volmean', {});

for k = 1:numel(runs)
    S = read_sim(runs{k});
    D = build(S, SAMPLE, COUPON, DELTA, C_Q, C_QDF, C_P, C_VOL, C_EXCL, ...
                 C_D, C_B, C_GDP);
    if isempty(D.y)
        fprintf('\n%s: no usable observations, skipped\n', labels{k});
        continue
    end
    fprintf('\n%s  [n = %d over %d histories]\n', labels{k}, D.n, D.g);
    fprintf('  mean spread %.1f bp   volatility %.2f to %.2f, mean %.2f\n', ...
            D.spread_bp, D.volmin, D.volmax, D.volmean);
    fprintf('  mean debt/GDP %.1f%%\n', D.debt_pct);
    for s = 1:4
        switch s
            case 1, X = [D.vol, D.dplag, D.ddebt];
                    tag = 'lagged price change (as the paper), with debt/GDP';
            case 2, X = [D.vol, D.dplag];
                    tag = 'lagged price change (as the paper), no debt/GDP';
            case 3, X = [D.vol, D.dp, D.ddebt];
                    tag = 'contemporaneous price change, with debt/GDP';
            case 4, X = [D.vol, D.dp];
                    tag = 'contemporaneous price change, no debt/GDP';
        end
        % the regressors are constant in the constant-volatility and
        % constant-price economies, so those columns are dropped not inverted
        nc = size(X,2);
        keepcol = false(1,nc);
        for j = 1:nc, keepcol(j) = std(X(:,j)) > 1e-12; end
        bb = nan(1,nc); ss = nan(1,nc);
        if any(keepcol)
            [b, se] = fe_cluster(D.y, X(:,keepcol), D.sid);
            bb(keepcol) = b; ss(keepcol) = se;
        end
        fprintf('  %s\n', tag);
        nm = {'volatility', 'd log oil price', 'd debt/GDP'};
        for j = 1:nc
            if keepcol(j)
                fprintf('    %-16s %+10.4f  (se %.4f)   t %+8.1f\n', nm{j}, ...
                        bb(j), ss(j), bb(j)/ss(j));
            else
                fprintf('    %-16s      --      (no variation in this economy)\n', nm{j});
            end
        end
        b3 = nan(1,3); s3 = nan(1,3);
        b3(1:nc) = bb; s3(1:nc) = ss;
        R(end+1) = struct('label', labels{k}, 'timing', tag, 'b', b3, ...
                          'se', s3, 'n', D.n, 'g', D.g, ...
                          'spread_bp', D.spread_bp, 'volmin', D.volmin, ...
                          'volmax', D.volmax, 'volmean', D.volmean);  %#ok<AGROW>
    end
    clear S D
end

% ---- the comparison the comment asks for --------------------------------
fprintf('\nTHE COMPARISON, TIMING FOR TIMING\n');
fprintf('  Each row pairs the model with the data estimated the same way.\n\n');
fprintf('  %-34s%12s%12s%12s%12s\n', 'timing', 'vol, model', 'vol, data', ...
        'price, model', 'price, data');
CMP = struct('timing', {}, 'vm', {}, 'vd', {}, 'pm', {}, 'pd', {});
for s = 1:2
    if s == 1, key = 'lagged'; else, key = 'contemporaneous'; end
    % compare like with like: both sides controlling for the change in debt/GDP
    im = find(strcmp({R.label}, 'full SV') & contains({R.timing}, key) & ...
              contains({R.timing}, 'with debt'), 1);
    id = find(contains(string(DT.timing), key) & ...
              contains(string(DT.timing), 'with debt'), 1);
    if isempty(im) || isempty(id), continue; end
    fprintf('  %-34s%+12.4f%+12.4f%+12.4f%+12.4f\n', R(im).timing, ...
            R(im).b(1), DT.coef_volatility(id), R(im).b(2), DT.coef_price(id));
    CMP(end+1) = struct('timing', R(im).timing, 'vm', R(im).b(1), ...
                        'vd', DT.coef_volatility(id), 'pm', R(im).b(2), ...
                        'pd', DT.coef_price(id));                  %#ok<AGROW>
end
fprintf('\n  the model as a share of the data, volatility channel\n');
for c = 1:numel(CMP)
    fprintf('    %-34s %.2f\n', CMP(c).timing, CMP(c).vm / CMP(c).vd);
end

% The comment's own arithmetic: a 10% oil price change, read off the price
% coefficient, applied to the mean spread.
fprintf('\n  basis points per 10%% oil price change\n');
im = find(strcmp({R.label}, 'full SV'), 1);
for c = 1:numel(CMP)
    fprintf('    %-34s model %+7.2f bp   data %+7.2f bp\n', CMP(c).timing, ...
            CMP(c).pm * 0.10 * R(im).spread_bp, ...
            CMP(c).pd * 0.10 * EMP_SPREAD_BP);
end

% ---- files ---------------------------------------------------------------
fh = fopen(fullfile(outdir, 'table1_simreg.csv'), 'w');
fpc(fh, ['economy,timing,coef_volatility,se_volatility,coef_dlog_oil_price,' ...
         'se_dlog_oil_price,coef_ddebt_gdp,se_ddebt_gdp,n,histories,' ...
         'mean_spread_bp,vol_min,vol_max,vol_mean\n']);
for k = 1:numel(R)
    fpc(fh, '%s,%s,%s,%s,%s,%s,%s,%s,%d,%d,%.2f,%.4f,%.4f,%.4f\n', ...
            csvq(R(k).label), csvq(R(k).timing), ...
            num(R(k).b(1)), num(R(k).se(1)), num(R(k).b(2)), num(R(k).se(2)), ...
            num(R(k).b(3)), num(R(k).se(3)), ...
            R(k).n, R(k).g, R(k).spread_bp, R(k).volmin, R(k).volmax, ...
            R(k).volmean);
end
fclose(fh);

fh = fopen(fullfile(outdir, 'table2_comparison.csv'), 'w');
fpc(fh, ['timing,vol_model,vol_data,vol_ratio,price_model,price_data,' ...
         'bp_per_10pct_model,bp_per_10pct_data\n']);
for c = 1:numel(CMP)
    fpc(fh, '%s,%.6f,%.6f,%.4f,%.6f,%.6f,%.3f,%.3f\n', csvq(CMP(c).timing), ...
            CMP(c).vm, CMP(c).vd, CMP(c).vm/CMP(c).vd, CMP(c).pm, CMP(c).pd, ...
            CMP(c).pm*0.10*R(im).spread_bp, CMP(c).pd*0.10*EMP_SPREAD_BP);
end
fclose(fh);

fprintf('\nwritten into %s\n  table1_simreg.csv  table2_comparison.csv\n\n', outdir);
end


function D = build(S, SAMPLE, COUPON, DELTA, C_Q, C_QDF, C_P, C_VOL, C_EXCL, ...
                   C_D, C_B, C_GDP)
%BUILD  The regression sample: one observation per usable quarter-to-quarter step.
n = size(S,1);

y   = COUPON ./ S(:,C_Q)   - DELTA;
yrf = COUPON ./ S(:,C_QDF) - DELTA;
sp  = 100 * ((1+y).^4 - (1+yrf).^4);                 % percent, as in the paper
ok  = S(:,C_Q) > 0 & S(:,C_QDF) > 0 & sp > 0;

lp  = log(S(:,C_P));
vol = 100 * exp(S(:,C_VOL)/2);                       % the empirical units
% The paper's preferred specification controls for the change in debt to GDP
% (dy_diff, which is diff of 100*CommPubG/GDP, a ratio to ANNUAL GDP). The
% simulation is quarterly, so the counterpart divides by four times quarterly
% output to put the two on one scale: the model then averages about 26% of
% annual GDP against 0 to 25.3% for the data series. The aggregates still
% differ -- the model's b is all external debt, the data's dy3 only commercial
% public and publicly guaranteed debt -- so this makes the SPECIFICATIONS
% comparable, not the series.
dg  = 100 * S(:,C_B) ./ (4 * S(:,C_GDP));
good = S(:,C_EXCL) == 1 & S(:,C_D) ~= 2;             % in good standing, not defaulting

% An observation sits at row t and needs rows t-1 and t-2, all three inside the
% same 1,500-quarter history, with the spread usable at t and t-1 and the
% country in good standing at both.
h = ceil((1:n)' / SAMPLE);
t = (3:n)';
same  = h(t) == h(t-1) & h(t) == h(t-2);
usable = same & ok(t) & ok(t-1) & good(t) & good(t-1);

D.y     = log(sp(t)) - log(sp(t-1));
D.vol   = vol(t);
D.dp    = lp(t)   - lp(t-1);      % contemporaneous
D.dplag = lp(t-1) - lp(t-2);      % the paper's op_diff
D.ddebt = dg(t) - dg(t-1);        % the counterpart of dy_diff
D.sid   = h(t);
D.y = D.y(usable); D.vol = D.vol(usable); D.dp = D.dp(usable);
D.dplag = D.dplag(usable); D.ddebt = D.ddebt(usable); D.sid = D.sid(usable);
D.debt_pct = mean(dg(ok));
D.n = numel(D.y); D.g = numel(unique(D.sid));
D.spread_bp = 100 * mean(sp(ok));                    % percent -> basis points
D.volmin  = min(vol);  D.volmax = max(vol);  D.volmean = mean(vol);
end


function [b, se] = fe_cluster(y, X, sid)
%FE_CLUSTER  History fixed effects, standard errors clustered by history.
[~, ~, gi] = unique(sid);
g = max(gi);
yd = demean(y, gi);
Xd = zeros(size(X));
for j = 1:size(X,2), Xd(:,j) = demean(X(:,j), gi); end
XX = Xd' * Xd;
b  = XX \ (Xd' * yd);
e  = yd - Xd * b;
k  = size(Xd,2);
M  = zeros(k);
for i = 1:g
    m = (gi == i);
    s = Xd(m,:)' * e(m);
    M = M + s * s';
end
V  = (XX \ ((g/(g-1)) * M)) / XX;
se = sqrt(max(diag(V), 0));
end


function v = demean(v, gi)
s = accumarray(gi, v);
c = accumarray(gi, 1);
v = v - s(gi) ./ c(gi);
end


function S = read_sim(run)
path = fullfile(run, 'graphs_data_sim_dss.txt');
fid  = fopen(path, 'r');
if fid < 0, error('read_sim:open', 'cannot open %s', path); end
C = textscan(fid, repmat('%f', 1, 20), 'CollectOutput', true);
fclose(fid);
S = C{1};
if size(S,2) ~= 20
    error('read_sim:shape', '%s has %d columns, expected 20', path, size(S,2));
end
end


function s = num(x)
if isnan(x), s = ''; else, s = sprintf('%.6f', x); end
end


function s = csvq(s)
if any(s == ',') || any(s == '"') || any(s == char(10)) || any(s == char(13))
    s = ['"' strrep(s, '"', '""') '"'];
end
end


function fpc(fh, fmt, varargin)
if numel(fmt) >= 2 && strcmp(fmt(end-1:end), '\n')
    fmt = [fmt(1:end-2) '\r\n'];
end
fprintf(fh, fmt, varargin{:});
end
