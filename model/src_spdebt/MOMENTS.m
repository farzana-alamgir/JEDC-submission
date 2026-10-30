%MOMENTS  Table 3 moments from a solved run, in one self-contained file.
%
%   >> MOMENTS
%
% Point RUNDIR at a folder produced by one of the oil_prod_CES_*.f90 solvers
% and it prints the targeted moments next to their data counterparts.
%
% ---------------------------------------------------------------------------
% CONVENTION. This reproduces sim_prod_oil_dec29.m exactly, which does NOT
% report unconditional means. It averages over the per_before = 100 quarters
% PRECEDING each qualifying default episode (per_after = -1, so the default
% quarter itself is excluded). An episode qualifies only if it is separated
% from the previous one by more than sample_size + 1 = 101 periods and the
% country was not in exclusion 101 quarters earlier. Moments are computed
% within each window and then averaged across windows.
%
% Using an unconditional mean instead shifts the spread by about 0.3pp, which
% is enough to miss a calibration target, so the window convention matters.
% ---------------------------------------------------------------------------

RUNDIR = 'run_benchmark';     % <-- edit this

% data targets (Table 3)
TGT = struct('spread',4.1,'sd',2.0,'debt',34.0,'oil',9.0,'volp',14.47);

RSTAR = 0.01;  DELTA = 0.03;
COUPON = (RSTAR + DELTA)/(1 + RSTAR);
PER_BEFORE = 100;  PER_AFTER = -1;
SAMPLE_SIZE = PER_BEFORE + PER_AFTER + 1;          % 100

if ~isfolder(RUNDIR), error('MOMENTS:dir','not found: %s', RUNDIR); end
fprintf('\n=== MOMENTS: %s ===\n', RUNDIR);

prm     = rd(fullfile(RUNDIR,'graphs_param_dss.txt'));
per_num = prm(1);  nsamp = prm(2);
num     = max(1000, nsamp);
off     = per_num - num;
fprintf('  %d periods x %d samples, trimmed to the last %d\n', per_num, nsamp, num);

S = rd(fullfile(RUNDIR,'graphs_data_sim_dss.txt'));
if size(S,1) ~= per_num*nsamp
    error('MOMENTS:shape','%d rows, expected %d', size(S,1), per_num*nsamp);
end

% columns, from the WRITE(23,...) in oil_prod_CES.f90
q   = S(:,4);   excl = S(:,7);   d   = S(:,8) - 1;  qdf = S(:,9);
b   = S(:,3);   oil  = S(:,6);   p   = S(:,14);     oily = S(:,15);
out = S(:,16);

% annualised spread over the default-free yield
yl  = COUPON./q   - DELTA;
yr  = COUPON./qdf - DELTA;
spread = (1+yl).^4 - (1+yr).^4;
spread(q<=0 | qdf<=0) = NaN;
bty = 0.25*b./(out - oil);

msp = []; ssp = []; mbt = []; moy = [];
for i = 1:nsamp
    base = (i-1)*per_num;
    dl = find(d(base+1 : base+per_num) == 1);      % default periods, 1-based
    dl = dl(dl > off) - off;                       % keep those in the trimmed tail
    if isempty(dl), continue; end
    inter = [dl(1); diff(dl(:))];
    for k = 1:numel(dl)
        if inter(k) <= SAMPLE_SIZE + 1, continue; end
        ei = min(max(dl(k) - PER_BEFORE - 1, 1), num);
        if ~(excl(base + off + ei) < 2), continue; end
        idx = base + off + (dl(k)-PER_BEFORE : dl(k)+PER_AFTER);
        w = spread(idx); w = w(isfinite(w));
        if isempty(w), continue; end
        msp(end+1) = mean(w);           %#ok<SAGROW>
        ssp(end+1) = std(w);            %#ok<SAGROW>
        mbt(end+1) = mean(bty(idx),'omitnan');   %#ok<SAGROW>
        moy(end+1) = mean(oily(idx),'omitnan');  %#ok<SAGROW>
    end
end
if isempty(msp), error('MOMENTS:none','no qualifying default episodes'); end

% oil price volatility: sd of the quarterly log change, 500-period burn-in
dl_all = [];
for i = 1:nsamp
    seg = p((i-1)*per_num + (501:per_num));
    seg = seg(seg > 0);
    dl_all = [dl_all; diff(log(seg))];           %#ok<AGROW>
end

M = struct('spread',100*mean(msp), 'sd',100*mean(ssp), ...
           'debt',100*mean(mbt),   'oil',100*mean(moy), ...
           'volp',100*std(dl_all), 'defrate',100*mean(d==1), 'nobs',numel(msp));

fprintf('\n%-34s %10s %10s %9s\n','moment','model','data','gap');
row('Mean annual spread (%)',   M.spread, TGT.spread);
row('sd(spread)',                M.sd,     TGT.sd);
row('Mean debt/GDP (%)',        M.debt,   TGT.debt);
row('Oil share of GDP (%)',     M.oil,    TGT.oil);
row('sd(dlog oil price) (%)',   M.volp,   TGT.volp);
fprintf('%-34s %10.4f %10s %9s\n','Default rate (%, quarterly)', M.defrate,'--','--');
fprintf('\n  averaged over %d qualifying default episodes\n\n', M.nobs);

function row(lab, m, t)
    fprintf(['%-34s %10.4f %10.2f %+9.2f\n'], lab, m, t, m - t);
end

function A = rd(name)
    fid = fopen(name,'r');
    if fid < 0, error('MOMENTS:open','cannot open %s', name); end
    first = fgetl(fid);  ncol = numel(sscanf(first,'%f'));  frewind(fid);
    c = textscan(fid,'%f','CollectOutput',true);  fclose(fid);
    v = c{1};
    if ncol < 1 || mod(numel(v),ncol) ~= 0
        error('MOMENTS:shape','%s: %d values not divisible by %d columns', ...
              name, numel(v), ncol);
    end
    A = reshape(v, ncol, []).';
end
