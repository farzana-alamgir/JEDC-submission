f={'oil_bm.mat','oil_intermediate.mat','oil_basic.mat'}; V={};
for k=1:3
  S=load(f{k},'v_matrix','pdf_p','pdf_p_vol','p_num','p_vol_num','y_num');
  pm=zeros(S.p_vol_num,S.p_num);
  for v=1:S.p_vol_num, for ip=1:S.p_num, pm(v,ip)=S.pdf_p((v-1)*S.p_num+ip); end, end
  Vk=zeros(S.y_num,1);
  for iy=1:S.y_num
    a=0;
    for v=1:S.p_vol_num
      b=0; for ip=1:S.p_num, b=b+pm(v,ip)*S.v_matrix(44,iy,ip,v); end
      a=a+b*S.pdf_p_vol(v);
    end
    Vk(iy)=a;
  end
  V{k}=Vk;
end
Vf=V{1}; sg=2; cev=@(Va) 100*((Va./Vf).^(1/(1-sg))-1);
fprintf('[4] WELFARE, consumption equivalent at mean debt  (paper: +0.2%% to +1.1%%)\n');
fprintf('    full -> intermediate (remove time-varying vol)  : %+0.4f%%\n', mean(cev(V{2})));
fprintf('    full -> basic        (remove all oil price risk): %+0.4f%%\n', mean(cev(V{3})));
fprintf('    mean V: full %.5f  intermediate %.5f  basic %.5f\n', mean(Vf), mean(V{2}), mean(V{3}));
