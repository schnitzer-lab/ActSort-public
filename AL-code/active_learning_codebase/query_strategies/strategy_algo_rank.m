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
first_unsorted_idx = NaN; % Default if all datasets are sorted

% Iterate through dataset indices in increasing order
for ds_idx = 1:length(dataset.labels_ex)
    labels_subset = dataset.labels_ex{ds_idx}; % Get labels for current dataset

    % Find unlabeled (unsorted) indices
    unlabeled_idxs = labels_subset == 0;

    if ~isempty(unlabeled_idxs)
        first_unsorted_idx = ds_idx;
        break; % Stop at the first dataset with unsorted cells
    end
end

% If all datasets are fully sorted, return NaN
if isnan(first_unsorted_idx)
    scores = ones(n,1);
    q_idxs = NaN;
    return;
end

% Select first `n` unsorted cells in the identified dataset
labels_subset = dataset.labels_ex{first_unsorted_idx}; % Get labels again
unlabeled_idxs = find(labels_subset == 0); % Get unsorted cell indices

% Select first `n` indices (without exceeding available unsorted cells)
selected_cells = unlabeled_idxs(1:min(n, length(unlabeled_idxs)));

% Construct the output matrix [dataset_index, cell_index]
q_idxs = [repmat(first_unsorted_idx, length(selected_cells), 1), selected_cells];

% Initialize scores
scores = zeros(size(q_idxs,1),1);
end