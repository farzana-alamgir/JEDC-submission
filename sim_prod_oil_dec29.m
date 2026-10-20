%% Code to simulate the basic Model with long bond and stochastic volatility

%% ------------------------------------------------------------------------
tic
clc

indicator_load = 10;

if indicator_load > 0.5

clear all

% indicator_unix =1;


   load graphs_data_sim_dss.txt
   load graphs_def_per_dss.txt
   load graphs_param_dss.txt
   load graphs_delta.txt
   load graphs_y_grid_dss.txt
   load graphs_oil_dss.txt
   load param_calib.txt
   load graphs_p_vol_grid_dss.txt
   p_vol_grid = graphs_p_vol_grid_dss;

   
   data_sim = graphs_data_sim_dss;
   def_per = graphs_def_per_dss;
   param = graphs_param_dss;
   delta = graphs_delta;
   y_grid = graphs_y_grid_dss;
   oil=graphs_oil_dss;
   beta=param_calib(1);
   d0=param_calib(2);
   d1=param_calib(3);
   delta=param_calib(4);

   y_num=length(y_grid);

else

clearvars -except data_sim def_per param delta

end %ends indicator_load loop.

rstar=0.01;
sigma=2;


per_num = param(1);  %HOW MANY PERIODS IN EACH SAMPLE
n = param(2);        %HOW MANY SAMPLES


y = zeros(per_num, n);
b = zeros(per_num, n);
q = zeros(per_num, n);
qdef = zeros(per_num, n); %we don't need this; qdef=0 all the time.
c = zeros(per_num, n);
oil=zeros(per_num, n);
output=zeros(per_num, n);


tby = zeros(per_num, n);
oil_y = zeros(per_num, n);
e = zeros(per_num, n);
d = zeros(per_num, n);
p = zeros(per_num, n);
p_vol = zeros(per_num, n);
b_next = zeros(per_num-1, n);
q_def_free = zeros(per_num, n);
price = zeros(per_num, n);
vol = zeros(per_num, n);

for i=1:n
   y(:,i) = data_sim((i-1)*per_num+1:i*per_num,1); 
   c(:,i) = data_sim((i-1)*per_num+1:i*per_num,2); 

   b(:,i) = data_sim((i-1)*per_num+1:i*per_num,3); 
   q(:,i) = data_sim((i-1)*per_num+1:i*per_num,4);
   qdef(:,i) = data_sim((i-1)*per_num+1:i*per_num,5);

   oil(:,i) = data_sim((i-1)*per_num+1:i*per_num,6);
  
   e(:,i) = data_sim((i-1)*per_num+1:i*per_num,7);
   d(:,i) = data_sim((i-1)*per_num+1:i*per_num,8)-1;
   q_def_free(:,i) = data_sim((i-1)*per_num+1:i*per_num,9); 
   i_y_current(:,i) = data_sim((i-1)*per_num+1:i*per_num,10);
   tby(:,i) = data_sim((i-1)*per_num+1:i*per_num,12);
   p_vol(:,i) = data_sim((i-1)*per_num+1:i*per_num,13);
   p(:,i) = data_sim((i-1)*per_num+1:i*per_num,14);
   
   oil_y(:,i) = data_sim((i-1)*per_num+1:i*per_num,15);
   output(:,i) = data_sim((i-1)*per_num+1:i*per_num,16);
   i_p_current(:,i) = data_sim((i-1)*per_num+1:i*per_num,17);
   i_vol_current(:,i) = data_sim((i-1)*per_num+1:i*per_num,18);
   price(:,i) = data_sim((i-1)*per_num+1:i*per_num,19);
   vol(:,i) = data_sim((i-1)*per_num+1:i*per_num,20);


end

excl_periods = find(data_sim(:,7)>1); %not being used.
b_next = b(2:per_num,:);
for j=1:per_num
    for i=1:n
   coupon(j,i) = (rstar+delta)/(1+rstar);
    end
end

%CREATE OUTPUT SERIES
num = max(1000,n); %HOW MANY PERIODS IN EACH SUBSAMPLE

%TRIM THE FIRST 9500 OBSERVATIONS:
last_y = y(per_num - num+1:per_num,:); 
last_c = c(per_num - num+1:per_num,:); 
last_output = output(per_num - num+1:per_num,:); 

last_b = b(per_num - num+1:per_num,:);
last_q = q(per_num - num+1:per_num,:);
last_oil = oil(per_num - num+1:per_num,:);  %TRIM THE FIRST 9500 OBSERVATIONS
last_tby= tby(per_num - num+1:per_num,:);  %TRIM THE FIRST 9500 OBSERVATIONS
last_e = e(per_num - num+1:per_num,:);
last_d = d(per_num - num+1:per_num,:);
last_p = p(per_num - num+1:per_num,:);
last_p_vol = p_vol(per_num - num+1:per_num,:);
last_b_to_y= 0.25*last_b./(last_output-last_oil);
last_oil_y= oil_y(per_num - num+1:per_num,:); 

last_coupon = coupon(per_num - num+1:per_num,:);
last_q_def_free = q_def_free(per_num - num+1:per_num,:);
last_i_y=i_y_current(per_num - num+1:per_num,:);
last_i_p = i_p_current(per_num - num+1:per_num,:);
last_i_vol = i_vol_current(per_num - num+1:per_num,:);
last_vol = vol(per_num - num+1:per_num,:);
last_price = price(per_num - num+1:per_num,:);

last_yield_long = (last_coupon./last_q -delta);
last_yield_long_rf = last_coupon./last_q_def_free-delta;

for j=1:num
    for i=1:n
         last_duration(j,i) = (((1-delta).*last_q(j,i) +last_coupon(j,i))./(last_q(j,i)))./...
             (((1-delta).*last_q(j,i) +last_coupon(j,i))./(last_q(j,i))-1+delta);
    end
end

last_duration_1 = (1+last_yield_long)./(last_yield_long+delta);


%last_spread_annual = (last_yield_long-last_yield_long_rf)*4;
last_spread_annual_rw = ((1+last_yield_long)./ (1+rstar)).^4 - 1;
last_spread_quarterly = ( last_yield_long-last_yield_long_rf) ;
last_spread_quarterly_rw = ( (1+last_yield_long)./ (1+rstar) ).^1 - 1;

% Annualize by compounding
annual_yield_risky = (1 + last_yield_long).^4 - 1;
annual_yield_riskfree = (1 + last_yield_long_rf).^4 - 1;

% Annual spread is the difference
last_spread_annual = annual_yield_risky - annual_yield_riskfree;

% Detrending

 hp_lambda = 1600;
%lambda = 6.25;

y_trend = hpfilter(log(last_y),hp_lambda);            %FILTER log(output)
c_trend = hpfilter(log(last_c),hp_lambda);            
oil_trend = hpfilter(log(last_oil), hp_lambda);           %FILTER log(consumption)
output_trend = hpfilter(log(last_output), hp_lambda);
 tby_trend = hpfilter(last_tby, hp_lambda);           %FILTER log(tb)
spread_annual_trend = hpfilter(last_spread_annual, hp_lambda);  %FILTER annual spread
spread_quarterly_trend = hpfilter(last_spread_quarterly, hp_lambda);  %FILTER annual spread
spread_annual_rw_trend = hpfilter(last_spread_annual_rw, hp_lambda);  %FILTER annual spread
spread_quarterly_rw_trend = hpfilter(last_spread_quarterly_rw, hp_lambda);  %FILTER annual spread
oil_y_trend = hpfilter(last_oil_y, hp_lambda);
b_to_y_trend = hpfilter(last_b_to_y, hp_lambda);

%COMPUTE DEVIATIONS FROM TREND 
y_dev = log(last_y)- y_trend;
c_dev = log(last_c)- c_trend;
output_dev = log(last_output) - output_trend;
oil_dev = log(last_oil) - oil_trend;

 tby_dev = last_tby - tby_trend;
oil_y_dev = last_oil_y - oil_y_trend;
spread_annual_dev = last_spread_annual - spread_annual_trend;
spread_annual_rw_dev = last_spread_annual_rw - spread_annual_rw_trend;
spread_quarterly_dev = last_spread_quarterly - spread_quarterly_trend;
spread_quarterly_rw_dev = last_spread_quarterly_rw - spread_quarterly_rw_trend;

b_to_y_dev=last_b_to_y - b_to_y_trend;

%% Compute moments (21 years before and 1 after a default)


per_immediately_after = -1;
per_before=100;
per_after=-1;
sample_size = per_before+per_after+1;

max_num_def = max(sum(last_d));

% n is the number of samples (= 500, unless modified somewhere)

num_observations_vector = zeros(n,1); %NUMBER OF OBSERVATIONS PER SAMPLE (AN OBSERVATION
                               % IS A DEFAULT EPISODE WITH SUFFICIENT
                               % PERIODS BEFORE THE DEFAULT AND NO
                               % EXCLUSION IN BETWEEN

def_per_matrix = zeros(max_num_def,n); %MATRIX OF DEFAULT PERIODS SATISFYING
                                       %THE ABOVE RESTRICTION. THIS MATRIX
                                       %WILL HAVE THE 'LOCATION' OF THE
                                       %DEFAULTS EVENTS.


index_acum = 0; %INDEX OF ACUMULATED NUMBER OF DEFAULT EPISODES

for i = 1:n
    def_num = sum(d(:,i)); %# of defaults in sample i 
    def_num_last = sum(last_d(:,i)); %# of defaults in sample i, after trimming
    if def_num_last>0
       
       %here... i need to define def_periods_last.. because we only use those!
       
       def_periods = def_per(index_acum+1:index_acum+def_num);  %VECTOR OF DEFAULT PERIODS of each sample 'i' of the n samples!
       deff=find(def_periods>(per_num - num)); % this is to take into account only the last num periods.
       def_periods_last = def_periods(deff)-(per_num-num);


       % New `interperiods', this time counting forward
       interperiods = zeros(def_num_last,1);
        interperiods(1) = def_periods_last(1);             %SEPARATION BETWEEN DEFAULT PERIODS
        interperiods(2:def_num_last)= diff(def_periods_last);   %SEPARATION BETWEEN DEFAULT PERIODS
       
       
       

       indices = find(interperiods>(sample_size + 1) &...
            def_periods_last(def_num_last)<=(num-per_after) &...
            last_e(min(max(def_periods_last - per_before -1,1),num),i)<2);
       
       num_observations_vector(i) = length(indices);        %STORE THE NUMBER OF SUCH SAMPLES
       if length(indices)>0
          
           %ONLY STORE RESULTS IF THERE ARE A POSITIVE NUMBER OF
           %OBSERVATIONS.
           def_per_matrix(1:length(indices),i) = def_periods_last(indices);  
                     
       end
    end
    
    index_acum = index_acum + def_num;

end

num_observations = sum(num_observations_vector);


std_y_vector = zeros(num_observations,1);
std_output_vector = zeros(num_observations,1);
std_c_vector = zeros(num_observations,1);
std_oil_y_vector = zeros(num_observations,1);
std_p_vector = zeros(num_observations,1);
std_oil_vector = zeros(num_observations,1);

std_spread_vector = zeros(num_observations,1);
std_spread_rw_vector = zeros(num_observations,1);
std_b_to_y_vector = zeros(num_observations,1);

corr_y_c_vector = zeros(num_observations,1);
corr_y_spread_vector = zeros(num_observations,1);
corr_y_tby_vector = zeros(num_observations,1);
corr_spread_tby_vector = zeros(num_observations,1);
corr_spread_c_vector = zeros(num_observations,1);



mean_b_vector = zeros(num_observations,1);
mean_duration_vector = zeros(num_observations,1);
mean_b_to_y_vector = zeros(num_observations,1);
mean_output_vector = zeros(num_observations,1);

mean_spread_annual_vector = zeros(num_observations,1);
mean_spread_annual_rw_vector = zeros(num_observations,1);
mean_spread_quarterly_vector = zeros(num_observations,1);
mean_spread_quarterly_rw_vector = zeros(num_observations,1);
median_spread_vector = zeros(num_observations,1);

index_observation = 1;

for i=1:n
       for j=1:num_observations_vector(i)
           
           duration_vector = last_duration_1(def_per_matrix(j,i) - per_before:def_per_matrix(j,i)+ per_after,i);

           spread_annual_vector = last_spread_annual(def_per_matrix(j,i) - per_before:def_per_matrix(j,i)+ per_after,i);
           spread_annual_rw_vector = last_spread_annual_rw(def_per_matrix(j,i) - per_before:def_per_matrix(j,i)+ per_after,i);
           spread_quarterly_vector = last_spread_quarterly(def_per_matrix(j,i) - per_before:def_per_matrix(j,i)+ per_after,i);

           spread_quarterly_rw_vector = last_spread_quarterly_rw(def_per_matrix(j,i) - per_before:def_per_matrix(j,i)+ per_after,i);

           
           
           yield_vector = last_yield_long_rf(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);

          
            y_vector = last_y(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);
            output_vector = last_output(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);

            c_vector = last_c(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);
            oil_y_vector = last_oil_y(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);

            oil_vector = last_oil(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);

            p_vector = last_p(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);
            price_vector = last_price(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);
            vol_vector = last_vol(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);

            tby_vector = last_tby(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);

            b_vector = last_b(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);

            b_to_y_vector = last_b_to_y(def_per_matrix(j,i)- per_before:def_per_matrix(j,i) + per_after,i);

            i_y_vector = last_i_y(def_per_matrix(j,i) - per_before:def_per_matrix(j,i) +per_after,i);
            i_p_vector = last_i_p(def_per_matrix(j,i) - per_before:def_per_matrix(j,i) +per_after,i);
            i_vol_vector = last_i_vol(def_per_matrix(j,i) - per_before:def_per_matrix(j,i) +per_after,i);
            
            %hp_lambda=100;
            hp_y = hpfilter(log(y_vector),hp_lambda);    %FILTER log 
            hp_output = hpfilter(log(output_vector),hp_lambda); 
            hp_c = hpfilter(log(c_vector),hp_lambda);    %FILTER log 

             hp_oil = hpfilter(log(oil_vector),hp_lambda);    %FILTER log 
            hp_tby = hpfilter(tby_vector,hp_lambda);    %FILTER Level 
            hp_oil_y = hpfilter(log(oil_y_vector),hp_lambda); 
            hp_b_to_y = hpfilter(b_to_y_vector,hp_lambda);    %FILTER level

            hp_spread_annual = hpfilter(spread_annual_vector,hp_lambda);    %FILTER level 
            hp_spread_annual_rw = hpfilter(spread_annual_rw_vector,hp_lambda);
            hp_spread_quarterly = hpfilter(spread_quarterly_vector,hp_lambda);
            hp_spread_quarterly_rw = hpfilter(spread_quarterly_rw_vector,hp_lambda);
            dev_y = log(y_vector) - hp_y;
            dev_output = log(output_vector) - hp_output;
            dev_c = log(c_vector) - hp_c;
             dev_oil_y = log(oil_y_vector) - hp_oil_y;
            dev_oil = log(oil_vector) - hp_oil;
             dev_tby = tby_vector - hp_tby;

            dev_b_to_y = b_to_y_vector - hp_b_to_y; %level

            dev_spread_annual = spread_annual_vector - hp_spread_annual;
            dev_spread_annual_rw = spread_annual_rw_vector - hp_spread_annual;
            dev_spread_quarterly = spread_quarterly_vector - hp_spread_annual;
            dev_spread_quarterly_rw = spread_quarterly_rw_vector - hp_spread_annual;

     
            std_spread_vector(index_observation) = std(spread_annual_vector,'omitnan');
            std_spread_rw_vector(index_observation) = std(spread_annual_rw_vector,'omitnan');
            std_c_vector(index_observation) = std(dev_c,'omitnan');
            std_output_vector(index_observation) = std(dev_output,'omitnan');
            std_p_vector(index_observation) = std(p_vector,'omitnan');
            std_oil_vector(index_observation) = std(dev_oil,'omitnan');
            std_oil_y_vector(index_observation) = std(dev_oil_y,'omitnan');
            std_y_vector(index_observation) = std(dev_y,'omitnan');
             std_tby_vector(index_observation) = std(dev_tby,'omitnan');
            std_b_to_y_vector(index_observation) = std(dev_b_to_y,'omitnan');
            

            matrix = corrcoef(dev_output, dev_c);
            corr_y_c_vector(index_observation) = matrix(1,2);

             matrix = corrcoef(dev_output, dev_tby);
             corr_y_tby_vector(index_observation) = matrix(1,2);

            matrix = corrcoef(dev_output, dev_spread_annual);
            corr_y_spread_vector(index_observation) = matrix(1,2);

             matrix = corrcoef(dev_spread_annual, dev_tby);
             corr_spread_tby_vector(index_observation) = matrix(1,2);

            matrix = corrcoef(dev_spread_annual, dev_oil_y);
            corr_spread_oil_y_vector(index_observation) = matrix(1,2);

            
            mean_b_vector(index_observation) = mean(b_vector,'omitnan');
            mean_output_vector(index_observation) = mean(output_vector,'omitnan');
            mean_p_vector(index_observation) = mean(p_vector,'omitnan');
            mean_c_vector(index_observation) = mean(c_vector,'omitnan');
            mean_oil_vector(index_observation) = mean(oil_vector,'omitnan');
            mean_oil_y_vector(index_observation) = mean(oil_y_vector,'omitnan');
            mean_duration_vector(index_observation) = mean(duration_vector,'omitnan');
            mean_b_to_y_vector(index_observation) = mean(b_to_y_vector,'omitnan');  

            median_b_to_y_vector(index_observation) = median(b_to_y_vector,'omitnan'); 

            mean_spread_annual_vector(index_observation) = mean(spread_annual_vector,'omitnan');
            mean_spread_annual_rw_vector(index_observation) = mean(spread_annual_rw_vector,'omitnan');
            mean_spread_quarterly_vector(index_observation) = mean(spread_quarterly_vector,'omitnan');
            mean_spread_quarterly_rw_vector(index_observation) = mean(spread_quarterly_rw_vector,'omitnan');
            median_spread_vector(index_observation) = median(spread_annual_vector,'omitnan');
                        
           output_ts(index_observation,:)=output_vector; % this is quarterly GDP
        hp_output_dev_ts(index_observation,:)=dev_output;
        c_ts(index_observation,:)=c_vector;
        b_ts(index_observation,:)=b_vector;
        b_to_y_ts(index_observation,:)=b_to_y_vector; %already divided by annual GDP
        spread_ts(index_observation,:) =spread_annual_vector;
        spread_ts_q(index_observation,:) =spread_quarterly_vector;
        spread_ts_rw_q(index_observation,:) =spread_quarterly_rw_vector;
        yield_ts(index_observation,:) =yield_vector;
        tb_ts(index_observation,:) =tby_vector;
        spreadrw_ts(index_observation,:) =spread_annual_rw_vector;
        %spreadrt_ts(index_observation,:) =spread_annual_rt_vector;
        
        p_ts(index_observation,:)=(p_vector);
        %r_ts_quarterly(index_observation,:)=r_vector;
        p_index_ts(index_observation,:)=i_p_vector;
        p_vol_index_ts(index_observation,:)=i_vol_vector;
        %r_vol_ts(index_observation,:)=(1+exp(r_vol_grid(i_vol_vector))).^4-1;
        p_vol_ts(index_observation,:)=exp(p_vol_grid(i_vol_vector));
        %sdf_ts(index_observation,:)=sdf_vector;     
        
            
            
            index_observation = index_observation+1;
    end
end

quarter_a(:,1)=1:size(output_ts,2);

n_samples = size(output_ts,1);

quarter_b(:,1)=ones(n_samples,1);

quarter=kron(quarter_b,quarter_a);

series_id1=kron(1:n_samples,ones(size(output_ts,2),1));
series_id = series_id1(:);

output_ts_keep = output_ts(1:n_samples,:)';
output_ts_keep = output_ts_keep(:);

hp_output_dev_ts_keep = hp_output_dev_ts(1:n_samples,:)';
hp_output_dev_ts_keep = hp_output_dev_ts_keep(:);

spread_ts_keep = spread_ts(1:n_samples,:)';
spread_ts_keep = spread_ts_keep(:);

spread_ts_keep_q = spread_ts_q(1:n_samples,:)';
spread_ts_keep_q = spread_ts_keep_q(:);

spread_ts_rw_keep_q = spread_ts_rw_q(1:n_samples,:)';
spread_ts_rw_keep_q = spread_ts_rw_keep_q(:);

yield_ts_keep = yield_ts(1:n_samples,:)';
yield_ts_keep = yield_ts_keep(:);

debt_ts_keep = b_ts(1:n_samples,:)';
debt_ts_keep = debt_ts_keep(:);

debt_ratio_ts_keep = b_to_y_ts(1:n_samples,:)';
debt_ratio_ts_keep = debt_ratio_ts_keep(:);

tb_ts_keep = tb_ts(1:n_samples,:)';
tb_ts_keep = tb_ts_keep(:);

p_ts_keep = p_ts(1:n_samples,:)';
p_ts_keep = p_ts_keep(:);

% p_ts_quarterly_keep = r_ts_quarterly(1:n_samples,:)';
% r_ts_quarterly_keep = r_ts_quarterly_keep(:);

% r_vol_ts_quarterly_keep = r_vol_ts_quarterly(1:n_samples,:)';
% r_vol_ts_quarterly_keep = r_vol_ts_quarterly_keep (:);

p_vol_ts_keep = p_vol_ts(1:n_samples,:)';
p_vol_ts_keep = p_vol_ts_keep(:);

 p_vol_index_ts_keep = p_vol_index_ts(1:n_samples,:)';
 p_vol_index_ts_keep = p_vol_index_ts_keep(:);
% 
 p_index_ts_keep = p_index_ts(1:n_samples,:)';
 p_index_ts_keep= p_index_ts_keep(:);

% sdf_ts_keep = sdf_ts(1:n_samples,:)';
% sdf_ts_keep = sdf_ts_keep(:);

%The line below saves the data in a .mat file which is easy to open in R:
save simulation_data series_id quarter output_ts_keep spread_ts_keep debt_ratio_ts_keep debt_ts_keep ...
    tb_ts_keep p_ts_keep p_vol_ts_keep hp_output_dev_ts_keep p_vol_index_ts_keep p_index_ts_keep spread_ts_keep_q spread_ts_rw_keep_q



%num_simulations = min(length(std_y_vector), 500);

%Get rid of the most extreme .05% on each side of the distribution of
%spreads.

spread_995 = quantile(mean_spread_annual_vector,.995);
spread_005 = quantile(mean_spread_annual_vector,.005);

no_outlier_position = find(mean_spread_annual_vector <= spread_995 & mean_spread_annual_vector >= spread_005);

 num_simulations = length(std_y_vector(no_outlier_position));


fprintf(' \n')
fprintf(['Compute statistics of ',num2str(num_simulations),' samples of ',num2str(sample_size),...
    ' observations with ',num2str(per_immediately_after),' periods after a default and without outliers (exclusion). \n'])
fprintf('std of output      = %8.4f \n',mean(std_output_vector,'omitnan'))
fprintf('std of c        = %8.4f \n',mean(std_c_vector,'omitnan'))
fprintf('std of price        = %8.4f \n',mean(std_p_vector,'omitnan'))
fprintf('std of oil_y        = %8.4f \n',mean(std_oil_y_vector,'omitnan'))
fprintf('std c / std y   = %2.4f \n',mean(std_c_vector)/mean(std_output_vector))
fprintf('std of oil    = %8.4f \n',mean(std_oil_vector,'omitnan'))
fprintf('std of spread         = %8.4f \n',100*mean(std_spread_vector,'omitnan'))
fprintf('std of spread_rw         = %8.4f \n',100*mean(std_spread_rw_vector,'omitnan'))
fprintf('std of debt/y      = %8.4f \n',mean(std_b_to_y_vector,'omitnan'))
fprintf('corr(c,y)          = %8.4f \n',mean(corr_y_c_vector,'omitnan'))
 fprintf('corr(y,tby)        = %8.4f \n',mean(corr_y_tby_vector,'omitnan'))
fprintf('corr(y,spread)   = %8.4f \n',mean(corr_y_spread_vector,'omitnan'))
fprintf('corr(tb/y,spread)       = %8.4f \n',mean(corr_spread_tby_vector,'omitnan'))
 fprintf('corr(spread,oil_y)          = %8.4f \n',mean(corr_spread_oil_y_vector,'omitnan'))
 
fprintf('Mean debt/y   = %8.4f \n',100*mean(mean_b_to_y_vector,'omitnan'))
fprintf('Mean Annual spread      = %8.4f \n',100*mean(mean_spread_annual_vector,'omitnan'))
fprintf('Mean Annual spread_rw      = %8.4f \n',100*mean(mean_spread_annual_rw_vector,'omitnan'))
fprintf('Mean Quarterly spread      = %8.4f \n',100*mean(mean_spread_quarterly_vector,'omitnan'))
fprintf('Mean Quarterly spread_rw      = %8.4f \n',100*mean(mean_spread_quarterly_rw_vector,'omitnan'))
fprintf('Max Annual R_s     = %8.4f \n',100*max(mean_spread_annual_vector, [], 'omitnan'))
fprintf('Mean debt          = %8.4f \n',mean(mean_b_vector,'omitnan'))
fprintf('Mean c          = %8.4f \n',mean(mean_c_vector,'omitnan'))
fprintf('Mean output          = %8.4f \n',mean(mean_output_vector,'omitnan'))
fprintf('Mean p          = %8.4f \n',mean(mean_p_vector,'omitnan'))
fprintf('Mean oil      = %8.4f \n',mean(mean_oil_vector,'omitnan'))
fprintf('Mean oil_y      = %8.4f \n',mean(mean_oil_y_vector,'omitnan'))
 fprintf('Mean default rate  = %8.5f \n', mean(sum(last_d)/size(last_d,2), 'omitnan'))
 fprintf('Duration           = %f5 \n',mean(mean(last_duration),'omitnan')/1)
fprintf('Duration-1           = %f5 \n',mean(mean_duration_vector,'omitnan')/1)
fprintf('Median spread      = %8.4f \n',100*mean(median_spread_vector))
fprintf('Mean default rate (all)  = %f5 \n', 100*mean(sum(d)/per_num),'omitnan' )


% %% Create array to write in xls file
% 
% 
%  A = [
%  100*nanmean(mean_b_to_y_vector);
% 100*nanmean(mean_spread_annual_vector);
% 100*nanmean(mean_spread_annual_rw_vector);
% 100*nanmean(mean_spread_quarterly_vector);
% 100*nanmean(mean_spread_quarterly_rw_vector);
% 100*nanmean(std_spread_vector);
% nanmean(mean_p_vector);
% nanmean(mean_oil_vector);
% nanmean(mean_oil_y_vector);
% 100*nanmean(sum(d)/per_num);
% nanmean(mean_c_vector)
% ];
%  csvwrite('moments_full.txt',A)
