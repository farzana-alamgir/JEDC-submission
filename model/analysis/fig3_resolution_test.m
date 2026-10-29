% Is the matched-price slope ratio identified on a 7-node per-state grid?
%
% Concern: each volatility state's grid width scales with its own sd, so node
% SPACING differs by state (state 2 spacing near the centre ~0.33-0.48, state 4
% ~0.53-0.99). Linear interpolation over a wider spacing smooths the spread
% schedule more, which flattens the measured derivative in exactly the
% high-volatility states whose slope the paper claims is steepest. If that is
% what drives the ratio, it should move systematically with the contrast width
% and with how many nodes the contrast spans.
%
% Run from a directory holding oil_bm.mat.

A = load('oil_bm.mat', 'spread_matrix', 'p_grid', 'p_num', 'p_vol_num', 'y_num');
p_num = A.p_num; p_vol_num = A.p_vol_num;
P = exp(reshape(A.p_grid, p_num, p_vol_num));
i_b3 = 44; vol_states = [2 3 4];
p_mid = P(ceil(p_num/2), 3);
med = @(x) median(x(isfinite(x)));

fprintf('\ncentral node spacing by vol state (price units):\n');
for k = 1:p_vol_num
    c = ceil(p_num/2);
    fprintf('  state %d: down %.4f  up %.4f\n', k, P(c,k)-P(c-1,k), P(c+1,k)-P(c,k));
end

widths = [0.05 0.10 0.20 0.40 0.60 0.80];
fprintf('\n%8s %10s %10s %10s %10s %10s\n', 'halfwid', 'dp', 'vol2', 'vol3', 'vol4', 'ratio4/2');
for w = widths
    p_lo = max((1-w)*p_mid, max(P(1,:)));
    p_hi = min((1+w)*p_mid, min(P(p_num,:)));
    s = zeros(1,3);
    for v = 1:3
        k = vol_states(v);
        S = squeeze(A.spread_matrix(i_b3,:,:,k)).';
        sl = (interp1(P(:,k), S, p_hi, 'linear') - ...
              interp1(P(:,k), S, p_lo, 'linear')).' / (p_hi - p_lo);
        s(v) = med(sl);
    end
    fprintf('%8.2f %10.4f %10.5f %10.5f %10.5f %10.3f\n', ...
            w, p_hi-p_lo, s(1), s(2), s(3), s(3)/s(1));
end

% How many grid nodes does the contrast actually span in each state?
fprintf('\nnodes strictly inside the +/-10%% contrast, by state:\n');
p_lo = 0.90*p_mid; p_hi = 1.10*p_mid;
for k = 1:p_vol_num
    fprintf('  state %d: %d of %d\n', k, sum(P(:,k) > p_lo & P(:,k) < p_hi), p_num);
end
fprintf(['\nIf the contrast contains 0-1 interior nodes in every state, the\n' ...
         '"derivative" is a chord between the bracketing nodes and inherits\n' ...
         'that state''s spacing -- the ratio is not identified.\n']);
