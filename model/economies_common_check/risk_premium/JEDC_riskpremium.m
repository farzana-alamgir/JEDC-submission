function JEDC_riskpremium(outdir, sweep_csv, benchmark_run)
%JEDC_RISKPREMIUM  Lender-side risk pricing, for R1 Major 5.
%
%   Run it from the folder it lives in,
%   model/economies_common_check/risk_premium:
%
%     >> JEDC_riskpremium
%
%   which is the same as
%
%     >> JEDC_riskpremium('.', 'sweep/kappa.csv', '../benchmark')
%
% WHAT R1 MAJOR 5 ASKS
%   The precautionary-borrowing result assumes risk-neutral lenders. Discuss
%   how robust it is to lender-side risk pricing, state that its strength is
%   conditional on risk-neutral pricing, and if feasible add a robustness
%   exercise with an exogenous SDF or a reduced-form global risk premium.
%
% THE EXERCISE
%   kappa_risk is a parameter of the model, zero in the baseline. With it on,
%
%       m' = exp(-rstar) * exp(kappa * eps') / Z(p, sigma')
%
%   where eps' is the innovation to the log oil price and Z normalises the
%   kernel ON THE DISCRETE GRID, so E[m'] = exp(-rstar) holds exactly at any
%   kappa. A positive kappa makes the discount factor high when oil is dear, so
%   lenders demand more for default risk that is concentrated in those states.
%   kappa_risk = 0 reproduces ../benchmark.
%
%   An earlier version of this kernel used the continuous-state lognormal
%   correction, which does not normalise on a discrete grid and gave
%   E[m]/exp(-rstar) ranging from 0 to 2559. That bug and its fix are recorded
%   in results/RISK_PREMIUM_AND_FIGURE3.md. The results here are post-fix.
%
% HOW MUCH RISK PRICING IS TOO MUCH
%   kappa is not observable, so it is disciplined by the maximum Sharpe ratio
%   the kernel implies. For this kernel the quarterly maximum is
%
%       sd(m')/E(m') = sqrt( exp(kappa^2 * v) - 1 )
%
%   in a state whose conditional innovation variance is v = exp(p_vol). This
%   file averages that over the volatility states at their simulated
%   frequencies and annualises by two. Equities run about 0.4 a year, so a
%   kernel implying much more than that is not a plausible description of
%   lenders.
%
% WHAT IT WRITES, into outdir:
%   table1_kappa.csv   the sweep, with the implied Sharpe ratio per kappa
%
% Base MATLAB only, no toolboxes.

if nargin < 1 || isempty(outdir),        outdir        = '.'; end
if nargin < 2 || isempty(sweep_csv),     sweep_csv     = 'sweep/kappa.csv'; end
if nargin < 3 || isempty(benchmark_run), benchmark_run = '../benchmark'; end

EQUITY_SHARPE = 0.4;        % the benchmark kappa is judged against
C_VOL = 20;                 % the log variance state in the simulation panel

T = readtable(sweep_csv, 'VariableNamingRule', 'preserve');
T = sortrows(T, 'kappa');

% the volatility states and how often they occur, from the baseline panel
fprintf('\nreading the baseline panel for the volatility distribution\n');
S = read_sim(benchmark_run);
v = exp(S(:, C_VOL));                       % conditional variance of eps
[u, ~, ix] = unique(v);
w = accumarray(ix, 1); w = w / sum(w);
fprintf('  %d volatility states, conditional sd of the innovation %.4f to %.4f\n', ...
        numel(u), sqrt(min(u)), sqrt(max(u)));
clear S v ix

sharpe = zeros(height(T), 1);
for i = 1:height(T)
    k = T.kappa(i);
    % the maximum Sharpe ratio state by state, then averaged and annualised
    sq = sqrt(max(exp(k^2 * u) - 1, 0));
    sharpe(i) = 2 * sum(w .* sq);
end

fprintf('\n');
fprintf('================================================================\n');
fprintf(' R1 MAJOR 5   lender-side risk pricing at sigma_oil = 0.25\n');
fprintf('================================================================\n\n');
fprintf('  %-7s %9s %10s %12s %10s %10s %8s %9s\n', 'kappa', 'spread', ...
        'debt/GDP', 'default %/y', 'spread lo', 'spread hi', 'gap', 'Sharpe');
for i = 1:height(T)
    lo = T.spread_lowvol(i); hi = T.spread_highvol(i);
    fprintf('  %-7.1f %8.2f%% %9.1f%% %11.2f%% %9.2f%% %9.2f%% %+8.2f %9.2f\n', ...
            T.kappa(i), T.mean_spread_pct(i), T.debt_gdp_pct(i), ...
            T.default_pct_annual(i), lo, hi, hi - lo, sharpe(i));
end

% where the equity benchmark sits
j = find(sharpe > EQUITY_SHARPE, 1);
if isempty(j)
    fprintf('\n  every kappa solved implies a Sharpe ratio below %.1f\n', EQUITY_SHARPE);
else
    if j == 1
        fprintf('\n  the equity benchmark of %.1f is already exceeded at the lowest kappa solved\n', ...
                EQUITY_SHARPE);
    else
        kstar = interp1(sharpe(j-1:j), T.kappa(j-1:j), EQUITY_SHARPE);
        fprintf('\n  a Sharpe ratio of %.1f, the equity benchmark, corresponds to kappa = %.2f\n', ...
                EQUITY_SHARPE, kstar);
        g0 = T.spread_highvol(1) - T.spread_lowvol(1);
        gs = interp1(T.kappa(j-1:j), ...
                     T.spread_highvol(j-1:j) - T.spread_lowvol(j-1:j), kstar);
        fprintf('  at that kappa the volatility gap is %+.2f, against %+.2f at kappa = 0\n', gs, g0);
        fprintf('  and debt/GDP is %.1f%%, against %.1f%%\n', ...
                interp1(T.kappa(j-1:j), T.debt_gdp_pct(j-1:j), kstar), T.debt_gdp_pct(1));
    end
end

fh = fopen(fullfile(outdir, 'table1_kappa.csv'), 'w');
fpc(fh, ['kappa,mean_spread_pct,debt_gdp_pct,default_pct_annual,' ...
         'spread_lowvol,spread_highvol,vol_gap,implied_max_sharpe_annual\n']);
for i = 1:height(T)
    fpc(fh, '%.1f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f,%.4f\n', T.kappa(i), ...
            T.mean_spread_pct(i), T.debt_gdp_pct(i), T.default_pct_annual(i), ...
            T.spread_lowvol(i), T.spread_highvol(i), ...
            T.spread_highvol(i) - T.spread_lowvol(i), sharpe(i));
end
fclose(fh);
fprintf('\nwritten %s\n\n', fullfile(outdir, 'table1_kappa.csv'));
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
