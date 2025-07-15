function [dataset, pretrained, method] = fine_tune(dataset, pretrained, method)
% This function train cell classifier (logistic regression)
% INPUT:
%   [dataset] a structure that contain fields
%       - features       : cell of N x d.
%       - labels_ex      : cell of N x 1 human / expert labels.
%       - labels_ml      : cell of N x 1 cell classifier / ML labels .
%       - labels_ml_probs: cell of N x 1 ML labels corresponding probablities being
%                          a cell predicted by mdl.
%       - q_idx_lst      : the query 2D array of selected annotated cell
%                          indices [dataset_id, cell_id].
%       - mdl            : the fine-tuned classifier.
%   [method] the active learning query method
%       - name     : query algorithm name ['random', 'cal', 'dal', 'dcal']
%       - weight   : (required only when using dcal)
%       - n        : number of selected samples by the AL query algorithm.
%       - continue : if 0 then train from scratch. if 1 then fine-tune.
%       - lam      : the regularization for the mdl.
%       - balance  : balancing between Cell and Not Cell (default=false).
%                    to have the same number as Cell.
%       - balance_pretrained: (required when fine-tuning) balancing between 
%                             Cell and Not Cell for the pretrained dataset
%                             (default=false).
%       - threshold : (required when fine-tuning) a scalar define the 
%                     throwaway threshold, i.e., if error > threshold, then
%                     throw away the sample in the pretrained dataset. if 
%                     threshold is -1, then throw away the sample that has 
%                     the maximum error. (default=-1）
%  [pretrained] previous labeled dataset
%       - features  : cell of N x d
%       - labels_ex : cell of N x 1 human / expert labels (will be updated based
%                     one method.threshold)
%       - labels_ml : cell of N x 1 cell classifier / ML labels 
%       - labels_ml_prob : cell of N x 1 ML labels equal to 1 probability 
% OUTPUT:
%   [dataset]    : modify the labels_ml field in the input dataset
%   [pretrained] : modify the labels_ex field by throwing away some
%                  confusing samples.
%% process data
% get expert label data from the current dataset
labeled_idxs_this_cell = cellfun(@(x) find(x ~= 0), dataset.labels_ex, 'UniformOutput', false);
labeled_ex_this_cell   = cellfun(@(labels_ex, labeled_idxs) labels_ex(labeled_idxs), dataset.labels_ex, labeled_idxs_this_cell, 'UniformOutput', false);
features_ex_this_cell  = cellfun(@(features, labeled_idxs) features(labeled_idxs,:), dataset.features, labeled_idxs_this_cell, 'UniformOutput', false);
% get expert labeled data from the pretrained dataset
labeled_idxs_pretrain_cell = cellfun(@(x) find(pretrained.labels_ex ~= 0), pretrained.labels_ex, 'UniformOutput', false);
labeled_ex_pretrain_cell   = cellfun(@(labels_ex, labeled_idxs) labels_ex(labeled_idxs), pretrained.labels_ex, labeled_idxs_pretrain_cell, 'UniformOutput', false);
features_ex_pretrain_cell  = cellfun(@(features, labeled_idxs) features(labeled_idxs,:), pretrained.features, labeled_idxs_pretrain_cell, 'UniformOutput', false);

% get the features (this and pretrained)
labeled_ex_this  = vertcat(labeled_ex_this_cell{:});
features_ex_this = vertcat(features_ex_this_cell{:});

labeled_ex_pretrain  = vertcat(labeled_ex_pretrain_cell{:});
features_ex_pretrain = vertcat(features_ex_pretrain_cell{:});

%% fine-tuning
if ~method.balance_pretrained && ~method.balance
    % no oversampling
    features_cat   = [features_ex_this; features_ex_pretrain];
    labeled_ex_cat = [labeled_ex_this; labeled_ex_pretrain];
    
    mdl = fitclinear(features_cat, labeled_ex_cat, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [-1, 1], 'Prior', 'empirical','Lambda',"auto");	
elseif method.balance_pretrained && ~method.balance
    % oversample the pretrained dataset
    dataset_b.features = features_ex_pretrain;
    dataset_b.labels   = labeled_ex_pretrain;
    method.balance_ratio = method.balance_ratio * method.balance_ratio_decay;
    dataset_b = balance_dataset(dataset_b, method.balance_ratio);

    features_cat   = [features_ex_this; dataset_b.features];
    labeled_ex_cat = [labeled_ex_this; dataset_b.labels];
    mdl = fitclinear(features_cat, labeled_ex_cat, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [-1, 1], 'Prior', 'empirical','Lambda',"auto");
elseif ~method.balance_pretrained && method.balance
    % oversample the current dataset
    dataset_b.features = features_ex_this;
    dataset_b.labels   = labeled_ex_this;
    method.balance_ratio = method.balance_ratio * method.balance_ratio_decay;
    dataset_b = balance_dataset(dataset_b, method.balance_ratio);
    
    features_cat   = [dataset_b.features; features_ex_pretrain];
    labeled_ex_cat = [dataset_b.labels; labeled_ex_pretrain];
    mdl = fitclinear(features_cat, labeled_ex_cat, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [-1, 1], 'Prior', 'empirical','Lambda',"auto");
else
    % oversample both the datasets (this and pretrain)
    features_cat   = [features_ex_this; features_ex_pretrain];
    labeled_ex_cat = [labeled_ex_this; labeled_ex_pretrain];

    dataset_b.features = features_cat;
    dataset_b.labels   = labeled_ex_cat;
    method.balance_ratio = method.balance_ratio * method.balance_ratio_decay;
    dataset_b = balance_dataset(dataset_b, method.balance_ratio);

    mdl = fitclinear(dataset_b.features, dataset_b.labels, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [-1, 1], 'Prior', 'empirical','Lambda',"auto");
end

%% save the classifier
dataset.mdl = mdl;
[dataset.labels_ml, dataset.labels_ml_prob] = cellfun(@(features_i) classify_cells(dataset.mdl, ...
                                    features_i, method.cls_threshold), dataset.features, 'UniformOutput', false);
%% Throw away uncertain confusing samples in the pretrained dataset
num_dataset = length(pretrained);
for i=1:num_dataset
    pretrained_i = pretrained{i};
    labeled_idxs_pretrain = labeled_idxs_pretrain_cell{i};
    idx_throwaway = get_remove_idx(pretrained_i, labeled_idxs_pretrain);
    if ~isnan(idx_throwaway)
        pretrained_i.labels_ex(idx_throwaway) = 0;
    end
end
end

function idx_throwaway = get_remove_idx(pretrained_i, labeled_idxs_pretrain)
idx_throwaway = NaN;
if sum(pretrained_i.labels_ex ~= 0) ~= 0  % if there are annotated samples  
    % throw away a wrong sample from the pretrained dataset
    threshold = method.threshold;
    
    [~, pred_probs] = predict(mdl, pretrained_i.features(labeled_idxs_pretrain, :));
    pred1_probs = pred_probs(:,2);
    errors = zeros(size(pretrained_i.labels_ml,1), 1); % size of N_pretrained x 1
    errors(labeled_ex_pretrain==1) = 1 - pred1_probs(labeled_ex_pretrain==1);
    errors(labeled_ex_pretrain==-1) = pred1_probs(labeled_ex_pretrain==-1);
    
    if threshold == -1
        [~, maxerrorIdx] = max(errors);
        idx_throwaway = labeled_idxs_pretrain(maxerrorIdx);
    else
        idx_throwaway = labeled_idxs_pretrain(errors>threshold);
        if length(idx_throwaway) < 1 % if all error below threshold, then throw away the maximum error sample
            [~, maxerrorIdx] = max(errors);
            idx_throwaway = labeled_idxs_pretrain(maxerrorIdx);
        end
    end
end
end