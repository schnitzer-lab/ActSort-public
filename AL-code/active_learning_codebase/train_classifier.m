function [dataset, method] = train_classifier(dataset, method)
% This function train cell classifier (logistic regression)
% INPUT:
%   [dataset] a class that contain fields
%       - features       : cell of N x d.
%       - labels_ex      : cell of N x 1 human / expert labels.
%       - labels_ml      : cell of N x 1 cell classifier / ML labels .
%       - labels_ml_probs: cell of N x 1 ML labels corresponding probablities being
%                          a cell predicted by mdl.
%       - q_idx_lst      : the query 2D array of selected annotated cell
%                          indices [dataset_id, cell_id]
%       - mdl            : the classifier.
%   [method] the active learning query method
%       - name     : query algorithm name ['random', 'cal', 'dal', 'dcal']
%       - weight   : (required only when using dcal)
%       - n        : number of selected samples by the AL query algorithm.
%       - continue : if 0 then train from scratch. if 1 then fine-tune.
%       - lam      : the regularization for the mdl.
%       - balance  : weight for balancing between Cell and Not Cell.
%                    (default=NaN) 0.5 means oversampling Not Cell
%                    to have the same number as Cell.
%       - balance_pretrained: (required when fine-tuning) weight for
%                             balancing between Cell and Not Cell for the 
%                             pretrained dataset. (default=NaN)
%       - threshold : (required when fine-tuning) the probability threshold
%                     for throwing away uncertain samples from the pretrained 
%                     dataset. (default=-1)
% OUTPUT:
%   [dataset] : modify the labeld_ml field in the input dataset
%   [method]  : the cell classifier, a logistic regression model
%% Ready for logistic regression (classes as -1 and 1)

labeled_idxs_cell = cellfun(@(x) find(x ~= 0), dataset.labels_ex, 'UniformOutput', false);
labeled_ex_cell   = cellfun(@(labels_ex, labeled_idxs) labels_ex(labeled_idxs), dataset.labels_ex, labeled_idxs_cell, 'UniformOutput', false);
features_ex_cell  = cellfun(@(features, labeled_idxs) features(labeled_idxs,:), dataset.features, labeled_idxs_cell, 'UniformOutput', false);
% Create mask
uN_lst = cellfun(@(x) size(x, 1), features_ex_cell, 'UniformOutput', true); % a list of how many cells in each datasets. 
mask = repelem(1:numel(uN_lst), uN_lst)';

labeled_ex  = vertcat(labeled_ex_cell{:});
features_ex = vertcat(features_ex_cell{:});

%% Define the logistic regression regularization term
lam = method.lam;
num_samples = size(labeled_ex,1);
if ~isstring(lam) && ~ischar(lam)
        lam = lam / num_samples;
end
%% Train the classifier
if ~method.balance
    mdl = fitclinear(features_ex, labeled_ex, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [-1, 1], 'Prior', 'empirical','Lambda',lam);
else
    % balance the training dataset (2bb stands for to be balanced)
    dataset_2bb.features = features_ex;
    dataset_2bb.labels   = labeled_ex;
    method.balance_ratio = method.balance_ratio * method.balance_ratio_decay;
    dataset_b = balance_dataset(dataset_2bb, method.balance_ratio); % balanced dataset
    mdl = fitclinear(dataset_b.features, dataset_b.labels, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [-1, 1], 'Prior', 'empirical','Lambda',lam);	
end

dataset.mdl = mdl;
[dataset.labels_ml, dataset.labels_ml_prob] = cellfun(@(features_i) classify_cells(dataset.mdl, features_i, method.cls_threshold), dataset.features, 'UniformOutput', false);
end