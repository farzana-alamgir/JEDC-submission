clear all

%%%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
%XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

load graphs_y_grid_dss.txt  
load graphs_b_grid_dss.txt
%load graphs_p_grid_dss.txt
load graphs_p_vol_grid_dss.txt
load graphs_p_grid_dss.txt
load graphs_p_grid_2_dss.txt

load graphs_p_vol_grid_dss.txt;
load 'graphs_trans_matrix_p.txt';
load graphs_trans_matrix_p_vol.txt

load graphs_v_dss.txt
load graphs_q_dss.txt
load graphs_default_dss.txt
load graphs_b_next_dss.txt
load graphs_dev_dss.txt
load graphs_q_paid_dss.txt
load graphs_trans_matrix_p.txt
load graphs_trans_matrix_p_2.txt
load graphs_trans_matrix_joint.txt

load graphs_cdf_matrix_p.txt
load graphs_trans_matrix_p_vol.txt
load graphs_trans_matrix_y.txt
load graphs_cons_dss.txt
load graphs_oil_dss.txt
load graphs_output_dss.txt
load graphs_delta.txt
load graphs_q_def_free.txt
load graphs_q_def_free_dss.txt
load graphs_pdf_y.txt
load graphs_pdf_p_vol.txt
load graphs_pdf_p.txt

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

% Price nodes used throughout for the "low price" / "high price" contrast.
% These were hardcoded as 2 and 6, which bracket the grid only when p_num = 7:
% at p_num = 277 nodes 2 and 6 sit at 0.4% and 1.8% of the grid -- both deep in
% the left tail, so the contrast collapses and every low-vs-high comparison
% becomes meaningless. Defined by RELATIVE position instead, reducing to exactly
% 2 and 6 when p_num = 7.
i_p_low  = max(1,     round(1 + (1/6)*(p_num-1)));   % 16.7% of the grid
i_p_high = min(p_num, round(1 + (5/6)*(p_num-1)));   % 83.3% of the grid
fprintf('price-node contrast: low = %d, high = %d (of %d)\n', i_p_low, i_p_high, p_num);

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
%fprintf('DEBUG: After load, spread_matrix size = ['); fprintf('%d ', size(spread_matrix)); fprintf(']\n');
% scale_y=10;
% dy =0.25*b_grid/mean(scale_y*exp(y_grid));
% y=scale_y*exp(y_grid);
scale_y=10;
dy1 =0.25*b_grid/mean(scale_y*exp(y_grid));
y1=scale_y*exp(y_grid);
spread1=spread_matrix;
%fprintf('DEBUG: After assignment, spread1 size = ['); fprintf('%d ', size(spread1)); fprintf(']\n');
mean_output1=mean(output_matrix(:));   % dimension-agnostic; identical to the nested means
debt_output1=0.25*b_grid./mean_output1;
consumption1=cons_matrix;
value1=v_matrix;
output1=output_matrix;
dprice_matrix_3=exp(p_grid_3_matrix(i_p_high,:))-exp(p_grid_3_matrix(i_p_low,:));
dvol_matrix=exp(p_vol_grid(4))-exp(p_vol_grid(3));
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
output_y_values = squeeze(output_matrix(i_b3, :, 2, 3));

% Compute slopes for vol states 2, 3, 4
vol_states = [2, 3, 4];
slopes_all = zeros(y_num, 3);

for vol_idx = 1:3
    i_vol = vol_states(vol_idx);
    
    % Spreads at low price (p=2) and high price (p=6)
    spread_p2 = squeeze(spread_matrix(i_b3, :, i_p_low, i_vol));
    spread_p6 = squeeze(spread_matrix(i_b3, :, i_p_high, i_vol));
    
    % Simple slope: ∆Spread / ∆Price
    slopes_all(:, vol_idx) = (spread_p6 - spread_p2) ./ dprice;
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
xlim([5.5, 8]);
ylim([0, 0.09]);

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
    
    spread_p2 = squeeze(spread_matrix(i_b, :, i_p_low, i_vol));
    spread_p6 = squeeze(spread_matrix(i_b, :, i_p_high, i_vol));
    
    slopes_debt(:, d_idx) = (spread_p6 - spread_p2) ./ dprice;
    output_vals{d_idx} = squeeze(output_matrix(i_b, :, 4, i_vol));
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
xlim([5.5, 8]);
ylim([-0.02, 0.35]);

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
plot(price_values, spread_values, '-', 'LineWidth', 3, 'Color', color_line);

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

for i_p = 1:7
    for i_vol_tomorrow = 1:p_vol_num
        expectation = transition_matrix_joint(:, :, i_p, i_vol_tomorrow) .* exp(p_grid_matrices{i_vol_tomorrow});
        exp_prices(i_p, i_vol_tomorrow) = sum(expectation, 'all');
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
volatility = exp(p_vol_grid);

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
axis([volatility(1), volatility(5), 1, 2]);

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
h1 = plot(debt_output1, 100*spread1(:,11,4,3)', '-', 'LineWidth', 3, 'Color', color_full);
hold on;
h2 = plot(debt_output2, 100*spread2(:,11,4)', '-', 'LineWidth', 3, 'Color', color_inter);
h3 = plot(debt_output3, 100*spread3(:,11)', '-', 'LineWidth', 3, 'Color', color_basic);

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
welfare_gain_full_to_base = 100*((value_basic_debt-value_full_debt)./value_full_debt)*scale_y;
welfare_gain_full_to_int = 100*((value_inter_debt-value_full_debt)./value_full_debt)*scale_y;



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
leg = legend([h1, h2], {'Full to Intermediate', 'Full to Basic'}, ...
    'Location', 'northwest', 'FontSize', 14, 'Interpreter', 'latex');
legend boxoff;

% Axis settings
set(gca, 'FontSize', 14, 'LineWidth', 1.2, 'Box', 'on', 'TickLabelInterpreter', 'latex');
xlim([1.05, 1.4]);


% Tight layout
set(gca, 'LooseInset', get(gca, 'TightInset'));

% Save figure
FigureName = 'FIGURE7';
saveas(gcf, [FigureName '.jpg']);

