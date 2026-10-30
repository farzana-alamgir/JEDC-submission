ALL_FIGURES_common_grid
fprintf('\n==== WELFARE consumption equivalent, percent ====\n');
fprintf('states: %d\n', numel(welfare_gain_full_to_base));
fprintf('output  full->basic  full->inter\n');
for k = 1:numel(welfare_gain_full_to_base)
    fprintf('%7.4f %12.4f %12.4f\n', output_values(k), welfare_gain_full_to_base(k), welfare_gain_full_to_int(k));
end
fprintf('full->basic : mean %.4f  min %.4f  max %.4f\n', mean(welfare_gain_full_to_base), min(welfare_gain_full_to_base), max(welfare_gain_full_to_base));
fprintf('full->inter : mean %.4f  min %.4f  max %.4f\n', mean(welfare_gain_full_to_int),  min(welfare_gain_full_to_int),  max(welfare_gain_full_to_int));
