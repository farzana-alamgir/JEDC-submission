% Figure 3 state dependence: old fixed-index method vs matched-price method.
%
% Under per-state Rouwenhorst grids (use_common_p_grid=.false.) each volatility
% state solves on its own grid, symmetric in logs about mean_p with half-width
% sqrt(p_num-1)*sd_k. A fixed price INDEX is therefore a different price in
% each state. This script reports the claimed state dependence both ways so
% the artifact can be stated quantitatively.
%
% Run from a directory holding oil_bm.mat.

A = load('oil_bm.mat', 'spread_matrix', 'p_grid', 'b_grid', ...
         'p_num', 'p_vol_num', 'y_num', 'output_matrix');
p_num = A.p_num; p_vol_num = A.p_vol_num;
P = exp(reshape(A.p_grid, p_num, p_vol_num));     % price nodes, per state

i_b3 = 44;                                        % mean debt index (as in script_bm)
i_p_low = 2; i_p_high = 6;                        % the submitted index contrast
vol_states = [2 3 4];

fprintf('\nper-state price grids (cols = vol state)\n');
fprintf('node');  fprintf('%10d', 1:p_vol_num); fprintf('\n');
for i = 1:p_num
    fprintf('%4d', i); fprintf('%10.4f', P(i,:)); fprintf('\n');
end
fprintf('\nnode%d->node%d interval by state:', i_p_low, i_p_high);
fprintf(' %.4f', P(i_p_high,:) - P(i_p_low,:)); fprintf('\n');

% ---- method 1: the submitted fixed-index slope -----------------------------
% numerator differences state k's OWN nodes; denominator is state 3's interval
dprice_state3 = P(i_p_high,3) - P(i_p_low,3);
slopes_idx = zeros(A.y_num, 3);
for v = 1:3
    k = vol_states(v);
    slopes_idx(:,v) = (squeeze(A.spread_matrix(i_b3,:,i_p_high,k)) - ...
                       squeeze(A.spread_matrix(i_b3,:,i_p_low ,k))).' / dprice_state3;
end

% ---- method 2: matched physical prices ------------------------------------
p_mid = P(ceil(p_num/2), 3);                      % shared central node
p_lo = max(0.90*p_mid, max(P(1,:)));
p_hi = min(1.10*p_mid, min(P(p_num,:)));
slopes_mp = zeros(A.y_num, 3);
for v = 1:3
    k = vol_states(v);
    S = squeeze(A.spread_matrix(i_b3,:,:,k)).';   % p_num x y_num
    slopes_mp(:,v) = (interp1(P(:,k), S, p_hi, 'linear') - ...
                      interp1(P(:,k), S, p_lo, 'linear')).' / (p_hi - p_lo);
end

fprintf('\nmatched prices %.4f -> %.4f (dp = %.4f)\n', p_lo, p_hi, p_hi - p_lo);

med = @(x) median(x(isfinite(x)));
fprintf('\n%-22s %10s %10s %10s %10s\n', '', 'vol 2', 'vol 3', 'vol 4', 'ratio 4/2');
fprintf('%-22s %10.5f %10.5f %10.5f %10.3f\n', 'fixed-index (old)', ...
        med(slopes_idx(:,1)), med(slopes_idx(:,2)), med(slopes_idx(:,3)), ...
        med(slopes_idx(:,3))/med(slopes_idx(:,1)));
fprintf('%-22s %10.5f %10.5f %10.5f %10.3f\n', 'matched-price (new)', ...
        med(slopes_mp(:,1)), med(slopes_mp(:,2)), med(slopes_mp(:,3)), ...
        med(slopes_mp(:,3))/med(slopes_mp(:,1)));
fprintf('\npaper claims the ratio is about 3.0\n');
