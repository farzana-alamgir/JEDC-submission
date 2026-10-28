% Are FIGURE2's economy ordering and FIGURE3's volatility ordering stable
% across the debt grid, or do they flip somewhere?
%
% FIGURE2 is drawn at (y = median, p = central node, all b) and FIGURE3 at a
% SINGLE debt index (i_b3 = 44). So FIGURE2 already spans debt and the
% question is whether the gap between economies changes sign along it;
% FIGURE3 has only ever been shown at mean debt and needs re-checking.
%
% Run from a directory holding oil_bm.mat, oil_intermediate.mat, oil_basic.mat
% (the level-matched set).

A = load('oil_bm.mat','spread_matrix','p_grid','b_grid','p_num','p_vol_num', ...
         'y_num','b_num','output_matrix');
I = load('oil_intermediate.mat','spread_matrix');
B = load('oil_basic.mat','spread_matrix');

p_num = A.p_num; p_vol_num = A.p_vol_num;
P   = exp(reshape(A.p_grid, p_num, p_vol_num));
ctr = ceil(p_num/2);                 % shared central node, identical in every state
iy  = 11;                            % median output, as in FIGURE2/FIGURE3

feas = squeeze(max(max(A.output_matrix,[],1),[],2)) < 1d3;
O__  = reshape(A.output_matrix, A.b_num, A.y_num, []);
O__(:,:,~feas(:)) = NaN;
gdpm = mean(O__(:),'omitnan');
dgdp = A.b_grid/(4*gdpm);            % one common debt/GDP axis for all economies

% ---------- FIGURE2: gap between economies, across debt ---------------------
sF = 100*squeeze(A.spread_matrix(:, iy, ctr, 3));
sI = 100*squeeze(I.spread_matrix(:, iy, ctr, 1));
sB = 100*squeeze(B.spread_matrix(:, iy));
fprintf('\n=== FIGURE2: spread at the shared central price, by debt ===\n');
fprintf('%9s %9s %9s %9s %11s %11s\n','debt/GDP','full','interm','basic','basic-full','int-full');
for ib = 10:8:A.b_num
    if ~isfinite(sF(ib)), continue; end
    fprintf('%9.3f %9.3f %9.3f %9.3f %11.3f %11.3f\n', ...
            dgdp(ib), sF(ib), sI(ib), sB(ib), sB(ib)-sF(ib), sI(ib)-sF(ib));
end
gap = sB - sF; ok = isfinite(gap) & isfinite(sF) & dgdp(:) < 0.40;
fprintf('basic-full gap over debt/GDP<0.40: min %+0.3f  max %+0.3f  sign flips %d time(s)\n', ...
        min(gap(ok)), max(gap(ok)), sum(diff(sign(gap(ok)))~=0));

% ---------- FIGURE3: matched-price slope ratio, across debt ------------------
p_mid = P(ctr,3);
p_lo  = max(0.90*p_mid, max(P(1,:)));
p_hi  = min(1.10*p_mid, min(P(p_num,:)));
dp    = p_hi - p_lo;
slope = @(ib,k) ( interp1(P(:,k), squeeze(A.spread_matrix(ib,:,:,k)).', p_hi, 'linear') ...
                - interp1(P(:,k), squeeze(A.spread_matrix(ib,:,:,k)).', p_lo, 'linear') ).' / dp;

fprintf('\n=== FIGURE3: matched-price slope by volatility state, across debt ===\n');
fprintf('matched contrast %.4f -> %.4f\n', p_lo, p_hi);
fprintf('%9s %10s %10s %10s %10s\n','debt/GDP','vol2','vol3','vol4','ratio 4/2');
ibs = 10:6:A.b_num; rat = nan(numel(ibs),1); dd = nan(numel(ibs),1);
for j = 1:numel(ibs)
    ib = ibs(j);
    s2 = slope(ib,2); s3 = slope(ib,3); s4 = slope(ib,4);
    v2 = median(s2(isfinite(s2))); v3 = median(s3(isfinite(s3))); v4 = median(s4(isfinite(s4)));
    if ~(isfinite(v2) && v2 > 1e-10), continue; end
    rat(j) = v4/v2; dd(j) = dgdp(ib);
    fprintf('%9.3f %10.5f %10.5f %10.5f %10.3f\n', dgdp(ib), v2, v3, v4, v4/v2);
end
good = isfinite(rat);
fprintf('ratio over the debt grid: min %.3f  max %.3f  above 1 at %d of %d debt levels\n', ...
        min(rat(good)), max(rat(good)), sum(rat(good)>1), sum(good));
fprintf('(paper claims about 3.0 at every debt level)\n');

save('fig23_by_debt.mat','dgdp','sF','sI','sB','dd','rat','good');
