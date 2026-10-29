A=load('oil_bm.mat','output_matrix','v_matrix','p_grid','p_num','p_vol_num','prob_vector_p');
P=exp(reshape(A.p_grid,A.p_num,A.p_vol_num));
floorp=0.3^2;
fprintf('CES feasibility floor alpha^(1/theta) = %.4f\n\n',floorp);
fprintf('%-6s %10s %12s %14s %14s\n','state','min node','below floor','max output','max |value|');
for k=1:A.p_vol_num
  O=A.output_matrix(:,:,:,k); V=A.v_matrix(:,:,:,k);
  fprintf('%-6d %10.4f %12d %14.3e %14.3e\n',k,P(1,k),sum(P(:,k)<floorp),max(O(:)),max(abs(V(:))));
end
fprintf('\noutput at the infeasible node (i_p=1,i_vol=5): %.4e\n',max(max(A.output_matrix(:,:,1,5))));
fprintf('output excluding that node, whole model:      %.4e\n', ...
  max(reshape(A.output_matrix(:,:,2:end,:),[],1)));
O=A.output_matrix; O(:,:,1,5)=NaN;
fprintf('max output excluding ONLY (1,5):              %.4e\n',max(O(:),[],'omitnan'));
