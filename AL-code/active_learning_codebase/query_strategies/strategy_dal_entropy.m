function [q_idxs, scores] = strategy_dal_entropy(dataset, n, mdl)
% Active learning query strategy 
% Output selected query indices [q_idxs] for the unlabeled training dataset
% i.e., [dataset.X[~labeled_idxs,:]]. 
% Update the [dataset] with [dataset.labeled_idxs]
	
%% Query
unlabeled_idxs = find(dataset.labels_ex == 0);
if isempty(unlabeled_idxs) % Return NaN if all the cells are sorted
    scores = ones(1, n);
    q_idxs = NaN;
    return
end
labeled_idxs   = dataset.labels_ex ~= 0;
% train binary classifier
Xbc = dataset.features;
ybc = int32(labeled_idxs);
bc_mdl = fitclinear(Xbc, ybc, ...
        'Learner', 'logistic', 'regularization', 'lasso',...
        'ClassNames', [0, 1], 'Prior', 'empirical');		
% select
[~, probs] = predict(bc_mdl, dataset.features(unlabeled_idxs,:));
log_probs = log(probs);
uncertainties = sum(probs.*log_probs); % calculate entropy
[sortedValues, sortedIndices] = sort(uncertainties, 'ascend');
q_idxs = unlabeled_idxs(sortedIndices(1:n)); 
scores = sortedValues(1:n);
end