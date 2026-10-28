% Why do FIGURE2 and FIGURE3 come out opposite to the paper?
%
% FIGURE2: the three economies are plotted at THREE DIFFERENT PRICES. The full
% model is drawn at its central log node exp(mean_p) = 1.1275, which is the
% MEDIAN price, while the basic economy is pinned at the ergodic MEAN price
% 1.3339. Jensen puts those 18.3% apart. Below, all three are evaluated at the
% same physical price by interpolation.
%
% FIGURE3: the level and the slope of the spread respond to volatility in
% OPPOSITE directions, and the figure plots the slope. Higher volatility is a
% wider conditional distribution for p', so the default probability as a
% function of today's price is that step convolved with a wider kernel:
% the LEVEL of risk rises but the function gets FLATTER. Checked below.

A = load('oil_bm.mat','spread_matrix','p_grid','b_grid','p_num','p_vol_num','y_num','b_num');
I = load('oil_intermediate.mat','spread_matrix','p_grid','p_num','p_vol_num');
B = load('oil_basic.mat','spread_matrix','p_grid');

P  = exp(reshape(A.p_grid, A.p_num, A.p_vol_num));
PI = exp(reshape(I.p_grid, I.p_num, I.p_vol_num));
pB = exp(B.p_grid(1));
iy = 11;

fprintf('\n=== FIGURE2 ===\n');
fprintf('plotted at: full %.4f, intermediate %.4f, basic %.4f\n', ...
        P(ceil(A.p_num/2),3), PI(ceil(I.p_num/2),1), pB);

% Evaluate full and intermediate at the SAME physical price as basic.
pt = pB;
fprintf('\nall three evaluated at p = %.4f:\n', pt);
fprintf('%6s %10s %10s %10s %11s %11s\n','i_b','full','interm','basic','basic-full','int-full');
for ib = [20 30 40 44 50 56 60]
    sF = 100*interp1(P(:,3),  squeeze(A.spread_matrix(ib,iy,:,3)), pt, 'linear');
    sI = 100*interp1(PI(:,1), squeeze(I.spread_matrix(ib,iy,:,1)), pt, 'linear');
    sB = 100*B.spread_matrix(ib,iy);
    fprintf('%6d %10.4f %10.4f %10.4f %11.4f %11.4f\n', ib, sF, sI, sB, sB-sF, sI-sF);
end

fprintf('\nfor contrast, the as-plotted (mismatched-price) version:\n');
fprintf('%6s %10s %10s %10s %11s\n','i_b','full','interm','basic','basic-full');
for ib = [20 30 40 44 50 56 60]
    sF = 100*A.spread_matrix(ib,iy,ceil(A.p_num/2),3);
    sI = 100*I.spread_matrix(ib,iy,ceil(I.p_num/2),1);
    sB = 100*B.spread_matrix(ib,iy);
    fprintf('%6d %10.4f %10.4f %10.4f %11.4f\n', ib, sF, sI, sB, sB-sF);
end

% ---- FIGURE3: level vs slope, by volatility state -------------------------
fprintf('\n=== FIGURE3: does volatility raise the LEVEL while flattening the SLOPE? ===\n');
ctr   = ceil(A.p_num/2);
p_mid = P(ctr,3);
p_lo  = max(0.90*p_mid, max(P(1,:)));
p_hi  = min(1.10*p_mid, min(P(A.p_num,:)));
fprintf('%6s %8s %12s %12s %12s\n','i_b','vol','level (%)','slope','');
for ib = [40 44 50]
    fprintf('  debt index %d\n', ib);
    lv = nan(1,A.p_vol_num); sl = nan(1,A.p_vol_num);
    for k = 1:A.p_vol_num
        s = squeeze(A.spread_matrix(ib,iy,:,k));
        lv(k) = 100*interp1(P(:,k), s, p_mid, 'linear');
        sl(k) = (interp1(P(:,k),s,p_hi,'linear') - interp1(P(:,k),s,p_lo,'linear'))/(p_hi-p_lo);
        fprintf('%6s %8d %12.4f %12.5f\n','',k,lv(k),sl(k));
    end
    fprintf('%6s %8s level hi/lo = %.3f   slope hi/lo = %.3f\n','','',lv(5)/lv(1),sl(5)/sl(1));
end
