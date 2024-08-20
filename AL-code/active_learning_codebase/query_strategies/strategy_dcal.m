function [q_idxs, scores] = strategy_dcal(dataset, n, mdl, weight)
% Active learning query strategy 
% Output selected query indices [q_idxs] for the unlabeled training dataset
% i.e., [dataset.X_train[~labeled_idxs,:]]. 
% Update the [dataset] with [dataset.labeled_idxs]


%% Query
unlabeled_idxs = find(dataset.labels_ex == 0);
if isempty(unlabeled_idxs) % Return NaN if all the cells are sorted
    scores = ones(1, n);
    q_idxs = NaN;
    return
end
[~, probs] = predict(mdl, dataset.features(unlabeled_idxs,:));

cal_score = 1-2*abs(probs(:,2)-0.5);
% log_probs = log(probs);
% cal_score = -sum(probs.*log_probs, 2); % calculate entropy

labeled_idxs   = (dataset.labels_ex ~= 0);
Xbc = dataset.features;
ybc = (labeled_idxs);
% Balance the set

idx = find(ybc == 1);
num_training = min(size(idx,1),size(ybc,1)-size(idx,1));
r = randperm(size(idx,1));
idx = idx(r(1:num_training));
X_train = Xbc(idx,:);
y_train = ybc(idx);
idx = find(ybc == 0);
r = randperm(size(idx,1));
idx = idx(r(1:num_training));
X_train = cat(1,X_train,Xbc(idx,:));
y_train = cat(1,y_train,ybc(idx));

% TODO: Do a cross-validation here
bc_mdl = fitclinear(X_train, y_train, ...
        'Learner', 'logistic', 'regularization', 'lasso',...
        'ClassNames', [0, 1], 'Prior', 'empirical');      
[y_pred] = predict(bc_mdl, dataset.features);
dal_accuracy = 2*(mean( y_pred == ybc)-0.5);
weight = weight * dal_accuracy;
% %%%%% TO BE DELTED [REBUTTAL] %%%%%
% global weight_lst
% weight_lst = [weight_lst, weight];
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% select
[~, probs] = predict(bc_mdl, dataset.features(unlabeled_idxs,:));
dal_score = probs(:,1);

%dcal_scores = 1./(weight./dal_score + (1-weight)./cal_score);
dcal_scores = weight*dal_score + (1-weight)*cal_score;

[sortedValues, sortedIndices] = sort(dcal_scores, 'descend');
q_idxs = unlabeled_idxs(sortedIndices(1:n)); 
scores = sortedValues(1:n);

end