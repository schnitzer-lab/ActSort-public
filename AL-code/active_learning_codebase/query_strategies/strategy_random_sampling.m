function [q_idxs, scores] = strategy_random_sampling(dataset, n)
% strategy_random_sampling - Randomly selects unsorted cells for active learning
%
% INPUT:
%   dataset - Struct with dataset information
%     dataset.labels_ex: {D x 1} cell, each {M_d x 1} (0 = unsorted, 1 = sorted)
%   n - Integer, number of queries to select
%
% OUTPUT:
%   q_idxs - [N x 2] matrix, columns: [dataset_idx, cell_idx] (NaN if all sorted)
%   scores - [N x 1] vector, initialized to 0 (ones(n,1) if all sorted)
%
% QUERY:
%   - Finds all unsorted cells across datasets.
%   - Randomly selects `n` unsorted cells from all datasets (without replacement).

%% Query
q_idxs = NaN; % Default if all datasets are sorted
all_unlabeled = []; % To store all [dataset_idx, cell_idx] pairs

% Iterate over all dataset indices
for ds_idx = 1:length(dataset.labels_ex)
    labels_subset = dataset.labels_ex{ds_idx}; % Get labels for current dataset

    % Find unlabeled (unsorted) cell indices
    unlabeled_idxs = find(labels_subset == 0);

    % Store dataset index and cell index pairs
    if ~isempty(unlabeled_idxs)
        all_unlabeled = [all_unlabeled; repmat(ds_idx, length(unlabeled_idxs), 1), unlabeled_idxs];
    end
end

% If no unlabeled cells remain, return NaN
if isempty(all_unlabeled)
    scores = ones(n,1);
    q_idxs = NaN;
    return;
end

% Randomly select `n` unsorted cells (without replacement)
num_samples = min(n, size(all_unlabeled, 1)); % Ensure we don't exceed available samples
rand_indices = randperm(size(all_unlabeled, 1), num_samples);
q_idxs = all_unlabeled(rand_indices, :);

% Initialize scores
scores = zeros(size(q_idxs,1),1);
end
