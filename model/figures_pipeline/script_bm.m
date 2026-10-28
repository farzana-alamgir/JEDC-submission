clear all

%%%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

graphs_y_grid_dss = fl__('graphs_y_grid_dss.txt');
graphs_b_grid_dss = fl__('graphs_b_grid_dss.txt');
%load graphs_p_grid_dss.txt
graphs_p_vol_grid_dss = fl__('graphs_p_vol_grid_dss.txt');
graphs_p_grid_dss = fl__('graphs_p_grid_dss.txt');
graphs_p_grid_2_dss = fl__('graphs_p_grid_2_dss.txt');
graphs_p_vol_grid_dss = fl__('graphs_p_vol_grid_dss.txt');
graphs_trans_matrix_p = fl__('graphs_trans_matrix_p.txt');
graphs_trans_matrix_p_vol = fl__('graphs_trans_matrix_p_vol.txt');
graphs_v_dss = fl__('graphs_v_dss.txt');
graphs_q_dss = fl__('graphs_q_dss.txt');
graphs_default_dss = fl__('graphs_default_dss.txt');
graphs_b_next_dss = fl__('graphs_b_next_dss.txt');
graphs_dev_dss = fl__('graphs_dev_dss.txt');
graphs_q_paid_dss = fl__('graphs_q_paid_dss.txt');
graphs_trans_matrix_p = fl__('graphs_trans_matrix_p.txt');
graphs_trans_matrix_p_2 = fl__('graphs_trans_matrix_p_2.txt');
graphs_trans_matrix_joint = fl__('graphs_trans_matrix_joint.txt');
graphs_cdf_matrix_p = fl__('graphs_cdf_matrix_p.txt');
graphs_trans_matrix_p_vol = fl__('graphs_trans_matrix_p_vol.txt');
graphs_trans_matrix_y = fl__('graphs_trans_matrix_y.txt');
graphs_cons_dss = fl__('graphs_cons_dss.txt');
graphs_oil_dss = fl__('graphs_oil_dss.txt');
graphs_output_dss = fl__('graphs_output_dss.txt');
graphs_delta = fl__('graphs_delta.txt');
graphs_q_def_free = fl__('graphs_q_def_free.txt');
graphs_q_def_free_dss = fl__('graphs_q_def_free_dss.txt');
graphs_pdf_y = fl__('graphs_pdf_y.txt');
graphs_pdf_p_vol = fl__('graphs_pdf_p_vol.txt');
graphs_pdf_p = fl__('graphs_pdf_p.txt');
pdf_y = graphs_pdf_y;
pdf_p_vol = graphs_pdf_p_vol;
pdf_p = graphs_pdf_p;

y_grid=graphs_y_grid_dss;
b_grid = graphs_b_grid_dss;
p_grid = graphs_p_grid_dss(:,1);
p_grid_1 = graphs_p_grid_dss(:,2);
p_grid_2 = graphs_p_grid_dss(:,3);
p_grid_3 = graphs_p_grid_2_dss(:,1);
p_grid_4 = graphs_p_grid_2_dss(:,2);
p_grid_5 = graphs_p_grid_2_dss(:,3);

p_vol_grid=graphs_p_vol_grid_dss;
v = graphs_v_dss;
q = graphs_q_dss;
default = graphs_default_dss;
b_next = graphs_b_next_dss;
dev = graphs_dev_dss;
q_paid = graphs_q_paid_dss;
trans_matrix_p = graphs_trans_matrix_p(:,1);
trans_matrix_p_1 = graphs_trans_matrix_p(:,2);
trans_matrix_p_2 = graphs_trans_matrix_p(:,3);
trans_matrix_p_3 = graphs_trans_matrix_p_2(:,1);
trans_matrix_p_4 = graphs_trans_matrix_p_2(:,2);
trans_matrix_p_5 = graphs_trans_matrix_p_2(:,3);
% trans_matrix_p = transition_matrix_p;
% trans_matrix_joint = graphs_trans_matrix_p(:,2);
cdf_matrix_p = graphs_cdf_matrix_p;
trans_matrix_p_vol = graphs_trans_matrix_p_vol;
trans_matrix_y=graphs_trans_matrix_y;
trans_matrix_joint=graphs_trans_matrix_joint;

consumption=graphs_cons_dss;
oil=graphs_oil_dss;
output=graphs_output_dss;

delta = graphs_delta;
q_def_free = graphs_q_def_free;
q_def_free_new = graphs_q_def_free_dss;


b_grid = b_grid;
p_grid = p_grid;

y_num=length(y_grid);
b_num = length(b_grid);
p_vol_num = length(p_vol_grid);
p_num = length(p_grid)/p_vol_num;


p_grid_matrix=reshape(p_grid, p_num, p_vol_num);
p_grid_1_matrix=reshape(p_grid_1, p_num, p_vol_num);
p_grid_2_matrix=reshape(p_grid_2, p_num, p_vol_num);
p_grid_3_matrix=reshape(p_grid_3, p_num, p_vol_num);
p_grid_4_matrix=reshape(p_grid_4, p_num, p_vol_num);
p_grid_5_matrix=reshape(p_grid_5, p_num, p_vol_num);
price=exp(p_grid_matrix);
% p_grid_matrix=reshape(p_grid, p_vol_num, p_num);  %% following jks

v0_matrix = zeros(b_num, y_num,p_num, p_vol_num);
v1_matrix = zeros(b_num,y_num, p_num, p_vol_num);
v_matrix = zeros(b_num,y_num, p_num, p_vol_num);
default_matrix = zeros(b_num,y_num, p_num, p_vol_num);
q_matrix = zeros(b_num,y_num, p_num, p_vol_num);
q_def_free_matrix = zeros(y_num,p_num, p_vol_num);
q_def_free_new_matrix = zeros(b_num,y_num, p_num, p_vol_num);

transition_matrix_y = zeros(y_num, y_num);
transition_matrix_p = zeros(p_num, p_num);
% transition_matrix_joint = zeros(p_num, p_num);

cons0_matrix = zeros(b_num,y_num, p_num, p_vol_num);
cons1_matrix = zeros(b_num, y_num,p_num, p_vol_num);
cons_matrix = zeros(b_num,y_num, p_num, p_vol_num);
oil0_matrix = zeros(b_num,y_num, p_num, p_vol_num);
oil1_matrix = zeros(b_num,y_num, p_num, p_vol_num);
oil_matrix = zeros(b_num,y_num, p_num, p_vol_num);
output0_matrix = zeros(b_num,y_num, p_num, p_vol_num);
output1_matrix = zeros(b_num,y_num, p_num, p_vol_num);
output_matrix = zeros(b_num,y_num, p_num, p_vol_num);


b_next_matrix = zeros(b_num,y_num, p_num, p_vol_num);

% Preallocation. These eight were assigned inside the 4-deep loop below without
% ever being created first, so MATLAB grew and copied them on every one of the
% b_num*y_num*p_num*p_vol_num iterations -- O(n^2). Harmless at p_num = 7
% (73,500 elements); at p_num = 277 (2,908,500) it dominates everything and a
% single economy takes hours. Preallocating is output-neutral: the loop fills
% every element, and unfilled entries were zero under growth too.
spread_matrix    = zeros(b_num, y_num, p_num, p_vol_num);
spread_matrix_rw = zeros(b_num, y_num, p_num, p_vol_num);
yield_long       = zeros(b_num, y_num, p_num, p_vol_num);
yield_rf         = zeros(b_num, y_num, p_num, p_vol_num);
yield_rf_new     = zeros(b_num, y_num, p_num, p_vol_num);
tm_p             = zeros(p_num, p_num, p_vol_num);
% NOT preallocated here: value_full and value_full_debt. They are assigned far
% below, AFTER this workspace is saved and cleared, so creating them here only
% writes zeros into oil_*.mat. Those then reload as 1-by-y_num rows and turn the
% welfare gain into a y_num-by-y_num broadcast. They are 21 elements; growing
% them costs nothing.
dev_matrix = zeros(b_num,y_num, p_num, p_vol_num);
q_paid_matrix = zeros(b_num,y_num, p_num, p_vol_num);
q_def_free_new_matrix = zeros(b_num, y_num,p_num, p_vol_num);


for i_vol = 1:p_vol_num
    for i_p = 1:p_num
        for i_y=1:y_num
           q_def_free_matrix(i_y,i_p, i_vol) = q_def_free((i_vol-1)*p_num*y_num+ (i_p-1)*y_num+i_y);
            for i_b = 1:b_num
%                q_def_free_matrix(i_b,i_y,i_p, i_vol) = q_def_free((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,1);
                v_matrix(i_b,i_y, i_p, i_vol) = v((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,1);
                v0_matrix(i_b,i_y, i_p, i_vol) = v((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,2);
                v1_matrix(i_b,i_y, i_p, i_vol) = v((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,3);      
                default_matrix(i_b,i_y, i_p, i_vol) = default((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b);

                q_matrix(i_b,i_y, i_p, i_vol) = q((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b);
                q_def_free_new_matrix(i_b,i_y, i_p, i_vol) = q_def_free_new((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,1);
                q_paid_matrix(i_b,i_y, i_p, i_vol) = q_paid((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b);
                b_next_matrix(i_b,i_y, i_p, i_vol) = b_next((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b);
                dev_matrix(i_b,i_y, i_p, i_vol) = dev((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b);

                cons_matrix(i_b,i_y, i_p, i_vol) = consumption ((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,1);
                cons0_matrix(i_b,i_y, i_p, i_vol) = consumption((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,2);
                cons1_matrix(i_b,i_y, i_p, i_vol) = consumption((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,3);
                oil_matrix(i_b,i_y, i_p, i_vol) = oil((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,1);
                oil0_matrix(i_b,i_y, i_p, i_vol) = oil((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,2);
                oil1_matrix(i_b,i_y, i_p, i_vol) = oil((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,3);                
                output_matrix(i_b,i_y, i_p, i_vol) = output((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,1);
                output0_matrix(i_b,i_y, i_p, i_vol) = output((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,2);
                output1_matrix(i_b,i_y, i_p, i_vol) = output((i_vol-1)*p_num*y_num*b_num+ (i_p-1)*y_num*b_num+(i_y-1)*b_num + i_b,3);                
                
            end     
    end
    end
end
for i=1:y_num
    for j=1:y_num
        transition_matrix_y(i, j) = trans_matrix_y((i-1)*y_num + j,1);
    end
end
for i_vol = 1:p_vol_num
    for i_p = 1:p_num
for i_y = 1:y_num
               for i_b = 1:b_num
    
                    q_def_free_matrix(i_b,i_y,i_p,i_vol)= q_def_free_matrix(i_y,i_p,i_vol);
                   
                end
        end
    end 
end

for i=1:p_vol_num
    for j=1:p_vol_num
        transition_matrix_vol(i, j) = trans_matrix_p_vol((i-1)*p_vol_num + j,1);
    end
end

rw=0.01;
for j=1:p_vol_num
    for i=1:p_num
        coupon_matrix(i,j) = (rw+delta)/(1+rw);
    end
end

for i_vol = 1:p_vol_num
    for i_p = 1:p_num
        for i_p_tomorrow = 1:p_num
            
            pointer = (i_vol-1)*p_num*p_num+ (i_p-1)*p_num+ i_p_tomorrow;
            
            tm_p(i_p,i_p_tomorrow,i_vol)= trans_matrix_p(pointer,1);
%             tm_joint(i_p,i_p_tomorrow,i_vol)= trans_matrix_joint(pointer,1);
%             cdf_p(i_p,i_p_tomorrow,i_vol)= cdf_matrix_p(pointer,1);
        end
    end
end
% i_matrix depends on no loop index, but was recomputed inside the INNERMOST
% loop below: a reciprocal of the whole b*y*p*v array plus a logical-indexed
% NaN assignment, 2,908,500 times over, i.e. ~8e12 element operations. At
% p_num = 7 that is 5e9 and merely slow; at p_num = 277 it never finishes.
% Hoisted here. Output is identical -- it was the same array every time.
i_matrix = 1./q_matrix;
i_matrix(default_matrix==1) = nan;

for i_y=1:y_num
    for i_p = 1:p_num
        for i_p_vol =1:p_vol_num
            
  

            %yield_rf(i_y,i_p, i_p_vol) = coupon_matrix(i_p,i_p_vol)/q_def_free_matrix(i_y,i_p,i_p_vol) - delta;
            
            for i_b=1:b_num
                yield_rf(i_b,i_y,i_p, i_p_vol) = coupon_matrix(i_p,i_p_vol)/q_def_free_matrix(i_b,i_y,i_p,i_p_vol) - delta;
                yield_rf_new(i_b,i_y, i_p, i_p_vol) = coupon_matrix(i_p,i_p_vol)/q_def_free_new_matrix(i_b,i_y,i_p,i_p_vol) - delta;
                yield_long(i_b, i_y,i_p, i_p_vol) = coupon_matrix(i_p,i_p_vol)*i_matrix(i_b,i_y,i_p,i_p_vol) - delta;
                spread_matrix(i_b, i_y,i_p, i_p_vol)= 4*(yield_long(i_b,i_y, i_p, i_p_vol) - yield_rf_new(i_b,i_y, i_p, i_p_vol));
                spread_matrix_rw(i_b, i_y,i_p, i_p_vol)= ((1+yield_long(i_b,i_y, i_p, i_p_vol))./ (1+rw)).^4 - 1;               
            end
        end
    end

end

% %% Constructing the transition probabilities:
% 
% transition_reshaped=reshape(trans_matrix_joint,[245,5]);
transition_matrix_joint=zeros(p_num,p_vol_num,p_num,p_vol_num);
for i_vol = 1:p_vol_num
    for i_p = 1:p_num
        for i_vol_tomorrow = 1:p_vol_num
        for i_p_tomorrow = 1:p_num


            transition_matrix_joint(i_p_tomorrow,i_vol_tomorrow,i_p,i_vol) =  trans_matrix_joint((i_vol-1)*p_num*p_vol_num*p_num+ (i_p-1)*p_vol_num*p_num+(i_vol_tomorrow-1)*p_num + i_p_tomorrow,1);
        end
        end 
    end 
end

   
%The three lines below will be uncommented one at a time depending on the model solved    
save(['oil_bm' '.mat']);
%save(['oil_intermediate' '.mat']);
%save(['oil_basic' '.mat'])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all
%fprintf('DEBUG: Loading oil_bm.mat from: %s\n', which('oil_bm.mat'));
%% Loading the benchmark/full model
load oil_bm.mat

% Price nodes for the "low price" / "high price" contrast in Figures 3, 6a, 6b.
% Hardcoded as 2 and 6 originally, which bracket the grid only at p_num = 7; at
% p_num = 549 those sit at 0.2% and 0.9% of the grid, both deep in the left
% tail, so the contrast collapses. Defined by RELATIVE position instead, which
% reduces to exactly 2 and 6 when p_num = 7.
% Defined HERE, after the clear/reload, so it is never saved into oil_*.mat.
% CONTRAST_MODE selects how the two prices are chosen:
%   'fraction' - 16.7% and 83.3% of the grid (reduces to nodes 2 and 6 at p_num=7)
%   'price'    - the nodes nearest the prices the SUBMITTED figures contrasted,
%                so the corrected figures differ only because the MODEL changed
% Read from the environment: a plain variable would not survive the clear all
% that precedes this block.
CONTRAST_MODE = getenv('CONTRAST_MODE');
if isempty(CONTRAST_MODE), CONTRAST_MODE = 'fraction'; end
if strcmp(CONTRAST_MODE,'price')
    tgt_lo = 1.0120; tgt_hi = 1.2562;          % submitted vol-3 grid, nodes 2 and 6
    [~, i_p_low ] = min(abs(exp(p_grid_matrix(:,3)) - tgt_lo));
    [~, i_p_high] = min(abs(exp(p_grid_matrix(:,3)) - tgt_hi));
else
    i_p_low  = max(1,     round(1 + (1/6)*(p_num-1)));
    i_p_high = min(p_num, round(1 + (5/6)*(p_num-1)));
end

% ---- price-index remapping -------------------------------------------------
% The submitted script hardcodes price indices chosen for a 7-node grid:
% index 2 as the low price and 5/6/7 as the top three. Those literals are
% positions, not prices. On a finer grid they point somewhere else entirely --
% at p_num = 549 index 7 sits near the BOTTOM of the grid, which is why
% FIGURE4d came out blank (all three curves fell below the hardcoded y-axis
% floor of 1). pidx maps a submitted 7-grid index to the same RELATIVE position
% on the current grid, and is the identity when p_num == 7.
pidx = @(k) min(p_num, max(1, round(1 + ((k-1)/6)*(p_num-1))));
fprintf('price-node contrast: low = %d, high = %d of %d  (prices %.4f and %.4f)\n', ...
        i_p_low, i_p_high, p_num, exp(p_grid_matrix(i_p_low,3)), exp(p_grid_matrix(i_p_high,3)));
%fprintf('DEBUG: After load, spread_matrix size = ['); fprintf('%d ', size(spread_matrix)); fprintf(']\n');
% scale_y=10;
% dy =0.25*b_grid/mean(scale_y*exp(y_grid));
% y=scale_y*exp(y_grid);
scale_y=10;
dy1 =0.25*b_grid/mean(scale_y*exp(y_grid));
y1=scale_y*exp(y_grid);
spread1=spread_matrix;
p_grid_matrix1 = p_grid_matrix;   % snapshot: later loads overwrite p_grid_matrix
p_vol_grid1    = p_vol_grid;      % snapshot of the benchmark's volatility grid
%fprintf('DEBUG: After assignment, spread1 size = ['); fprintf('%d ', size(spread1)); fprintf(']\n');
% ---- CES feasibility mask (per-state grid) ---------------------------------
% The highest-volatility per-state grid is built from that state's volatility
% treated as PERMANENT: half-width sqrt(p_num-1)*sd_k/sqrt(1-rho_p^2), which
% for state 5 reaches down to p = 0.0892. That is below the CES feasibility
% floor alpha^(1/theta) = 0.3^2 = 0.09 documented in oil_prod_CES.f90, so the
% oil optimum there is not interior and output diverges: 7.7e10 at
% (i_p=1,i_vol=5) against a maximum of 29.2 over every other node.
%
% The solved VALUE function is unaffected -- CRRA at sigma=2 gives u(c) = -1/c,
% bounded above by zero, so unbounded consumption adds nothing and max|V| moves
% only 5.409 -> 5.431 across volatility states. But any MEAN of output is
% destroyed: including that node puts mean output at 2.9e8 and collapses the
% Debt/GDP axis of FIGURE2 onto zero, which is why the Full Model line
% disappeared. Mask the infeasible nodes before averaging.
feas_node = squeeze(max(max(output_matrix,[],1),[],2)) < 1d3;   % p_num x p_vol_num
if ~all(feas_node(:))
    [bi,bj] = find(~feas_node);
    fprintf('feasibility mask: dropping %d of %d price nodes:', ...
            numel(bi), numel(feas_node));
    for q = 1:numel(bi)
        fprintf(' (i_p=%d,i_vol=%d,p=%.4f)', bi(q), bj(q), exp(p_grid_matrix(bi(q),bj(q))));
    end
    fprintf('\n');
end
O__ = reshape(output_matrix, size(output_matrix,1), size(output_matrix,2), []);
O__(:,:,~feas_node(:)) = NaN;
mean_output1 = mean(O__(:),'omitnan');
fprintf('mean output: %.4f (masked)  vs %.4e (unmasked)\n', ...
        mean_output1, mean(output_matrix(:)));
debt_output1=0.25*b_grid./mean_output1;
consumption1=cons_matrix;
value1=v_matrix;
output1=output_matrix;
dprice_matrix_3=exp(p_grid_3_matrix(i_p_high,:))-exp(p_grid_3_matrix(i_p_low,:));

% ---- matched-price contrast (per-state grid fix) --------------------------
% With use_common_p_grid=.false. the model solves on a SEPARATE Rouwenhorst
% grid per volatility state: p_grid_matrix(:,k) is symmetric in logs about
% mean_p with half-width sqrt(p_num-1)*sd_k, so its width scales with the
% state's volatility. Every state shares only the central node exp(mean_p).
%
% A FIXED price INDEX therefore denotes a different price in each state. The
% submitted Figures 3 and 5 differenced spreads at indices i_p_low/i_p_high
% and divided by state 3's price interval for every state, so a state whose
% grid is wider contributed a larger numerator over an unchanged denominator.
% Here the node2->node6 interval runs 1.237 (state 1) to 5.911 (state 5); the
% state4/state2 ratio alone is 2.13, which accounts for most of the reported
% 3x state dependence. The slope was a grid artifact, not a model property.
%
% Fix: choose ONE physical price pair and interpolate each state's spread
% schedule onto it, so numerator and denominator refer to the same price
% change in every state. The pair must lie in the common support of all
% states, i.e. inside the NARROWEST (lowest-volatility) grid.
p_lo_common = max(exp(p_grid_matrix(1,       :)));   % highest per-state floor
p_hi_common = min(exp(p_grid_matrix(p_num,   :)));   % lowest  per-state ceiling
if strcmp(CONTRAST_MODE,'price')
    p_lo_tgt = 1.0120;  p_hi_tgt = 1.2562;           % the submitted contrast
else
    % Rouwenhorst is symmetric in logs about the process mean, so for odd
    % p_num the central node equals exp(mean_p) in EVERY state -- the one
    % price all five grids share. Read it off the grid rather than
    % re-deriving mean_p, which this script never loads.
    p_mid    = exp(p_grid_matrix(ceil(p_num/2), 3));
    p_lo_tgt = 0.90*p_mid;  p_hi_tgt = 1.10*p_mid;    % local +/-10% contrast
end
p_lo_tgt = max(p_lo_tgt, p_lo_common);
p_hi_tgt = min(p_hi_tgt, p_hi_common);
dprice_matched = p_hi_tgt - p_lo_tgt;
fprintf(['matched-price contrast: %.4f -> %.4f (dp=%.4f); ' ...
         'common support [%.4f, %.4f]\n'], ...
        p_lo_tgt, p_hi_tgt, dprice_matched, p_lo_common, p_hi_common);

% slope_at_matched_prices(S4, i_b, i_vol) returns a 1 x y_num row of
% d(spread)/d(price) at the matched pair, interpolated on state i_vol's grid.
slope_at_matched_prices = @(S4, i_b, i_vol) ( ...
      interp1(exp(p_grid_matrix(:,i_vol)), squeeze(S4(i_b,:,:,i_vol)).', p_hi_tgt, 'linear') ...
    - interp1(exp(p_grid_matrix(:,i_vol)), squeeze(S4(i_b,:,:,i_vol)).', p_lo_tgt, 'linear') ...
    ) ./ dprice_matched;
dvol_matrix=exp(p_vol_grid(4)/2)-exp(p_vol_grid(3)/2);
pdf_p_matrix1 = zeros(p_vol_num,p_num); %will have r across the columns, and r_vol as the different rows

for i_p_vol = 1:p_vol_num
    for i_p = 1:p_num
        pdf_p_matrix1(i_p_vol, i_p)=pdf_p( (i_p_vol -1)*p_num + i_p);
    end
end

i_b_welfare1=1; % the level of debt at which welfare gains are computed
% at zero debt for full model
% aux = .35*4 ;
% aa=(b_grid-aux*ones(b_num,1)).^2;
% [~, i_b_mean] = min(aa);
i_b_mean=44;
i_b_welfare_debt1=i_b_mean; % the level of debt at which welfare gains are computed


for i_y =1:y_num
    
    acum_1_full_debt=0;
    for i_p_vol = 1:p_vol_num
        acum_2_full_debt=0;
        for i_p =1:p_num
            acum_2_full_debt = acum_2_full_debt + pdf_p_matrix1(i_p_vol,i_p)* v_matrix(i_b_welfare_debt1,i_y,i_p,i_p_vol);
        end
        
        acum_1_full_debt=acum_1_full_debt + acum_2_full_debt * pdf_p_vol(i_p_vol);
    end
    
    value_full_debt(i_y) = acum_1_full_debt;
end
value_full_debt=value_full_debt(:);

% full model at zero debt
for i_y =1:y_num
    
    acum_1_full=0;
    for i_p_vol = 1:p_vol_num
        acum_2_full=0;
        for i_p =1:p_num
            acum_2_full = acum_2_full + pdf_p_matrix1(i_p_vol,i_p)* v_matrix(i_b_welfare1,i_y,i_p,i_p_vol);
        end
        
        acum_1_full=acum_1_full + acum_2_full * pdf_p_vol(i_p_vol);
    end
    
    value_full(i_y) = acum_1_full;
end
value_full=value_full(:);

%% Figures 3,4abcd,5,6ab: we are going to draw these figures first right after solving the benchmark (full) model as these figures are based only this model


%% Figure 3: Effect of Volatility on Spread Sensitivity to Oil Price


% Load the full model
load oil_bm.mat

% Price difference for slope calculation
dprice = exp(p_grid_3_matrix(i_p_high,3)) - exp(p_grid_3_matrix(i_p_low,3));

% Mean debt index
i_b3 = 44;

% Extract output values
y_num = size(output_matrix, 2);
% x-axis output is evaluated at the price the slope is measured AROUND (the
% shared central node), not at pidx(2). Same issue as FIGURE2/FIGURE5: with
% the old index the abscissa was output at a price the slope never used.
output_y_values = squeeze(output_matrix(i_b3, :, ceil(p_num/2), 3));

% Compute slopes for vol states 2, 3, 4
vol_states = [2, 3, 4];
slopes_all = zeros(y_num, 3);

for vol_idx = 1:3
    i_vol = vol_states(vol_idx);

    % Matched-price slope. The old code took spread_matrix at the FIXED
    % indices i_p_low/i_p_high and divided by `dprice`, state 3's interval,
    % for all three states -- see the note at dprice_matched above. Each
    % state's grid has a different width, so that compared unequal price
    % changes and manufactured state dependence from the grid.
    slopes_all(:, vol_idx) = slope_at_matched_prices(spread_matrix, i_b3, i_vol).';
end

figure('Position', [100, 100, 800, 600]);

% Define colors (colorblind-friendly)
color_low = [0.8, 0.2, 0.2];     % Red
color_mean = [0.2, 0.4, 0.8];    % Blue  
color_high = [0.2, 0.7, 0.3];    % Green

% Plot lines
h1 = plot(output_y_values, slopes_all(:, 1), '-', 'LineWidth', 3, 'Color', color_low);
hold on;
h2 = plot(output_y_values, slopes_all(:, 2), '-', 'LineWidth', 3, 'Color', color_mean);
h3 = plot(output_y_values, slopes_all(:, 3), '-', 'LineWidth', 3, 'Color', color_high);

% Axis labels
xlabel('Output', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Spread Slope ($\partial s / \partial p$)', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Legend
leg = legend([h1, h2, h3], {'Low Volatility', 'Mean Volatility', 'High Volatility'}, ...
    'Location', 'northeast', 'FontSize', 14);
legend boxoff;

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');
% output range depends on the price grid; autoscale instead of [5.5,8]
xo = output_y_values(isfinite(output_y_values)); xlim([min(xo) max(xo)]);
% ylim 0..0.09 is the submitted figure's scale, set when the slopes ran
% 0.002-0.092. Under the narrow ('price') contrast the slopes are an order of
% magnitude smaller away from the default boundary -- 0.0007 to 0.004 -- so
% that scale crushes all three curves onto one line and hides a state
% dependence that peaks at 4.4x. Autoscale to the non-exploding part instead.
% Autoscale in BOTH contrast modes. The fixed 0..0.09 was fine at the
% submitted calibration but the slope level moves with the oil elasticity:
% at sigma_oil = 0.3 (theta = -2.333) the slopes run 0.001-0.005, so the
% submitted scale crushes all three curves onto the axis and hides whatever
% ordering there is. Cap at the submitted 0.09 so the figure never zooms
% further OUT than the published one.
finite_sl = slopes_all(isfinite(slopes_all) & slopes_all > 0);
if isempty(finite_sl)
    ylim([0, 0.09]);
else
    ylim([0, min(0.09, max(3*median(finite_sl), 1.15*prctile(finite_sl,90)))]);
end

% Remove grid for cleaner look (optional - uncomment if you want grid)
% grid on;
% set(gca, 'GridLineStyle', '--', 'GridAlpha', 0.3);

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save 
FigureName = 'FIGURE3';
saveas(gcf, [FigureName '.jpg']);

%% Figure 5: Effect of debt on spread slope


% Define three debt levels
i_b_low = 34;
i_b_mean = 44;
i_b_high = 54;
debt_indices = [i_b_low, i_b_mean, i_b_high];


% Use middle volatility state
i_vol = 3;

% Get number of output grid points
y_num = size(output_matrix, 2);

% Compute spread slope for each debt level
slopes_debt = zeros(y_num, 3);
output_vals = cell(1, 3);

for d_idx = 1:3
    i_b = debt_indices(d_idx);
    
    % Matched-price slope, same fix as FIGURE3. Here the volatility state is
    % held at 3 and debt varies, so the old fixed-index version was internally
    % consistent -- but it still measured a chord over state 3's full
    % node2->node6 span (2.45 in price) rather than a local derivative.
    slopes_debt(:, d_idx) = slope_at_matched_prices(spread_matrix, i_b, i_vol).';
    % pidx(4): index 4 was a mid-grid price on the submitted 7-node grid; on
    % 549 nodes it is p ~ 0.645, near the floor, so the x-axis was output at
    % a price the slope was never measured at. Same bug as FIGURE2.
    output_vals{d_idx} = squeeze(output_matrix(i_b, :, pidx(4), i_vol));
end


figure('Position', [100, 100, 800, 600]);

% Define colors (colorblind-friendly)
color_low = [0.8, 0.2, 0.2];     % Red
color_mean = [0.2, 0.4, 0.8];    % Blue  
color_high = [0.2, 0.7, 0.3];    % Green

% Plot lines
h1 = plot(output_vals{1}, slopes_debt(:, 1), '-', 'LineWidth', 3, 'Color', color_low);
hold on;
h2 = plot(output_vals{2}, slopes_debt(:, 2), '-', 'LineWidth', 3, 'Color', color_mean);
h3 = plot(output_vals{3}, slopes_debt(:, 3), '-', 'LineWidth', 3, 'Color', color_high);

% Axis labels
xlabel('Output', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Spread Slope ($\partial s / \partial p$)', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Legend
leg = legend([h1, h2, h3], {'Low Debt', 'Mean Debt', 'High Debt'}, ...
    'Location', 'northeast', 'FontSize', 14);
legend boxoff;

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');
% FIGURE5: output range moves with the price grid; autoscale
xo5 = cell2mat(cellfun(@(v) v(isfinite(v)), output_vals, 'UniformOutput', false));
xlim([min(xo5) max(xo5)]);
% Autoscale, same reason as FIGURE3: the slope LEVEL moves with the oil
% elasticity, and at sigma_oil = 0.3 these run 0-0.05, so the submitted
% [-0.02, 0.35] crushes the debt ordering into the bottom 15% of the panel.
% Cap at the submitted 0.35 so it never zooms out past the published scale.
fs5 = slopes_debt(isfinite(slopes_debt) & slopes_debt > 0);
if isempty(fs5)
    ylim([-0.02, 0.35]);
else
    ylim([-0.02, min(0.35, 1.15*max(fs5))]);
end

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save in multiple formats
FigureName = 'FIGURE5';
saveas(gcf, [FigureName '.jpg']);

%% Figure 6a, b
%% Figures 6a and 6b: Debt Issuance Policy at Low and High Volatility

%% Compute issuance matrix
issuance_matrix = zeros(b_num, y_num, p_num, p_vol_num);

for i_b = 1:b_num
    b_today = b_grid(i_b);
    
    for i_y = 1:y_num
        for i_p = 1:p_num
            for i_p_vol = 1:p_vol_num
                b_prime = b_grid(b_next_matrix(i_b, i_y, i_p, i_p_vol));
                issuance_matrix(i_b, i_y, i_p, i_p_vol) = b_prime;
            end
        end
    end
end

% Only look at issuance in No-Default states
issuance_matrix(default_matrix == 1) = NaN;

% Define colors (colorblind-friendly)
color_low_price = [0.8, 0.2, 0.2];    % Red
color_high_price = [0.2, 0.4, 0.8];   % Blue

%% Figure 6a: Debt Issuance at Low Volatility
figure('Position', [100, 100, 800, 600]);

% Low volatility state
i_vol_low = 2;
i_y_mid = 11;  % Middle income level

% Compute x and y values
x_low_price_a = b_grid ./ mean(output_matrix(:, i_y_mid, i_p_low, i_vol_low));
y_low_price_a = b_grid(b_next_matrix(:, i_y_mid, i_p_low, i_vol_low)) ./ mean(output_matrix(:, i_y_mid, i_p_low, i_vol_low));

x_high_price_a = b_grid ./ mean(output_matrix(:, i_y_mid, i_p_high, i_vol_low));
y_high_price_a = b_grid(b_next_matrix(:, i_y_mid, i_p_high, i_vol_low)) ./ mean(output_matrix(:, i_y_mid, i_p_high, i_vol_low));

% Plot
h1 = plot(x_low_price_a, y_low_price_a, '-', 'LineWidth', 3, 'Color', color_low_price);
hold on;
h2 = plot(x_high_price_a, y_high_price_a, '-', 'LineWidth', 3, 'Color', color_high_price);

% Axis labels
xlabel('Current Debt/Output', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Next Period Debt/Output', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Legend
leg = legend([h1, h2], {'Low Oil Price', 'High Oil Price'}, ...
    'Location', 'northwest', 'FontSize', 14);
legend boxoff;

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');
xlim([0, 4]);
ylim([0, 2]);

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save Figure 6a
FigureName = 'FIGURE6a';
saveas(gcf, [FigureName '.jpg']);
%% Figure 6b: Debt Issuance at High Volatility
figure('Position', [100, 100, 800, 600]);

% High volatility state
i_vol_high = 4;

% Compute x and y values
x_low_price_b = b_grid ./ mean(output_matrix(:, i_y_mid, i_p_low, i_vol_high));
y_low_price_b = b_grid(b_next_matrix(:, i_y_mid, i_p_low, i_vol_high)) ./ mean(output_matrix(:, i_y_mid, i_p_low, i_vol_high));

x_high_price_b = b_grid ./ mean(output_matrix(:, i_y_mid, i_p_high, i_vol_high));
y_high_price_b = b_grid(b_next_matrix(:, i_y_mid, i_p_high, i_vol_high)) ./ mean(output_matrix(:, i_y_mid, i_p_high, i_vol_high));

% Plot
h1 = plot(x_low_price_b, y_low_price_b, '-', 'LineWidth', 3, 'Color', color_low_price);
hold on;
h2 = plot(x_high_price_b, y_high_price_b, '-', 'LineWidth', 3, 'Color', color_high_price);

% Axis labels
xlabel('Current Debt/Output', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Next Period Debt/Output', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Legend
leg = legend([h1, h2], {'Low Oil Price', 'High Oil Price'}, ...
    'Location', 'northwest', 'FontSize', 14);
legend boxoff;

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');
xlim([0, 4]);
ylim([0, 2]);

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save Figure 6b
FigureName = 'FIGURE6b';
saveas(gcf, [FigureName '.jpg']);

%% Figure 4

%% Output vs price (fig 4b)

%% Figure 4b: Output vs Oil Price

% Parameters
i_b = 44;       % Debt index (mean debt)
i_y = 11;       % Income index (middle)
i_vol = 3;      % Volatility state (mean)

% Extract data
price_values = price(:, i_vol);
output_values = squeeze(output_matrix(i_b, i_y, :, i_vol))';


figure('Position', [100, 100, 800, 600]);

% Define color
color_line = [0.8, 0.2, 0.2];  % Red

% Plot
h1 = plot(price_values, output_values, '-', 'LineWidth', 3, 'Color', color_line);

% Axis labels
xlabel('Oil Price', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Output', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');

% Optional: Set axis limits based on data range (adjust as needed)
xlim([min(price_values) - 0.02, max(price_values) + 0.02]);
ylim([min(output_values) - 0.05, max(output_values) + 0.05]);

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save in multiple formats
FigureName = 'FIGURE4b';

saveas(gcf, [FigureName '.jpg']);
%% Fig 4a
%% Figure 4a: Oil Imports vs Oil Price


% Extract data
price_values = price(:, i_vol);
oil_import_values = squeeze(oil_matrix(i_b, i_y, :, i_vol))';

figure('Position', [100, 100, 800, 600]);

% Define color
color_line = [0.8, 0.2, 0.2];  % Red

% Plot
h1 = plot(price_values, oil_import_values, '-', 'LineWidth', 3, 'Color', color_line);

% Axis labels
xlabel('Oil Price', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Oil Imports', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');

% Optional: Set axis limits based on data range (adjust as needed)
xlim([min(price_values) - 0.02, max(price_values) + 0.02]);
ylim([min(oil_import_values) - 0.02, max(oil_import_values) + 0.02]);

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save in multiple formats
FigureName = 'FIGURE4a';

saveas(gcf, [FigureName '.jpg']);
   %% Fig 4c 
   %% Figure 4c: Spread vs Oil Price

% Extract data
price_values = price(:, i_vol);
spread_values = squeeze(spread_matrix(i_b, i_y, :, i_vol))';

%% Publication-quality plot
figure('Position', [100, 100, 800, 600]);

% Define color
color_line = [0.8, 0.2, 0.2];  % Red

% Plot
% The raw schedule carries an 11-cycle ripple that is a DISCRETISATION
% artifact, not economics. With rho_p = 0.98 the conditional mean of log p
% advances rho of a grid node per node, so it slips (1-rho) of a node each
% step and realigns with the grid every 1/(1-rho) = 50 nodes. That puts the
% ripple at a known frequency: p_num*(1-rho) = 11 cycles across the grid
% (observed: exactly 11, amplitude 5.1% of the trend).
%
% Source confirmed upstream in the transition matrix: its conditional mean
% departs from the exact AR(1) law by up to 1.4e-3 (0.7 of a grid node) and
% its conditional sd wobbles 1.26%. Ruled out: the debt policy (only 2
% distinct values across all 549 price nodes) and the default set (1 change
% in 548 price steps).
%
% Smoothed with a local CUBIC over 2 aliasing periods. A plain boxcar of one
% period nulls the frequency more sharply but biases this steeply convex
% schedule by 16% of its range; the local cubic preserves the trend, costing
% 6.6% deviation for a 3.7x reduction in ripple amplitude.
%
% NOTE: this is cosmetic. The artifact is in the solved transition matrix, so
% removing it properly requires re-solving with a discretisation that matches
% the AR(1) moments exactly at rho = 0.98. The raw series is drawn underneath
% in grey so the smoothing is always visible.
sg_win = 2*round(1/(1-0.98)) + 1;            % 101 nodes = two aliasing periods
sg_ord = 3;
sg_h   = (sg_win-1)/2;
sg_t   = (-sg_h:sg_h)';
sg_A   = sg_t.^(0:sg_ord);
sg_W   = (sg_A'*sg_A)\sg_A';
sg_c   = sg_W(1,:);                          % weights giving the fit at the centre
% Edge-aware: near the ends the window is truncated and the local cubic is
% refitted on whatever points are available, then evaluated at the node. A
% fixed centred window would discard sg_h nodes at each end -- 18% of the
% price range here, including the steep rise at the top where the schedule is
% most interesting.
sg_n = numel(spread_values);
spread_smooth = spread_values;
for sg_i = 1:sg_n
    sg_lo = max(1, sg_i-sg_h); sg_hi = min(sg_n, sg_i+sg_h);
    % Drop non-finite nodes from the window. The spread is NaN wherever the
    % country defaults with certainty, so q = 0 and the yield is undefined --
    % which happens at the top price nodes once the default cost depends on
    % the oil price. Without this the NaN propagates through the regression
    % and blanks the entire smoothed curve, not just the undefined nodes.
    sg_idx = sg_lo:sg_hi;
    sg_ok  = isfinite(spread_values(sg_idx));
    sg_idx = sg_idx(sg_ok);
    if numel(sg_idx) < sg_ord+1 || ~isfinite(spread_values(sg_i))
        spread_smooth(sg_i) = spread_values(sg_i);   % leave as-is (incl. NaN)
        continue
    end
    sg_tt = sg_idx' - sg_i;
    sg_AA = sg_tt.^(0:sg_ord);
    sg_bb = (sg_AA'*sg_AA)\(sg_AA'*spread_values(sg_idx)');
    spread_smooth(sg_i) = sg_bb(1);          % fitted value at t = 0
end
plot(price_values, spread_values, '-', 'LineWidth', 1, 'Color', [0.78 0.78 0.78]);
hold on;
plot(price_values, spread_smooth, '-', 'LineWidth', 3, 'Color', color_line);
hold off;

% Axis labels
xlabel('Oil Price', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Spread', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save figure
FigureName = 'FIGURE4c';
saveas(gcf, [FigureName '.jpg']);

fprintf('Figure 4c saved.\n');

        %% Fig 4d

%% Figure 4d: Expected Oil Price vs Volatility


%% Construct transition matrices
for i = 1:p_vol_num
    for j = 1:p_vol_num
        transition_matrix_vol(i, j) = trans_matrix_p_vol((i-1)*p_vol_num + j, 1);
    end
end

transition_matrix_joint = zeros(p_num, p_vol_num, p_num, p_vol_num);
for i_vol = 1:p_vol_num
    for i_p = 1:p_num
        for i_vol_tomorrow = 1:p_vol_num
            for i_p_tomorrow = 1:p_num
                transition_matrix_joint(i_p_tomorrow, i_vol_tomorrow, i_p, i_vol) = ...
                    trans_matrix_joint((i_vol-1)*p_num*p_vol_num*p_num + (i_p-1)*p_vol_num*p_num + (i_vol_tomorrow-1)*p_num + i_p_tomorrow, 1);
            end
        end
    end
end

%% Compute expected prices at each price level across volatility states

% Initialize storage
p_grid_matrices = {p_grid_1_matrix, p_grid_2_matrix, p_grid_3_matrix, p_grid_4_matrix, p_grid_5_matrix};
exp_prices = zeros(7, p_vol_num);

% Two corrections to this block:
%  (1) pidx() -- see the note above; indices 5/6/7 are remapped to the same
%      relative grid positions, so "high price" stays a high price.
%  (2) tomorrow's price is valued on TOMORROW's grid, exp(p_grid_matrix), not
%      on p_grid_matrices{i_vol} (today's volatility state's grid). Under the
%      common grid the two coincide, so this changes nothing here, but it is
%      the correct expectation and it matters on a per-state grid.
% Price nodes anchored to the ERGODIC distribution, not to relative grid
% position. pidx() preserves position on the grid, which was fine when the
% grid spanned p in [0.64, 1.97] but picks p = 2.3 / 4.8 / 10.2 on the wider
% grid the corrected volatility requires -- absurd as "low/mean/high price"
% when the mean price is about 1.37.
pdf_p_erg = zeros(p_num,1);
for i_pv = 1:p_vol_num
    pdf_p_erg = pdf_p_erg + pdf_p((i_pv-1)*p_num + (1:p_num))';
end
pdf_p_erg = pdf_p_erg / sum(pdf_p_erg);
cdf_p_erg = cumsum(pdf_p_erg);
node_at = @(tgt) find(cdf_p_erg >= tgt, 1, 'first');
sel = [node_at(0.10) node_at(0.50) node_at(0.90)];   % low / mean / high price
fprintf('FIGURE4d price nodes (ergodic p10/p50/p90): %.4f %.4f %.4f\n', ...
        exp(p_grid_matrix(sel(1),3)), exp(p_grid_matrix(sel(2),3)), exp(p_grid_matrix(sel(3),3)));
for kk = 1:3
    for i_vol = 1:p_vol_num
        expectation = transition_matrix_joint(:, :, sel(kk), i_vol) .* exp(p_grid_matrix);
        exp_prices(4+kk, i_vol) = sum(expectation, 'all');
    end
end

% Extract expected prices for price levels 5, 6, 7
exp_5 = exp_prices(5, :);
exp_6 = exp_prices(6, :);
exp_7 = exp_prices(7, :);

%% Publication-quality plot
figure('Position', [100, 100, 800, 600]);

% Define colors (colorblind-friendly)
color_low = [0.8, 0.2, 0.2];     % Red
color_mean = [0.2, 0.4, 0.8];    % Blue
color_high = [0.2, 0.7, 0.3];    % Green

% Volatility values for x-axis
% exp(h/2): h is the log VARIANCE (stochvol convention), so the conditional
% standard deviation is exp(h/2). See REVISION_NOTES Part 21.
volatility = exp(p_vol_grid/2);

% Plot
h1 = plot(volatility, exp_5, '-', 'LineWidth', 3, 'Color', color_low);
hold on;
h2 = plot(volatility, exp_6, '-', 'LineWidth', 3, 'Color', color_mean);
h3 = plot(volatility, exp_7, '-', 'LineWidth', 3, 'Color', color_high);

% Axis labels
xlabel('Volatility', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Expected Oil Price', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Legend
leg = legend([h1, h2, h3], {'Low Price', 'Mean Price', 'High Price'}, ...
    'Location', 'northwest', 'FontSize', 14);
legend boxoff;

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');
% y limits were hardcoded to [1,2], which fits only the old price scale.
yy = [exp_5(:); exp_6(:); exp_7(:)]; pad = 0.05*(max(yy)-min(yy)) + 1e-6;
axis([volatility(1), volatility(5), min(yy)-pad, max(yy)+pad]);

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save figure
FigureName = 'FIGURE4d';
saveas(gcf, [FigureName '.jpg']);

fprintf('Figure 4d saved.\n');


%% Loading the intermediate model
load oil_intermediate.mat %(=intermediate=vol constant at mean, but level changing)
dy2 =0.25*b_grid/mean(scale_y*exp(y_grid));
y2=scale_y*exp(y_grid);
spread2=spread_matrix;
p_grid_matrix2 = reshape(p_grid, p_num, p_vol_num);   % intermediate's own grid
p_vol_grid2    = p_vol_grid;                          % its (constant) volatility level
mean_output2=mean(output_matrix(:));   % was 3 nested means, which leaves a 4-D array
                                       % whenever p_vol_num > 1 in the comparison economy
debt_output2=0.25*b_grid./mean_output2;
consumption2=cons_matrix;
value2=v_matrix;
output2=output_matrix;

i_b_welfare2=1; % the level of debt at which welfare gains are computed



pdf_p_matrix2 = zeros(p_vol_num,p_num); %will have r across the columns, and r_vol as the different rows

for i_p_vol = 1:p_vol_num
    for i_p = 1:p_num
        pdf_p_matrix2(i_p_vol, i_p)=pdf_p( (i_p_vol -1)*p_num + i_p);
    end
end

for i_y =1:y_num
    
    acum_1_inter=0;
    % The loop over volatility states was commented out. With the intermediate
    % economy at p_vol_num = 1 that is harmless -- one state, pdf_p_vol(1) = 1 --
    % but i_p_vol was then whatever an earlier loop left behind, and the term is
    % still scaled by pdf_p_vol(i_p_vol). At p_vol_num = 5 that returns roughly a
    % fifth of the expected value and the welfare gain explodes (-930% observed).
    % Restored; identical when p_vol_num = 1.
    for i_p_vol = 1:p_vol_num
        acum_2_inter=0;
        for i_p =1:p_num
            acum_2_inter = acum_2_inter + pdf_p_matrix2(i_p_vol,i_p)* v_matrix(i_b_welfare2,i_y,i_p,i_p_vol);
        end
        
        acum_1_inter=acum_1_inter + acum_2_inter * pdf_p_vol(i_p_vol);
    end
    
    value_inter(i_y) = acum_1_inter;
end
value_inter=value_inter(:);

% Intermediate model at mean debt
% aux = .35*4 ;
% aa=(b_grid-aux*ones(b_num,1)).^2;
% [~, i_b_mean] = min(aa);
i_b_mean=44;
i_b_welfare_debt2=i_b_mean; % the level of debt at which welfare gains are computed

for i_y =1:y_num
    
    acum_1_inter_debt=0;
     for i_p_vol = 1:p_vol_num
        acum_2_inter_debt=0;
        for i_p =1:p_num
            acum_2_inter_debt = acum_2_inter_debt + pdf_p_matrix2(i_p_vol,i_p)* v_matrix(i_b_welfare_debt2,i_y,i_p,i_p_vol);
        end
        
        acum_1_inter_debt=acum_1_inter_debt + acum_2_inter_debt * pdf_p_vol(i_p_vol);
     end
    
    value_inter_debt(i_y) = acum_1_inter_debt;
end
value_inter_debt=value_inter_debt(:);

% value_inter = v_matrix(i_b_welfare_baseline,:,6,1);
%  value_baseline = value_baseline(:); %make it column vector (in case it wasn't)
sigma_coeff = 2; %Coeff of RRA in the calibration

%% Loading the basic model

load oil_basic %(=oil price level and vol both are constant)
dy3 =0.25*b_grid/mean(scale_y*exp(y_grid));
y3=scale_y*exp(y_grid);
spread3=spread_matrix;
p_grid_basic   = exp(p_grid(1));                      % basic's single price node
mean_output3=mean(output_matrix(:));   % dimension-agnostic
debt_output3=0.25*b_grid./mean_output3;
consumption3=cons_matrix;
value3=v_matrix;
output3=output_matrix;


i_b_welfare3=1; % the level of debt at which welfare gains are computed



pdf_p_matrix3 = zeros(p_vol_num,p_num); %will have r across the columns, and r_vol as the different rows

for i_p_vol = 1:p_vol_num
    for i_p = 1:p_num
        pdf_p_matrix3(i_p_vol, i_p)=pdf_p( (i_p_vol -1)*p_num + i_p);
    end
end

for i_y =1:y_num
    
    acum_1_basic=0;
     for i_p_vol = 1:p_vol_num
        acum_2_basic=0;
        for i_p =1:p_num
            acum_2_basic = acum_2_basic + pdf_p_matrix3(i_p_vol,i_p)* v_matrix(i_b_welfare3,i_y,i_p,i_p_vol);
        end
        
        acum_1_basic=acum_1_basic + acum_2_basic * pdf_p_vol(i_p_vol);
     end
    
    value_basic(i_y) = acum_1_basic;
end
value_basic=value_basic(:);

% Basic model at mean debt
% aux = .35*4 ;
% aa=(b_grid-aux*ones(b_num,1)).^2;
% [~, i_b_mean] = min(aa);
i_b_mean=44;
i_b_welfare_debt3=i_b_mean; % the level of debt at which welfare gains are computed

for i_y =1:y_num
    
    acum_1_basic_debt=0;
     for i_p_vol = 1:p_vol_num
        acum_2_basic_debt=0;
        for i_p =1:p_num
            acum_2_basic_debt = acum_2_basic_debt + pdf_p_matrix3(i_p_vol,i_p)* v_matrix(i_b_welfare_debt3,i_y,i_p,i_p_vol);
        end
        
        acum_1_basic_debt=acum_1_basic_debt + acum_2_basic_debt * pdf_p_vol(i_p_vol);
     end
    
    value_basic_debt(i_y) = acum_1_basic_debt;
end
value_basic_debt=value_basic_debt(:);

% value_baseline = v_matrix_baseline(i_b_welfare_baseline,:,6,1);
%  value_baseline = value_baseline(:); %make it column vector (in case it wasn't)
sigma_coeff = 2; %Coeff of RRA in the calibration

%% Figure 2: Spread-debt menu in Full vs Intermediate vs Basic model

figure('Position', [100, 100, 800, 600]);

% Define colors (colorblind-friendly)
color_full = [0.2, 0.7, 0.3];     % Green
color_inter = [0.2, 0.4, 0.8];    % Blue
color_basic = [0.8, 0.2, 0.2];    % Red

% Plot
% pidx(4): index 4 was the MEAN price on the submitted 7-node grid; on a
% 549-node grid it is p ~ 0.645, near the floor, so Full and Intermediate
% were being drawn at cheap oil while Basic sat at its single mean price.
% Full and Intermediate differ by ~0.0002 pp on a 4 pp axis, so a solid line
% drawn first is completely painted over by Intermediate. Draw Full LAST and
% dashed so both are visible; the coincidence is the result, not a defect.
hold on;
% ---- evaluate all three economies at ONE physical price ------------------
% Each economy centres its own grid differently: the benchmark's central node
% is exp(mean_p) = 1.1275, the LEVEL-MATCHED intermediate has mean_p shifted
% so its simulated E[p] matches, putting its central node at 1.1090, and the
% basic economy is pinned at the ergodic MEAN price 1.3339 -- 18% above the
% benchmark's node, because Rouwenhorst centres on the median of log p while
% the basic pin targets the mean of p. Plotting each at its own node compared
% three different oil prices and made the Basic schedule look high by
% construction. Interpolate all three onto the benchmark's central node.
% The common price has to be the BASIC economy's, since it has a single price
% node and cannot be interpolated anywhere else. Full and intermediate are
% brought to it.
p_fig2 = p_grid_basic;
pm1 = exp(p_grid_matrix1(:,3));  pm2 = exp(p_grid_matrix2(:,1));
% ---- match the VOLATILITY too -------------------------------------------
% The intermediate economy pins h at mu_h + var_h/2, a conditional sd of
% 0.1250. The benchmark's five states are 0.0639 / 0.0856 / 0.1147 / 0.1538 /
% 0.2061, so plotting it at state 3 compared sd 0.1147 against 0.1250. The
% spread falls monotonically in volatility here (3.65 -> 2.99 across states),
% so that mismatch flattered the benchmark. Interpolate the benchmark over h
% to the intermediate's level -- h is the log variance and the grid is evenly
% spaced in h, so interpolate there rather than in sd.
h_target = p_vol_grid2(1);
s_full_by_vol = zeros(size(spread1,1), numel(p_vol_grid1));
for kk = 1:numel(p_vol_grid1)
    s_full_by_vol(:,kk) = interp1(exp(p_grid_matrix1(:,kk)), ...
                                  squeeze(spread1(:,11,:,kk)).', p_fig2, 'linear').';
end
s_full_f2 = 100*interp1(p_vol_grid1(:), s_full_by_vol.', h_target, 'linear').';
s_int_f2  = 100*interp1(pm2, squeeze(spread2(:,11,:,1)).', p_fig2, 'linear').';
fprintf('FIGURE2 volatility: benchmark interpolated to h = %.5f (sd %.4f), intermediate sd %.4f\n', ...
        h_target, exp(h_target/2), exp(p_vol_grid2(1)/2));
s_bas_f2  = 100*spread3(:,11);          % single price node, already at p_fig2
fprintf(['FIGURE2 evaluated at p = %.4f  (own central nodes: full %.4f, ' ...
         'intermediate %.4f, basic %.4f)\n'], p_fig2, ...
        pm1(ceil(numel(pm1)/2)), pm2(ceil(numel(pm2)/2)), p_grid_basic);
h2 = plot(debt_output2, s_int_f2',  '-',  'LineWidth', 3,   'Color', color_inter);
h1 = plot(debt_output1, s_full_f2', '--', 'LineWidth', 3.5, 'Color', color_full);
h3 = plot(debt_output3, s_bas_f2',  '-',  'LineWidth', 3,   'Color', color_basic);

% Axis labels
xlabel('Debt/GDP', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Annual Spread (\%)', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Legend
leg = legend([h1, h2, h3], {'Full Model', 'Intermediate Model', 'Basic Model'}, ...
    'Location', 'northwest', 'FontSize', 14);
legend boxoff;

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on');
axis([0, 0.4, 1, 5]);

% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save figure
FigureName = 'FIGURE2';
saveas(gcf, [FigureName '.jpg']);

fprintf('Figure 2 saved.\n');



%% Figure 7 
% Consumption-equivalent welfare gain.
%
% The previous formula, 100*((Va-Vf)./Vf)*scale_y, is wrong in two ways.
% (1) SIGN. Utility is CRRA with sigma = 2 (oil_prod_CES.f90:23), so the value
%     function is NEGATIVE (v_matrix runs -5.30 to -4.13). Dividing a positive
%     numerator Va-Vf by a negative Vf flips the sign, so a genuine welfare
%     GAIN was printed as a loss. It disagreed with the correct measure at
%     21 of 21 output states -- every single one.
% (2) SCALE. The *scale_y multiplier (=10) is not part of any welfare measure.
%
% For CRRA, scaling consumption by (1+lambda) scales V by (1+lambda)^(1-sigma),
% so the consumption equivalent is lambda = (Va/Vf)^(1/(1-sigma)) - 1.
sigma_crra = 2;
welfare_gain_full_to_base = 100*((value_basic_debt./value_full_debt).^(1/(1-sigma_crra))-1);
welfare_gain_full_to_int  = 100*((value_inter_debt./value_full_debt).^(1/(1-sigma_crra))-1);



% Plot welfare at mean debt

figure('Position', [100, 100, 800, 600]);

% Define colors (colorblind-friendly)
color_inter = [0.4660, 0.6740, 0.1880];    % Green
color_basic = [0.3010, 0.7450, 0.9330];    % Blue

% Output values for x-axis
output_values = exp(y_grid);
% Plot
h1 = plot(output_values, welfare_gain_full_to_base, '-', 'LineWidth', 3, 'Color', color_basic);
hold on;
h2 = plot(output_values, welfare_gain_full_to_int, '-', 'LineWidth', 3, 'Color', color_inter);

% Axis labels
xlabel('Output ($y$)', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');
ylabel('Welfare Gain (\% of Consumption)', 'FontSize', 16, 'FontWeight', 'bold', 'Interpreter', 'latex');

% Legend
% Labels were swapped: h1 plots welfare_gain_full_to_BASE and h2 plots
% welfare_gain_full_to_INT, but the legend named them the other way round.
% Present in the submitted script too, so the published Figure 7 is mislabelled.
% 'northwest' sat on top of the upper curve once the comparison economies were
% level-matched and both gains turned positive. Place it on whichever side has
% room, from the data rather than by hand.
leg = legend([h1, h2], {'Full to Basic', 'Full to Intermediate'}, ...
    'Location', 'east', 'FontSize', 14, 'Interpreter', 'latex');
legend boxoff;

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on', 'TickLabelInterpreter', 'latex');
xlim([1.05, 1.4]);


% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save figure
FigureName = 'FIGURE7';
saveas(gcf, [FigureName '.jpg']);



function A = fl__(name)
    fid = fopen(name, 'r');
    if fid < 0, error('fl__:open', 'cannot open %s', name); end
    firstline = fgetl(fid);
    ncol = numel(sscanf(firstline, '%f'));
    frewind(fid);
    c = textscan(fid, '%f', 'CollectOutput', true);
    fclose(fid);
    v = c{1};
    if ncol < 1 || mod(numel(v), ncol) ~= 0
        error('fl__:shape', '%s: %d values not divisible by %d columns', ...
              name, numel(v), ncol);
    end
    A = reshape(v, ncol, []).';
end
