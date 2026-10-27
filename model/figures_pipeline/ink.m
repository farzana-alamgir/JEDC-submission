R='/Users/farzanaalamgir/code/JEDC_submission/results/figures_recalibrated/same_prices';
f=dir([R '/FIGURE*.jpg']);
fprintf('%-12s %10s %10s   verdict\n','figure','coloured%','vs ref%');
Rref='/Users/farzanaalamgir/code/JEDC_submission/results/figures_submitted_from_paper';
for i=1:numel(f)
  I=imread([R '/' f(i).name]); D=double(I);
  sat = max(D,[],3)-min(D,[],3);          % coloured (non-grey) pixels = data ink
  c = 100*mean(sat(:)>40);
  nm=f(i).name;
  if isfile([Rref '/' nm])
    J=double(imread([Rref '/' nm])); s2=max(J,[],3)-min(J,[],3); c2=100*mean(s2(:)>40);
  else, c2=NaN; end
  v=''; if c<0.05, v='BLANK'; elseif ~isnan(c2) && c<0.3*c2, v='sparse'; end
  fprintf('%-12s %10.3f %10.3f   %s\n', nm, c, c2, v);
end
