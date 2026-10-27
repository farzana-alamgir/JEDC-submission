f={'oil_bm.mat','oil_intermediate.mat','oil_basic.mat','oil_basic_matched.mat'};
lbl={'full','intermediate','basic (E[p]=1.3735)','basic matched (E[p]=1.3339)'};
V={};
for k=1:numel(f)
  S=load(f{k},'v_matrix','pdf_p','pdf_p_vol','p_num','p_vol_num','y_num','output_matrix');
  fk=squeeze(max(max(S.output_matrix,[],1),[],2))<1d3;
  if isscalar(fk), fk=true; end
  Vk=zeros(S.y_num,1);
  for iy=1:S.y_num
    a=0; w=0;
    for v=1:S.p_vol_num
      b=0; ww=0;
      for ip=1:S.p_num
        if ~fk(ip,v), continue; end
        t=S.pdf_p((v-1)*S.p_num+ip);
        b=b+t*S.v_matrix(44,iy,ip,v); ww=ww+t;
      end
      a=a+b*S.pdf_p_vol(v); w=w+ww*S.pdf_p_vol(v);
    end
    Vk(iy)=a/w;
  end
  V{k}=Vk;
end
Vf=V{1}; sg=2; cev=@(Va) 100*((Va./Vf).^(1/(1-sg))-1);
fprintf('\nconsumption-equivalent welfare, full model as the baseline\n');
for k=2:numel(f)
  fprintf('  full -> %-28s : %+0.4f%%   (mean V %.5f)\n', lbl{k}, mean(cev(V{k})), mean(V{k}));
end
fprintf('  full model mean V %.5f\n', mean(Vf));
