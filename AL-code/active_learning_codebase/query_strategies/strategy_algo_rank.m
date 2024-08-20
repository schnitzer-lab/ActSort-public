function [q_idxs, scores] = strategy_algo_rank(dataset, n)
% Active learning query strategy 
% Output selected query indices [q_idxs] for the unlabeled training dataset
% i.e., [dataset.X_train[~labeled_idxs,:]]. 
% Update the [dataset] with dataset.labeled_idxs]
%% Query
unlabeled_idxs = find(dataset.labels_ex == 0);
if isempty(unlabeled_idxs) % Return NaN if all the cells are sorted
    scores = ones(n,1);
    q_idxs = NaN;
    return
end
q_idxs = unlabeled_idxs(1:n); % sample without replacement
scores = zeros(n,1);
end