function [q_idxs, scores] = strategy_dal(dataset, n)
% Active learning query strategy 
% Output selected query indices [q_idxs] for the unlabeled training dataset
% i.e., [dataset.X[~labeled_idxs,:]]. 
% Update the [dataset] with [dataset.labeled_idxs]
	
%% Query
N_lst = dataset.num_cells;
data_mask = repelem(1:numel(N_lst), N_lst)';
cell_mask = arrayfun(@(N) 1:N, N_lst, 'UniformOutput', false);
cell_mask = horzcat(cell_mask{:})';

features = vertcat(dataset.features{:});
labels_ex = vertcat(dataset.labels_ex{:});

unlabeled_idxs = find(labels_ex == 0);
if isempty(unlabeled_idxs) % Return NaN if all the cells are sorted
    scores = ones(1, n);
    q_idxs = NaN;
    return
end

labeled_idxs   = (labels_ex ~= 0);
% train binary classifier
Xbc = features;
ybc = labeled_idxs;
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
% select
[~, probs] = predict(bc_mdl, features(unlabeled_idxs,:));
[sortedValues, sortedIndices] = sort(probs(:,2), 'ascend');

unlabeled_idxs = unlabeled_idxs(sortedIndices(1:n));
unlabeled_data_idxs = data_mask(unlabeled_idxs)';
unlabeled_cell_idxs = cell_mask(unlabeled_idxs)';

q_idxs = zeros(n, 2);
q_idxs(:,1) = unlabeled_data_idxs;
q_idxs(:,2) = unlabeled_cell_idxs;

scores = sortedValues(1:n);
end