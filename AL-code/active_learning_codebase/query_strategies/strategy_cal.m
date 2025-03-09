function [q_idxs, scores] = strategy_cal(dataset, n, mdl)
% Active learning query strategy 
% Output selected query indices [q_idxs] for the unlabeled training dataset
% i.e., [dataset.X_train[~labeled_idxs,:]]. 
% Update the [dataset] with [dataset.labeled_idxs]

N_lst = dataset.num_cells;
data_mask = repelem(1:numel(N_lst), N_lst)';
cell_mask = arrayfun(@(N) 1:N, N_lst, 'UniformOutput', false);
cell_mask = horzcat(cell_mask{:})';

features = vertcat(dataset.features{:});
labels_ex = vertcat(dataset.labels_ex{:});

unlabeled_idxs = find(labels_ex == 0);

if isempty(unlabeled_idxs) % Return NaN if all the cells are sorted
    scores = ones(n,1);
    q_idxs = NaN;
    return
end

[~, probs] = predict(mdl, features);
probs = probs(:,2);
confidences = abs(probs - 0.5);
confidences(labels_ex ~= 0) = inf;
%[scores, q_idxs] = min(confidences);
[sortedValues, sortedIndices] = sort(confidences, 'ascend');

unlabeled_idxs = sortedIndices(1:n);
unlabeled_data_idxs = data_mask(unlabeled_idxs)';
unlabeled_cell_idxs = cell_mask(unlabeled_idxs)';

q_idxs = zeros(n, 2);
q_idxs(:,1) = unlabeled_data_idxs;
q_idxs(:,2) = unlabeled_cell_idxs;

scores = sortedValues(1:n);
end