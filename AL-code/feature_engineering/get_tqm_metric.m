function metric = get_tqm_metric(M_cell,S_cell,T_cell,event_ratio)
n_cell = size(S_cell,2);
metric = zeros(1,n_cell);
for i=1:n_cell
M = M_cell{i};
S = full(S_cell{i});
T = T_cell{i};
M = reshape(M,size(M,1)*size(M,2),[]);
S = reshape(S,size(S,1)*size(S,2),[]);
[metric(i)] = compute_temporal_goodness(M, T, S,event_ratio);
end
end