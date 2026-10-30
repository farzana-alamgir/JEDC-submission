ALL_FIGURES_common_grid
fprintf('\n==== CLAIMS CHECK ====\n');

% ---- FIGURE3: slope of spread wrt price, by volatility state (cols: vol 2,3,4)
fprintf('FIGURE3 slopes_all %dx%d, NaN in %d of %d cells\n', ...
    size(slopes_all,1), size(slopes_all,2), sum(isnan(slopes_all(:))), numel(slopes_all));
fprintf('FIGURE3 median slope (low,mid,high): %.4f %.4f %.4f\n', ...
    median(slopes_all(:,1),'omitnan'), median(slopes_all(:,2),'omitnan'), median(slopes_all(:,3),'omitnan'));
r = slopes_all(:,3) ./ slopes_all(:,1);
fprintf('FIGURE3 ratio high/low: median %.4f  mean %.4f  min %.4f  max %.4f  (n=%d)\n', ...
    median(r,'omitnan'), mean(r,'omitnan'), min(r), max(r), sum(~isnan(r)));
ok = ~any(isnan(slopes_all),2);
mono = sum(slopes_all(ok,3) >= slopes_all(ok,2) & slopes_all(ok,2) >= slopes_all(ok,1));
fprintf('FIGURE3 high>=mid>=low at %d of %d non-NaN output states\n', mono, sum(ok));

% ---- FIGURE2: ordering Full > Intermediate > Basic
f = s_full_f2(:); i2 = s_int_f2(:); b = s_bas_f2(:);
v = ~isnan(f) & ~isnan(i2) & ~isnan(b);
fprintf('FIGURE2 %d debt points, %d with all three defined\n', numel(f), sum(v));
fprintf('FIGURE2 mean level over those: full %.4f  inter %.4f  basic %.4f\n', ...
    mean(f(v)), mean(i2(v)), mean(b(v)));
fprintf('FIGURE2 full-inter %.6f pp;  inter-basic %.6f pp\n', ...
    mean(f(v))-mean(i2(v)), mean(i2(v))-mean(b(v)));
fprintf('FIGURE2 full>=inter at %d/%d;  inter>=basic at %d/%d;  both at %d/%d\n', ...
    sum(f(v)>=i2(v)), sum(v), sum(i2(v)>=b(v)), sum(v), sum(f(v)>=i2(v) & i2(v)>=b(v)), sum(v));

% ---- FIGURE4d: expected oil price flat across volatility
fprintf('FIGURE4d volatility axis: '); fprintf('%.4f ', volatility); fprintf('\n');
nms = {'exp_5','exp_6','exp_7'};
for k = 1:3
    vv = eval(nms{k}); vv = vv(:);
    fprintf('FIGURE4d %s: min %.6f max %.6f  range %.6f  (%.4f%% of mean)\n', ...
        nms{k}, min(vv), max(vv), max(vv)-min(vv), 100*(max(vv)-min(vv))/mean(vv));
end
