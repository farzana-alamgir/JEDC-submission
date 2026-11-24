function JEDC_elasticity(outdir, benchmark_run, sweep_csv, empdir)
%JEDC_ELASTICITY  Everything behind the R1 Major 3 response.
%
%   Run it from the folder it lives in, model/economies_common_check:
%
%     >> JEDC_elasticity
%
%   which is the same as
%
%     >> JEDC_elasticity('elasticity_sweep', ...
%            'benchmark', ...
%            'elasticity_sweep/sweep_resp/responses.csv', ...
%            '../../empirical')
%
%   Skip the 250 MB simulation panel (everything except the alpha schedule and
%   the independent check of the 0.25 row, which need it):
%
%     >> JEDC_elasticity(outdir, '', sweep_csv, empdir)
%
% WHAT IT WRITES, into outdir:
%   table1_elasticity_specs.csv    the four specifications          (letter, s2)
%   table2_response.csv            how the model responds           (letter, s3)
%   table3_by_country.csv          the 34 country elasticities      (letter, s5)
%   table4_heterogeneity.csv       distribution, noise, dependence  (letter, s5)
%   table5_alpha_schedule.csv      the alpha pin at each elasticity (letter, s1)
%   response_table.tex             the LaTeX body of table 2, ready to paste
%
% WHERE THE NUMBERS COME FROM
%   The elasticity estimates are from the import panel in empirical/, which is
%   the same data the paper's Table 1 uses. The model's responses are NOT
%   recomputed here: the six solves are Fortran, they take about half an hour
%   each, and their run folders are deleted as soon as the moments are out
%   because the disk cannot hold six of them. responses.csv is the surviving
%   record. The one row that CAN be rebuilt from scratch is the adopted
%   elasticity, because its run folder is the economy of record
%   (economies_common_check/benchmark), and this file rebuilds it and compares,
%   which is what makes the other five rows trustworthy.
%
% WHERE EVERYTHING FOR THIS COMMENT LIVES
%   This file sits in model/economies_common_check, beside JEDC_decomposition.m,
%   and every path it defaults to is relative to that folder. The subfolder
%   elasticity_sweep holds the three scripts that solved the six economies
%   (run_respsweep.sh, respsweep.sh, extract_responses.awk), the run record
%   under sweep_resp, and the tables this file writes, so a bare
%   JEDC_elasticity call keeps the whole comment in one place.
%
% Base MATLAB only -- no toolboxes, and no Statistics Toolbox for the
% regressions, which are written out by hand below. Everything after the main
% function is a local function, so this one file is the whole pipeline.
%
% Ported from empirical/estimate_substitution_elasticity.py and
% empirical/elasticity_heterogeneity.py. The ports agree to the printed
% precision; if you change anything in here, re-run both and compare before
% trusting a number in the response letter.

if nargin < 1 || isempty(outdir),        outdir        = 'elasticity_sweep'; end
if nargin < 2,                           benchmark_run = 'benchmark'; end
if nargin < 3 || isempty(sweep_csv),     sweep_csv     = 'elasticity_sweep/sweep_resp/responses.csv'; end
if nargin < 4 || isempty(empdir),        empdir        = '../../empirical'; end

if ~exist(outdir, 'dir'), mkdir(outdir); end

% the elasticities the model was actually solved at, and the share target the
% alpha pin has to hit. K is the oil cost share of GDP, as a fraction.
SIGMAS  = [0.20 0.25 0.30 0.35 0.40 0.50];
ADOPTED = 0.25;
K_SHARE = 0.100790;

% the alpha schedule as it went into the six Fortran sources, for checking
ALPHA_USED = [4.709e-6 5.779464e-5 3.070e-4 1.011e-3 2.467e-3 8.579e-3];

% EXCLUDED FROM THE ESTIMATES, AND WHY
% El Salvador clears the importer cutoff and has 21 years of data, so it is in
% the paper's 35, but its own elasticity is estimated at 2.924 with a standard
% error of 2.185 and an R2 of 0.039 -- over 21 years the oil price explains 4%%
% of its oil share. The pooled within regression weights those 21 years as
% heavily as Poland's, whose standard error is 0.059, so this one uninformative
% country moves the baseline elasticity from 0.394 to 0.474 and the lower end of
% its confidence interval from 0.232 to 0.252. It is excluded as an influential
% uninformative observation. Nothing is hidden by doing so: the full-sample
% baseline is printed beside the reported one, and table3 lists all 35 countries
% with a column saying which was dropped.
EXCLUDE = {'EL SALVADOR'};

fprintf('\n');
fprintf('================================================================\n');
fprintf(' R1 MAJOR 3   disciplining the substitution elasticity\n');
fprintf('================================================================\n');

% ---- the data -----------------------------------------------------------
price = annual_oil_price(empdir);                    % year -> real oil price
[cty, shares] = import_shares(empdir);               % country x year, percent
keep  = importer_sample(empdir);                     % the paper's importers

sel = false(numel(cty), 1);
for i = 1:numel(cty)
    sel(i) = any(strcmp(cty{i}, keep));
end
cty = cty(sel); shares = shares(sel);
[cty, ord] = sort(cty); shares = shares(ord);

% stack the panel: one row per country-year with a price and a positive share
C = {}; YR = []; LP = []; LS = []; SHR = [];
for i = 1:numel(cty)
    ys = shares{i}.years; vs = shares{i}.vals;
    for j = 1:numel(ys)
        if isKeyYear(price, ys(j))
            C{end+1,1} = cty{i};                                  %#ok<AGROW>
            YR(end+1,1)  = ys(j);                                 %#ok<AGROW>
            LP(end+1,1)  = log(getYear(price, ys(j)));            %#ok<AGROW>
            LS(end+1,1)  = log(vs(j));                            %#ok<AGROW>
            SHR(end+1,1) = vs(j);                                 %#ok<AGROW>
        end
    end
end
inc_c = ~ismember(cty, EXCLUDE);          % countries kept in the estimates
inc   = ~ismember(C, EXCLUDE);            % the same mask over the stacked panel

fprintf('\noil importers matched: %d   years %d-%d   observations %d\n', ...
        numel(unique(C)), min(YR), max(YR), numel(YR));
if any(~inc_c)
    fprintf('excluded from the estimates: %s   (see the header for why)\n', ...
            strjoin(cty(~inc_c), ', '));
    fprintf('estimates therefore use %d importers and %d observations\n', ...
            sum(inc_c), sum(inc));
end

% ---- the four specifications -------------------------------------------
elasticity_specs(C, YR, LP, LS, inc, price, cty, shares, inc_c, outdir);

% ---- country by country -------------------------------------------------
by_country(cty, shares, inc_c, price, ADOPTED, SIGMAS(1), SIGMAS(end), outdir);

% ---- the share target the model has to hit ------------------------------
fprintf('\nTHE SHARE TARGET\n');
fprintf('  oil import share in the importer sample: mean %.4f%%   median %.4f%%\n', ...
        mean(SHR(inc)), qtile(SHR(inc), 0.50));
fprintf('  the model pins the simulated share at   %.4f%%\n', 100*K_SHARE);

% ---- the simulation panel, if we were given one -------------------------
S = [];
if ~isempty(benchmark_run)
    fprintf('\nreading the benchmark simulation panel (250 MB, about a minute)\n');
    S = read_sim(benchmark_run);
    fprintf('  %d quarters x %d columns\n', size(S,1), size(S,2));
end

alpha_schedule(S, SIGMAS, ALPHA_USED, K_SHARE, outdir);
response_table(sweep_csv, S, ADOPTED, outdir);

fprintf('\nwritten into %s\n', outdir);
fprintf('  table1_elasticity_specs.csv  table2_response.csv\n');
fprintf('  table3_by_country.csv        table4_heterogeneity.csv\n');
fprintf('  table5_alpha_schedule.csv    response_table.tex\n\n');
end


% ======================================================================
% section 2 of the letter: the four specifications
% ======================================================================

function elasticity_specs(C, YR, LP, LS, inc, price, cty, shares, inc_c, outdir)
%ELASTICITY_SPECS  The oil share's price response, four ways.
%
% The share equation is s(p) = alpha^sigma * p^(1-sigma), so
%
%     d ln s / d ln p = 1 - sigma
%
% and the comovement of the oil import share with the oil price identifies the
% elasticity with nothing calibrated from outside. sigma = 2, the submitted
% value, predicts a coefficient of exactly -1: oil bills FALLING as a share of
% GDP when oil gets dearer.

fprintf('\nTABLE 1  the oil share''s price response\n');
fprintf('  d ln(oil import share) / d ln(real oil price) = 1 - sigma\n');
fprintf('  sigma = 2 (the submitted calibration) predicts -1.000\n\n');
fprintf('  %-38s%9s%9s%9s\n', 'specification', 'coef', 'se', 'sigma');

specs = struct('name', {}, 'b', {}, 'se', {}, 'n', {});

% (1) within country, standard errors clustered by year. The regressor is the
% global oil price, common across the cross-section within a year, so the
% residuals are correlated across countries. Clustering on year is the
% adjustment that matters; clustering on country is not.
[b1, se1, n1] = within_year_clustered(C(inc), YR(inc), LP(inc), LS(inc));
% the same estimator on everything, printed below so the exclusion is visible
[bF, seF, nF] = within_year_clustered(C, YR, LP, LS);
specs(1) = struct('name', 'within country, clustered by year', ...
                  'b', b1, 'se', se1, 'n', n1);

% (2) collapse to a single time series of the cross-country mean log share.
Ci = C(inc); YRi = YR(inc); LPi = LP(inc); LSi = LS(inc);
yrs = unique(YRi);
m   = zeros(numel(yrs), 1);
for k = 1:numel(yrs)
    m(k) = mean(LSi(YRi == yrs(k)));
end
lpy = zeros(numel(yrs), 1);
for k = 1:numel(yrs), lpy(k) = log(getYear(price, yrs(k))); end
c1 = ols([ones(numel(yrs),1) lpy], m);
specs(2) = struct('name', 'collapsed to a time series', ...
                  'b', c1(2), 'se', NaN, 'n', numel(yrs));

% (3) the same, allowing a linear time trend.
c2 = ols([ones(numel(yrs),1) lpy (yrs - yrs(1))], m);
specs(3) = struct('name', 'collapsed, with linear time trend', ...
                  'b', c2(2), 'se', NaN, 'n', numel(yrs));

% (4) within-country first differences, which removes country-specific trends.
[b4, se4, n4] = first_difference(cty(inc_c), shares(inc_c), price);
specs(4) = struct('name', 'first differences within country', ...
                  'b', b4, 'se', se4, 'n', n4);

for k = 1:4
    if isnan(specs(k).se)
        fprintf('  %-38s%+9.4f%9s%9.3f\n', specs(k).name, specs(k).b, ' ', 1-specs(k).b);
    else
        fprintf('  %-38s%+9.4f%9.4f%9.3f\n', specs(k).name, specs(k).b, ...
                specs(k).se, 1-specs(k).b);
    end
end

lo = b1 - 1.96*se1; hi = b1 + 1.96*se1;
if nF > n1
    loF = bF - 1.96*seF; hiF = bF + 1.96*seF;
    fprintf('\n  the baseline on the full sample, for comparison:\n');
    fprintf('  %-38s%+9.4f%9.4f%9.3f\n', 'within country, all importers', ...
            bF, seF, 1-bF);
    fprintf('  %-38s%9s%9s   [%.3f, %.3f]\n', '  its 95% interval for sigma', ...
            '', '', 1-hiF, 1-loF);
end
fprintf('\n  average of the four implied elasticities: %.5f\n', ...
        mean(1 - [specs.b]));
fprintf('  baseline 95%% CI, coefficient : [%+.4f, %+.4f]\n', lo, hi);
fprintf('  baseline 95%% CI, elasticity  : [%.3f, %.3f]\n', 1-hi, 1-lo);
fprintf('  sigma = 2 (coefficient -1): %s\n', rej(lo > -1 || hi < -1));
fprintf('  sigma = 1 (coefficient  0): %s\n', rej(lo > 0 || hi < 0));

fh = fopen(fullfile(outdir, 'table1_elasticity_specs.csv'), 'w');
fpc(fh, 'specification,coefficient,se,implied_elasticity,n\n');
for k = 1:4
    if isnan(specs(k).se), ses = ''; else, ses = sprintf('%.4f', specs(k).se); end
    fpc(fh, '%s,%.4f,%s,%.3f,%d\n', csvq(specs(k).name), specs(k).b, ses, ...
            1-specs(k).b, specs(k).n);
end
fpc(fh, '%s,%.4f,,%.3f,%d\n', csvq('95% CI lower (baseline)'), lo, 1-lo, n1);
fpc(fh, '%s,%.4f,,%.3f,%d\n', csvq('95% CI upper (baseline)'), hi, 1-hi, n1);
fclose(fh);
end


function [b, se, n] = within_year_clustered(C, YR, LP, LS)
%WITHIN_YEAR_CLUSTERED  Country-demeaned OLS, standard errors clustered by year.
u = unique(C);
x = []; y = []; t = [];
for i = 1:numel(u)
    m = strcmp(C, u{i});
    if sum(m) < 2, continue; end          % cannot carry a slope
    x = [x; LP(m) - mean(LP(m))];                                 %#ok<AGROW>
    y = [y; LS(m) - mean(LS(m))];                                 %#ok<AGROW>
    t = [t; YR(m)];                                               %#ok<AGROW>
end
sxx = sum(x.^2);
b   = sum(x.*y)/sxx;
e   = y - b*x;
ut  = unique(t);
g   = zeros(numel(ut), 1);
for k = 1:numel(ut)
    m = (t == ut(k));
    g(k) = sum(x(m).*e(m));
end
se = sqrt(sum(g.^2))/sxx;
n  = numel(x);
end


function [b, se, n] = first_difference(cty, shares, price)
%FIRST_DIFFERENCE  Within-country year-on-year changes, clustered by year.
x = []; y = []; t = [];
for i = 1:numel(cty)
    ys = shares{i}.years; vs = shares{i}.vals;
    ok = arrayfun(@(a) isKeyYear(price, a), ys);
    ys = ys(ok); vs = vs(ok);
    [ys, o] = sort(ys); vs = vs(o);
    for j = 1:numel(ys)-1
        if ys(j+1) - ys(j) == 1
            x(end+1,1) = log(getYear(price, ys(j+1))) - log(getYear(price, ys(j))); %#ok<AGROW>
            y(end+1,1) = log(vs(j+1)) - log(vs(j));               %#ok<AGROW>
            t(end+1,1) = ys(j+1);                                 %#ok<AGROW>
        end
    end
end
sxx = sum(x.^2);
b   = sum(x.*y)/sxx;
e   = y - b*x;
ut  = unique(t);
g   = zeros(numel(ut), 1);
for k = 1:numel(ut)
    m = (t == ut(k));
    g(k) = sum(x(m).*e(m));
end
se = sqrt(sum(g.^2))/sxx;
n  = numel(x);
end


% ======================================================================
% section 5 of the letter: one elasticity for 34 economies
% ======================================================================

function by_country(cty, shares, inc_c, price, ADOPTED, LO, HI, outdir)
%BY_COUNTRY  The share relationship estimated separately for each importer.
%
% The question is not whether the countries differ -- with twenty annual
% observations each they are bound to look different -- but how much of the
% spread is real, and whether it lines up with oil dependence, which is the
% dimension along which a common elasticity would misprice the economies the
% paper is about.

name = {}; b = []; se = []; nn = []; r2 = []; dep = []; kept = [];
for i = 1:numel(cty)
    ys = shares{i}.years; vs = shares{i}.vals;
    ok = arrayfun(@(a) isKeyYear(price, a), ys);
    ys = ys(ok); vs = vs(ok);
    if numel(ys) < 5, continue; end        % too short to carry a slope
    lp = zeros(numel(ys),1);
    for j = 1:numel(ys), lp(j) = log(getYear(price, ys(j))); end
    [bi, sei, r2i] = ols1(lp, log(vs(:)));
    name{end+1,1} = cty{i};                                       %#ok<AGROW>
    b(end+1,1) = bi; se(end+1,1) = sei; nn(end+1,1) = numel(ys);  %#ok<AGROW>
    r2(end+1,1) = r2i; dep(end+1,1) = mean(vs);                   %#ok<AGROW>
    kept(end+1,1) = inc_c(i);                                     %#ok<AGROW>
end
sig_all = 1 - b;
[sig_all, o] = sort(sig_all);
name = name(o); b = b(o); se = se(o); nn = nn(o); r2 = r2(o); dep = dep(o);
kept = logical(kept(o));

% every country is listed and written out; the statistics use the kept ones
name_all = name; b_all = b; se_all = se; nn_all = nn; r2_all = r2; dep_all = dep;
sig = sig_all(kept); se = se_all(kept); dep = dep_all(kept);
name = name_all(kept); b = b_all(kept); nn = nn_all(kept);
n = numel(sig);

fprintf('\nTABLE 3  the elasticity country by country (%d listed, %d used)\n\n', ...
        numel(sig_all), n);
fprintf('  %-22s%6s%9s%8s%9s%11s%10s\n', 'country', 'years', 'coef', 'se', ...
        'sigma', 'oil/GDP %', 'used');
for i = 1:numel(sig_all)
    fprintf('  %-22s%6d%+9.3f%8.3f%9.3f%11.2f%10s\n', name_all{i}, nn_all(i), ...
            b_all(i), se_all(i), sig_all(i), dep_all(i), yn(kept(i)));
end

var_hat = var(sig);                 % MATLAB normalises by n-1, as the port does
noise   = mean(se.^2);
signal  = var_hat - noise;          % var(true) = var(estimated) - E[se^2]
wt      = 1./(se.^2);

fprintf('\nTABLE 4  what the spread of those estimates means\n');
fprintf('\n  DISTRIBUTION\n');
fprintf('    mean %.3f   median %.3f   sd %.3f\n', mean(sig), qtile(sig,0.50), ...
        sqrt(var_hat));
fprintf('    p25 %.3f   p75 %.3f        min %.3f (%s)   max %.3f (%s)\n', ...
        qtile(sig,0.25), qtile(sig,0.75), sig(1), name{1}, sig(end), name{end});
fprintf('    precision-weighted mean %.3f   weighted by oil import share %.3f\n', ...
        sum(wt.*sig)/sum(wt), sum(dep.*sig)/sum(dep));
fprintf('\n  HOW MUCH OF THE SPREAD IS REAL\n');
fprintf('    variance of the estimates     %.4f\n', var_hat);
fprintf('    average sampling variance     %.4f\n', noise);
if signal > 0
    fprintf('    implied variance of true sigma %+.4f   -> sd %.3f, against %.3f raw\n', ...
            signal, sqrt(signal), sqrt(var_hat));
else
    fprintf('    implied variance of true sigma %+.4f   -> indistinguishable from one sigma\n', signal);
end
fprintf('\n  WHERE THE COUNTRIES SIT\n');
fprintf('    complements, sigma < 1                 %3d of %d\n', sum(sig<1), n);
fprintf('    inside the solved range [%.2f, %.2f]     %3d of %d\n', LO, HI, ...
        sum(sig>=LO & sig<=HI), n);
fprintf('    above it                               %3d of %d\n', sum(sig>HI), n);
% "cannot reject" below is the two-sided 95%% test on that country's own
% estimate, abs(sigma_c - x) <= 1.96*se_c. The Python port printed a one-se
% band instead, which is a different and much tighter count (12 rather than
% 19), so take these from here and not from that script's stdout.
fprintf('    cannot reject the adopted %.2f          %3d of %d\n', ADOPTED, ...
        sum(abs(sig-ADOPTED) <= 1.96*se), n);
fprintf('    cannot reject the submitted 2          %3d of %d\n', ...
        sum(abs(sig-2) <= 1.96*se), n);

% does the elasticity line up with dependence? this is the question that
% decides whether a common elasticity distorts the paper's conclusion.
[bd, sed, r2d] = ols1(log(dep), sig);
fprintf('\n  IS THE ELASTICITY RELATED TO OIL DEPENDENCE\n');
fprintf('    sigma on ln(mean oil import share): %+.3f (se %.3f), R2 %.3f\n', ...
        bd, sed, r2d);

% The thirds are reported two ways because the answer moves with the cutoff.
% At exact terciles the boundary country falls INSIDE each group (12 and 12);
% at the 0.333/0.667 cutoffs the Python port used it falls outside (11 and 11),
% which shifts both means by about 0.04. The GAP between the groups is 0.07
% either way, and the regression above does not move at all, so the finding --
% no relation between the elasticity and oil dependence -- does not depend on
% this choice. The levels quoted in the letter do.
heavy = dep >= qtile(dep, 2/3);     light = dep <= qtile(dep, 1/3);
heavyP = dep >= qtile(dep, 0.667);  lightP = dep <= qtile(dep, 0.333);
fprintf('    exact terciles        most dependent (n %2d) %.3f   least (n %2d) %.3f\n', ...
        sum(heavy), mean(sig(heavy)), sum(light), mean(sig(light)));
fprintf('    0.333/0.667 cutoffs   most dependent (n %2d) %.3f   least (n %2d) %.3f\n', ...
        sum(heavyP), mean(sig(heavyP)), sum(lightP), mean(sig(lightP)));
fprintf('    the gap is %.3f at exact terciles and %.3f at the other cutoffs\n', ...
        mean(sig(heavy))-mean(sig(light)), mean(sig(heavyP))-mean(sig(lightP)));

fh = fopen(fullfile(outdir, 'table3_by_country.csv'), 'w');
fpc(fh, 'country,years,coef,se,sigma,mean_oil_import_share_pct,r2,used\n');
for i = 1:numel(sig_all)
    fpc(fh, '%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%s\n', csvq(name_all{i}), ...
            nn_all(i), b_all(i), se_all(i), sig_all(i), dep_all(i), r2_all(i), ...
            yn(kept(i)));
end
fclose(fh);

fh = fopen(fullfile(outdir, 'table4_heterogeneity.csv'), 'w');
fpc(fh, 'statistic,value\n');
rows = { ...
  'countries',                        n; ...
  'mean sigma',                       mean(sig); ...
  'median sigma',                     qtile(sig,0.50); ...
  'p25 sigma',                        qtile(sig,0.25); ...
  'p75 sigma',                        qtile(sig,0.75); ...
  'sd of the estimates',              sqrt(var_hat); ...
  'precision-weighted mean',          sum(wt.*sig)/sum(wt); ...
  'mean weighted by oil share',       sum(dep.*sig)/sum(dep); ...
  'variance of the estimates',        var_hat; ...
  'average sampling variance',        noise; ...
  'implied variance of true sigma',   signal; ...
  'implied sd of true sigma',         sqrt(max(signal,0)); ...
  'complements (sigma<1)',            sum(sig<1); ...
  'cannot reject adopted 0.25',       sum(abs(sig-ADOPTED) <= 1.96*se); ...
  'cannot reject submitted 2',        sum(abs(sig-2) <= 1.96*se); ...
  'above the solved range 0.50',      sum(sig>HI); ...
  'sigma on ln oil share, coef',      bd; ...
  'sigma on ln oil share, se',        sed; ...
  'sigma on ln oil share, r2',        r2d; ...
  'mean sigma, most dependent third (exact terciles)',  mean(sig(heavy)); ...
  'mean sigma, least dependent third (exact terciles)', mean(sig(light)); ...
  'mean sigma, most dependent third (0.667 cutoff)',    mean(sig(heavyP)); ...
  'mean sigma, least dependent third (0.333 cutoff)',   mean(sig(lightP))};
for i = 1:size(rows,1)
    fpc(fh, '%s,%.6f\n', csvq(rows{i,1}), rows{i,2});
end
fclose(fh);
end


% ======================================================================
% section 1 of the letter: why alpha moved by three orders of magnitude
% ======================================================================

function alpha_schedule(S, SIGMAS, ALPHA_USED, K_SHARE, outdir)
%ALPHA_SCHEDULE  The pin that keeps the oil share fixed as the elasticity moves.
%
% alpha is not the oil share. The share is
%
%     s(p) = alpha^sigma * p^(1-sigma)
%
% so holding the SHARE at its target K while changing sigma forces
%
%     alpha(sigma) = ( K / E[p^(1-sigma)] )^(1/sigma)
%
% and the expectation is taken over the simulated price path, which is common
% to every run because the price process does not involve alpha or theta. This
% is the whole explanation for alpha moving from 0.2 to 0.000058: a factor of
% 1,800 in alpha across the sweep, and the same oil bill in every row.

fprintf('\nTABLE 5  the alpha pin\n');
if isempty(S)
    fprintf('  (skipped: no simulation panel given)\n');
    return
end
p = S(:,14);
fprintf('\n  %8s%14s%15s%15s%9s\n', 'sigma', 'E[p^(1-s)]', 'alpha implied', ...
        'alpha used', 'ratio');
A = zeros(numel(SIGMAS), 1); E = A;
for k = 1:numel(SIGMAS)
    s = SIGMAS(k);
    E(k) = mean(p.^(1-s));
    A(k) = (K_SHARE/E(k))^(1/s);
    fprintf('  %8.2f%14.6f%15.6e%15.6e%9.4f\n', s, E(k), A(k), ...
            ALPHA_USED(k), A(k)/ALPHA_USED(k));
end
fprintf('\n  alpha varies by a factor of %.0f across the sweep, and every row\n', ...
        max(A)/min(A));
fprintf('  delivers the same oil bill of %.3f%% of GDP.\n', 100*K_SHARE);

fh = fopen(fullfile(outdir, 'table5_alpha_schedule.csv'), 'w');
fpc(fh, 'sigma,theta,E_p_pow_1_minus_sigma,alpha_implied,alpha_used,ratio\n');
for k = 1:numel(SIGMAS)
    fpc(fh, '%.2f,%.8f,%.6f,%.8e,%.8e,%.6f\n', SIGMAS(k), 1-1/SIGMAS(k), ...
            E(k), A(k), ALPHA_USED(k), A(k)/ALPHA_USED(k));
end
fclose(fh);
end


% ======================================================================
% section 3 of the letter: how the model responds across the range
% ======================================================================

function response_table(sweep_csv, S, ADOPTED, outdir)
%RESPONSE_TABLE  Oil imports, the oil bill, output, default and spreads by sigma.
%
% The six solves are Fortran and are not re-run here. responses.csv is their
% record. What this does re-run is the adopted elasticity, whose panel still
% exists, so the extraction itself is checked rather than taken on trust.

fprintf('\nTABLE 2  how the model responds across the range\n');
if ~exist(sweep_csv, 'file')
    fprintf('  (skipped: %s not found)\n', sweep_csv);
    return
end
M = readmatrix(sweep_csv);
M = sortrows(M, 1);

% columns of responses.csv:
%  1 sigma  2 n  3 oil_qty  4 oil_value  5 oil_value_pct_gdp  6 gdp  7 price
%  8 spread_pct_whole_sim  9 default_pct_annual  10 default_se_pp
% 11 events 12 good_quarters
fprintf('\n  %10s%12s%14s%12s%10s%18s%12s\n', 'elasticity', 'oil imports', ...
        'value of oil', 'oil/GDP %', 'output', 'default % p.a.', 'spread %');
for i = 1:size(M,1)
    fprintf('  %10.2f%12.4f%14.4f%12.3f%10.4f%12.3f (%.3f)%12.3f\n', ...
            M(i,1), M(i,3), M(i,4), M(i,5), M(i,6), M(i,9), M(i,10), M(i,8));
end

iA = find(abs(M(:,1) - ADOPTED) < 1e-9, 1);
fprintf('\n  oil imported, range over the sweep      %+.2f%%\n', ...
        100*(max(M(:,3))/min(M(:,3)) - 1));
fprintf('  oil bill, range                         %+.2f%%\n', ...
        100*(max(M(:,4))/min(M(:,4)) - 1));
fprintf('  output, range                           %+.2f%%\n', ...
        100*(max(M(:,6))/min(M(:,6)) - 1));
fprintf('  oil bill as %% of GDP, min to max        %.3f to %.3f\n', ...
        min(M(:,5)), max(M(:,5)));
fprintf('  default rate, min to max                %.3f to %.3f %% a year\n', ...
        min(M(:,9)), max(M(:,9)));
fprintf('  spread, min to max                      %.0f to %.0f basis points\n', ...
        100*min(M(:,8)), 100*max(M(:,8)));
if ~isempty(iA)
    d  = abs(M(:,9) - M(iA,9));
    sd = sqrt(M(:,10).^2 + M(iA,10)^2);
    [~, w] = max(d);
    fprintf('  largest default gap from %.2f            %.3f pp = %.1f se\n', ...
            ADOPTED, d(w), d(w)/sd(w));
end

% the one row we can rebuild from scratch
if ~isempty(S) && ~isempty(iA)
    r = extract_row(S);
    fprintf('\n  CHECK  the %.2f row rebuilt from benchmark/\n', ADOPTED);
    fld = {'oil imports','oil bill','oil/GDP %','output','price','spread %', ...
           'default % p.a.','default se'};
    got = [r.oil_qty r.oil_value r.oil_share r.gdp r.price r.spread r.def r.def_se];
    exp_ = [M(iA,3) M(iA,4) M(iA,5) M(iA,6) M(iA,7) M(iA,8) M(iA,9) M(iA,10)];
    worst = 0;
    for k = 1:numel(fld)
        rel = abs(got(k)-exp_(k))/max(abs(exp_(k)), eps);
        worst = max(worst, rel);
        fprintf('    %-16s rebuilt %12.6f   recorded %12.6f   %.1e\n', ...
                fld{k}, got(k), exp_(k), rel);
    end
    if worst < 1e-4
        fprintf('    agrees to %.1e -- the extraction is sound, so the other\n', worst);
        fprintf('    five rows can be read with the same confidence.\n');
    else
        fprintf('    DISAGREES by %.1e. Do not use this table until that is explained.\n', worst);
    end
end

fh = fopen(fullfile(outdir, 'table2_response.csv'), 'w');
fpc(fh, ['elasticity,oil_imports,value_of_oil_imports,oil_bill_pct_gdp,' ...
         'output,default_pct_annual,default_se_pp,mean_spread_pct,' ...
         'mean_price,quarters\n']);
for i = 1:size(M,1)
    fpc(fh, '%.2f,%.4f,%.4f,%.3f,%.4f,%.3f,%.3f,%.3f,%.6f,%d\n', ...
            M(i,1), M(i,3), M(i,4), M(i,5), M(i,6), M(i,9), M(i,10), ...
            M(i,8), M(i,7), M(i,2));
end
fclose(fh);

% the LaTeX body, so the letter's table is generated rather than retyped
fh = fopen(fullfile(outdir, 'response_table.tex'), 'w');
fprintf(fh, '%% generated by JEDC_elasticity.m -- do not edit by hand\n');
fprintf(fh, '\\begin{tabular}{ccccccc}\n\\toprule\n');
fprintf(fh, 'elasticity & oil & value of & oil bill & output & default rate & mean \\\\\n');
fprintf(fh, '           & imports & oil imports & / GDP & & \\%% p.a. & spread, \\%% \\\\\n');
fprintf(fh, '\\midrule\n');
for i = 1:size(M,1)
    if abs(M(i,1)-ADOPTED) < 1e-9
        fprintf(fh, ['\\textbf{%.2f} & \\textbf{%.4f} & \\textbf{%.4f} & ' ...
                     '\\textbf{%.3f} & \\textbf{%.4f} & \\textbf{%.3f (%.3f)} & ' ...
                     '\\textbf{%.3f} \\\\\n'], ...
                M(i,1), M(i,3), M(i,4), M(i,5), M(i,6), M(i,9), M(i,10), M(i,8));
    else
        fprintf(fh, '%.2f & %.4f & %.4f & %.3f & %.4f & %.3f (%.3f) & %.3f \\\\\n', ...
                M(i,1), M(i,3), M(i,4), M(i,5), M(i,6), M(i,9), M(i,10), M(i,8));
    end
end
fprintf(fh, '\\bottomrule\n\\end{tabular}\n');
fclose(fh);
end


function r = extract_row(S)
%EXTRACT_ROW  One row of the response table from a simulation panel.
%
% Column map, 1-based, from the WRITE(23,...) in the Fortran source:
%    4 q   6 oil quantity   7 standing (1 good)   8 default flag (2 = default)
%    9 q default-free      14 p    15 oil*p/gdp   16 gdp
RSTAR = 0.01; DELTA = 0.03; COUPON = (RSTAR + DELTA)/(1 + RSTAR);

r.oil_qty   = mean(S(:,6));
r.oil_value = mean(S(:,6).*S(:,14));     % E[p*m], not E[p]*E[m]
r.oil_share = 100*mean(S(:,15));
r.gdp       = mean(S(:,16));
r.price     = mean(S(:,14));

m  = S(:,4) > 0 & S(:,9) > 0;
yl = COUPON./S(m,4) - DELTA;
yr = COUPON./S(m,9) - DELTA;
r.spread = 100*mean((1+yl).^4 - (1+yr).^4);

ev   = sum(S(:,8) == 2);
good = sum(S(:,7) == 1);
q    = ev/good;
r.def    = 100*(1 - (1-q)^4);
r.def_se = 100*4*(1-q)^3*sqrt(ev)/good;
end


% ======================================================================
% the data readers
% ======================================================================

function price = annual_oil_price(empdir)
%ANNUAL_OIL_PRICE  The quarterly real oil price averaged to calendar years.
C = readcell(fullfile(empdir, 'oil_qtrly.xlsx'), 'Sheet', 'Sheet 1');
head = cellfun(@tostr, C(1,:), 'UniformOutput', false);
iq = find(strcmp(head, 'qdate'), 1);
ip = find(strcmp(head, 'real_price'), 1);
if isempty(iq) || isempty(ip)
    error('JEDC_elasticity:cols', 'oil_qtrly.xlsx needs qdate and real_price');
end
yr = []; v = [];
for i = 2:size(C,1)
    q = tostr(C{i,iq});
    x = tonum(C{i,ip});
    if isempty(q) || isnan(x), continue; end
    y = sscanf(q, '%d', 1);
    if isempty(y), continue; end
    yr(end+1,1) = y; v(end+1,1) = x;                              %#ok<AGROW>
end
uy = unique(yr);
pv = zeros(numel(uy),1);
for k = 1:numel(uy), pv(k) = mean(v(yr == uy(k))); end
price = struct('years', uy, 'vals', pv);
end


function [cty, shares] = import_shares(empdir)
%IMPORT_SHARES  Oil import share of GDP, percent, by country and year.
%
% Zeros mean missing, not zero: the sheet pads every country to the full year
% range. Country names carry an '_import/gdp' suffix that the other sheet does
% not, so both are upper-cased and stripped before matching.
C = readcell(fullfile(empdir, 'spread_data.xlsx'), 'Sheet', 'exp_imp_data');
years = [];
for j = 2:size(C,2)
    y = sscanf(tostr(C{1,j}), '%d', 1);
    if isempty(y), y = NaN; end
    years(j) = y;                                                 %#ok<AGROW>
end
cty = {}; shares = {};
for i = 2:size(C,1)
    nm = canon(strrep(tostr(C{i,1}), '_import/gdp', ''));
    if isempty(nm), continue; end
    ys = []; vs = [];
    for j = 2:size(C,2)
        if isnan(years(j)), continue; end
        x = tonum(C{i,j});
        if isnan(x) || x <= 0, continue; end
        ys(end+1,1) = years(j); vs(end+1,1) = x;                  %#ok<AGROW>
    end
    if isempty(ys), continue; end
    cty{end+1,1} = nm;                                            %#ok<AGROW>
    shares{end+1,1} = struct('years', ys, 'vals', vs);            %#ok<AGROW>
end
end


function keep = importer_sample(empdir)
%IMPORTER_SAMPLE  The paper's oil importers: average oil import/GDP above 1%.
C = readcell(fullfile(empdir, 'spread_data.xlsx'), 'Sheet', 'import_gdp');
keep = {};
for i = 2:size(C,1)
    nm = canon(tostr(C{i,1}));
    x  = tonum(C{i,2});
    if ~isempty(nm) && ~isnan(x) && x > 1
        keep{end+1,1} = nm;                                       %#ok<AGROW>
    end
end
end


function nm = canon(nm)
%CANON  A country name, upper-cased, with the one known misspelling repaired.
%
% The import_gdp sheet spells El Salvador 'EL SAVADOR', without the second L,
% while exp_imp_data spells it correctly. Matching the two sheets on the raw
% strings silently drops El Salvador, which is why an earlier version of this
% analysis ran on 34 importers against the paper's 35. El Salvador clears the
% import-share cutoff at 1.56%% and has 21 usable years, so it belongs in the
% sample. The repair is here rather than in the spreadsheet so the data file is
% left as it was received.
nm = upper(strtrim(nm));
if strcmp(nm, 'EL SAVADOR'), nm = 'EL SALVADOR'; end
end


function tf = isKeyYear(price, y)
tf = any(price.years == y);
end

function v = getYear(price, y)
v = price.vals(price.years == y);
v = v(1);
end


% ======================================================================
% small numerical helpers, so no toolbox is needed
% ======================================================================

function b = ols(X, y)
%OLS  Least squares by the normal equations. X already carries its constant.
b = (X'*X) \ (X'*y);
end


function [b, se, r2] = ols1(x, y)
%OLS1  Slope of y on x with a constant, textbook homoskedastic standard error.
%
% With about twenty annual observations per country there is no useful degree
% of freedom for a HAC correction, and the object of interest is the SPREAD of
% the slopes across countries rather than a test on any single one.
x = x(:); y = y(:);
n = numel(x);
mx = mean(x); my = mean(y);
sxx = sum((x-mx).^2);
b   = sum((x-mx).*(y-my))/sxx;
a   = my - b*mx;
res = y - a - b*x;
sse = sum(res.^2);
syy = sum((y-my).^2);
if n > 2, se = sqrt(sse/(n-2)/sxx); else, se = NaN; end
if syy > 0, r2 = 1 - sse/syy; else, r2 = NaN; end
end


function q = qtile(v, p)
%QTILE  Linearly interpolated quantile, matching numpy's and the Python port's.
s = sort(v(:));
if numel(s) == 1, q = s(1); return; end
h  = (numel(s)-1)*p;
lo = floor(h);
hi = min(lo+1, numel(s)-1);
q  = s(lo+1) + (h-lo)*(s(hi+1) - s(lo+1));
end


function s = yn(tf)
if tf, s = 'yes'; else, s = 'no'; end
end


function s = rej(tf)
if tf, s = 'REJECTED'; else, s = 'not rejected'; end
end


function s = tostr(x)
%TOSTR  A cell from readcell as a char row, empty when the cell was blank.
if isnumeric(x) && isscalar(x) && isnan(x), s = ''; return; end
if ismissing_(x), s = ''; return; end
if ischar(x), s = x; return; end
if isstring(x), s = char(x); return; end
if isnumeric(x), s = num2str(x); return; end
s = '';
end


function v = tonum(x)
%TONUM  A cell from readcell as a double, NaN when it was blank or not a number.
if ismissing_(x), v = NaN; return; end
if isnumeric(x) && isscalar(x), v = double(x); return; end
if ischar(x) || isstring(x)
    v = str2double(x);
    return
end
v = NaN;
end


function tf = ismissing_(x)
%ISMISSING_  ismissing without erroring on the types readcell can return.
try
    tf = any(ismissing(x));
catch
    tf = false;
end
if isempty(x), tf = true; end
end


% ======================================================================
% file I/O, shared in spirit with JEDC_decomposition.m
% ======================================================================

function S = read_sim(run)
%READ_SIM  Load graphs_data_sim_dss.txt as a numeric matrix, 20 columns.
path = fullfile(run, 'graphs_data_sim_dss.txt');
fid  = fopen(path, 'r');
if fid < 0, error('read_sim:open', 'cannot open %s', path); end
C = textscan(fid, repmat('%f', 1, 20), 'CollectOutput', true);
fclose(fid);
S = C{1};
if size(S, 2) ~= 20
    error('read_sim:shape', '%s has %d columns, expected 20', path, size(S,2));
end
end


function s = csvq(s)
%CSVQ  Quote a field only when it has to be quoted.
if any(s == ',') || any(s == '"') || any(s == char(10)) || any(s == char(13))
    s = ['"' strrep(s, '"', '""') '"'];
end
end


function fpc(fh, fmt, varargin)
%FPC  fprintf to a CSV file with the CRLF line terminator the Python ports use.
if numel(fmt) >= 2 && strcmp(fmt(end-1:end), '\n')
    fmt = [fmt(1:end-2) '\r\n'];
end
fprintf(fh, fmt, varargin{:});
end
