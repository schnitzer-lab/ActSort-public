function [q_idxs, scores] = strategy_cal(dataset, n, mdl)
% Active learning query strategy 
% Output selected query indices [q_idxs] for the unlabeled training dataset
% i.e., [dataset.X_train[~labeled_idxs,:]]. 
% Update the [dataset] with [dataset.labeled_idxs]

unlabeled_idxs = find(dataset.labels_ex == 0, 1); % added ,1 for performance
if isempty(unlabeled_idxs) % Return NaN if all the cells are sorted
    scores = ones(n,1);
    q_idxs = NaN;
    return
end

[~, probs] = predict(mdl, dataset.features);
probs = probs(:,2);
confidences = abs(probs - 0.5);
confidences(dataset.labels_ex ~= 0) = inf;
%[scores, q_idxs] = min(confidences);
[sortedValues, sortedIndices] = sort(confidences, 'ascend');
q_idxs = sortedIndices(1:n);
scores = sortedValues(1:n);
end