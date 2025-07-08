function [q_idxs, scores] = strategy_algo_rank(dataset, n)
% strategy_algo_rank - Selects first unsorted cells for active learning
%
% INPUT:
%   dataset - Struct with dataset information
%     dataset.labels_ex: {D x 1} cell, each {M_d x 1} (0 = unsorted, 1 = sorted)
%   n - Integer, number of queries to select
%
% OUTPUT:
%   q_idxs - [N x 2] matrix, columns: [dataset_idx, cell_idx] (NaN if all sorted)
%   scores - [N x 1] vector, initialized to 0 (ones(n,1) if all sorted)

%% Query
N_lst = dataset.num_cells;
data_mask = repelem(1:numel(N_lst), N_lst)';
cell_mask = arrayfun(@(N) 1:N, N_lst, 'UniformOutput', false);
cell_mask = horzcat(cell_mask{:})';

labels_ex = vertcat(dataset.labels_ex{:});

unlabeled_idxs = find(labels_ex == 0, n);

if isempty(unlabeled_idxs)
    scores = ones(n, 1);
    q_idxs = [NaN, NaN];
    return
end

unlabeled_data_idxs = data_mask(unlabeled_idxs)';
unlabeled_cell_idxs = cell_mask(unlabeled_idxs)';

q_idxs = zeros(n, 2);
q_idxs(:,1) = unlabeled_data_idxs;
q_idxs(:,2) = unlabeled_cell_idxs;
scores = zeros(n, 1);
end