% Paper's quantitative claims, measured on the PER-STATE Rouwenhorst grid
% (use_common_p_grid = .false., p_num = 7) -- the submitted grid construction.
%
% Two corrections relative to check_claims.m, both forced by the per-state grid:
%
%  (a) MATCHED PRICES. Each volatility state solves on its own grid, so a fixed
%      price INDEX is a different price in each state. check_claims.m indexes
%      spread_matrix(:,:,iHi,k) with the same iHi for every k and divides by
%      state 3's interval. Here each state's spread schedule is interpolated
%      onto one physical price pair instead.
%
%  (b) FEASIBILITY MASK. State 5's grid reaches p = 0.0892, below the CES floor
%      alpha^(1/theta) = 0.09, where output diverges (7.7e10 vs 29.2 elsewhere).
%      Any mean of output must exclude it.
%
% Run from a directory holding oil_bm.mat, oil_intermediate.mat, oil_basic.mat.

A = load('oil_bm.mat','spread_matrix','p_grid_matrix','b_grid','y_num','p_num', ...
         'p_vol_num','output_matrix','b_next_matrix','b_num','pdf_p','pdf_p_vol','v_matrix');
P = exp(A.p_grid_matrix);                       % p_num x p_vol_num, per-state prices

% ---- feasibility mask ------------------------------------------------------
feas = squeeze(max(max(A.output_matrix,[],1),[],2)) < 1d3;
O__  = reshape(A.output_matrix, A.b_num, A.y_num, []);
O__(:,:,~feas(:)) = NaN;
gdpm = mean(O__(:),'omitnan');
fprintf('feasibility: %d of %d price nodes dropped; mean output %.4f (unmasked %.3e)\n', ...
        sum(~feas(:)), numel(feas), gdpm, mean(A.output_matrix(:)));

% ---- matched price pair ----------------------------------------------------
% +/-10% around the shared central node exp(mean_p), clipped to the common
% support of all states (the narrowest, lowest-volatility grid).
pm   = P(ceil(A.p_num/2), 3);
p_lo = max(0.90*pm, max(P(1,:)));
p_hi = min(1.10*pm, min(P(A.p_num,:)));
dp   = p_hi - p_lo;
fprintf('matched contrast around p=%.4f : %.4f -> %.4f (dp=%.4f, %.0f%% move)\n\n', ...
        pm, p_lo, p_hi, dp, 100*dp/pm);

slope = @(ib,k) ( interp1(P(:,k), squeeze(A.spread_matrix(ib,:,:,k)).', p_hi, 'linear') ...
                - interp1(P(:,k), squeeze(A.spread_matrix(ib,:,:,k)).', p_lo, 'linear') ).' / dp;

ib = 44; vs = [2 3 4]; sl = nan(A.y_num,3);
for k = 1:3, sl(:,k) = slope(ib, vs(k)); end
r = sl(:,3)./sl(:,1); ok = isfinite(r) & sl(:,1) > 1e-8;
fprintf('[1] SPREAD SLOPE, state dependence  (paper: 3x)\n');
fprintf('    low/mean/high vol at median y: %.1f / %.1f / %.1f bp per unit price\n', ...
        1e4*sl(11,1), 1e4*sl(11,2), 1e4*sl(11,3));
fprintf('    ratio high/low: median %.3f  max %.2f  >1 at %d of %d\n', ...
        median(r(ok)), max(r(ok)), sum(r(ok)>1), sum(ok));
fprintf(['    NOTE: not identified on this grid -- node spacing scales with the\n' ...
         '    state''s own volatility, so the interpolated slope inherits it.\n' ...
         '    See fig3_resolution_test.m.\n\n']);

fprintf('[2] DEBT AMPLIFICATION  (paper: more indebted -> larger spread increases)\n');
fprintf('    %-6s %-11s %s\n','i_b','debt/GDP','slope (bp per unit price, mean vol)');
for ib2 = [20 30 40 44 50 60]
  s = slope(ib2, 3); f = s(isfinite(s));
  if ~isempty(f)
      fprintf('    %-6d %-11.3f %.1f\n', ib2, A.b_grid(ib2)/(4*gdpm), 1e4*median(f));
  end
end

fprintf('\n[3] DEBT SLOPE d(Debt/GDP)/d(OilPrice)  (paper: 0.16 low / 0.25 mean / 0.70 high)\n');
iy = 11; nm = {'low','mean','high'};
for k = 1:3
  v = vs(k); dd = [];
  % b_next is indexed on the grid, so interpolate the POLICY in price instead:
  % take the bracketing nodes of p_lo and p_hi on THIS state's grid.
  [~, iLo] = min(abs(P(:,v) - p_lo));  [~, iHi] = min(abs(P(:,v) - p_hi));
  if iLo == iHi, fprintf('    %-5s vol: contrast falls inside one cell, skipped\n', nm{k}); continue; end
  dpv = P(iHi,v) - P(iLo,v);
  for ib2 = 1:A.b_num
    bl = A.b_next_matrix(ib2,iy,iLo,v); bh = A.b_next_matrix(ib2,iy,iHi,v);
    if bl<1||bh<1||bl>A.b_num||bh>A.b_num, continue; end
    gl = A.output_matrix(ib2,iy,iLo,v);  gh = A.output_matrix(ib2,iy,iHi,v);
    if gl<=0||gh<=0||gl>1d3||gh>1d3, continue; end
    dd(end+1) = (A.b_grid(bh)/(4*gh) - A.b_grid(bl)/(4*gl))/dpv;
  end
  if ~isempty(dd)
      fprintf('    %-5s vol: mean %+0.4f  median %+0.4f  (n=%d, dp=%.3f)\n', ...
              nm{k}, mean(dd), median(dd), numel(dd), dpv);
  end
end

% ---- [4] welfare -----------------------------------------------------------
f = {'oil_bm.mat','oil_intermediate.mat','oil_basic.mat'}; V = {};
for k = 1:3
  S = load(f{k},'v_matrix','pdf_p','pdf_p_vol','p_num','p_vol_num','y_num','output_matrix','b_num');
  fk = squeeze(max(max(S.output_matrix,[],1),[],2)) < 1d3;   % mask infeasible nodes
  Vk = zeros(S.y_num,1);
  for iy = 1:S.y_num
    a = 0; wtot = 0;
    for v = 1:S.p_vol_num
      b = 0; w = 0;
      for ip = 1:S.p_num
        if ~fk(ip,v), continue; end
        ww = S.pdf_p((v-1)*S.p_num+ip);
        b  = b + ww*S.v_matrix(44,iy,ip,v); w = w + ww;
      end
      a = a + b*S.pdf_p_vol(v); wtot = wtot + w*S.pdf_p_vol(v);
    end
    Vk(iy) = a/wtot;                       % renormalise after masking
  end
  V{k} = Vk;
end
Vf = V{1}; sg = 2; cev = @(Va) 100*((Va./Vf).^(1/(1-sg))-1);
fprintf('\n[4] WELFARE, consumption equivalent at mean debt  (paper: +0.2%% to +1.1%%)\n');
fprintf('    full -> intermediate (remove time-varying vol)  : %+0.4f%%\n', mean(cev(V{2})));
fprintf('    full -> basic        (remove all oil price risk): %+0.4f%%\n', mean(cev(V{3})));
fprintf('    mean V: full %.5f  intermediate %.5f  basic %.5f\n', mean(Vf), mean(V{2}), mean(V{3}));
