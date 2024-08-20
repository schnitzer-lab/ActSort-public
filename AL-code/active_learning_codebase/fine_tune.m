function [dataset, pretrained, method] = fine_tune(dataset, pretrained, method)
% This function train cell classifier (logistic regression)
% INPUT:
%   [dataset] a structure that contain fields
%       - features       : N x d.
%       - labels_ex      : N x 1 human / expert labels.
%       - labels_ml      : N x 1 cell classifier / ML labels .
%       - labels_ml_probs: N x 1 ML labels corresponding probablities being
%                          a cell predicted by mdl.
%       - q_idx_lst      : the query list of selected annotated cell
%                          indices.
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
%       - features  : N x d
%       - labels_ex : N x 1 human / expert labels (will be updated based
%                     one method.threshold)
%       - labels_ml : N x 1 cell classifier / ML labels 
%       - labels_ml_prob : N x 1 ML labels equal to 1 probability 
% OUTPUT:
%   [dataset]    : modify the labels_ml field in the input dataset
%   [pretrained] : modify the labels_ex field by throwing away some
%                  confusing samples.
%% process data
% binarize the dataset (this stands for the current dataset)
labeled_idxs_this = find(dataset.labels_ex ~= 0);
labeled_ex01_this = dataset.labels_ex(labeled_idxs_this);
labeled_ex01_this(labeled_ex01_this==-1) = 0;
% binarize the pretrained dataset
labeled_idxs_pretrain = find(pretrained.labels_ex ~= 0);
labeled_ex01_pretrain = pretrained.labels_ex(labeled_idxs_pretrain);
labeled_ex01_pretrain(labeled_ex01_pretrain==-1) = 0;
% get the features (this and pretrained)
features_this     = dataset.features(labeled_idxs_this,:);
features_pretrain = pretrained.features(labeled_idxs_pretrain, :);

%% fine-tuning
if ~method.balance_pretrained && ~method.balance
    % no oversampling
    features_cat     = [features_this; features_pretrain];
    labeled_ex01_cat = [labeled_ex01_this; labeled_ex01_pretrain];
    
    mdl = fitclinear(features_cat, labeled_ex01_cat, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [0, 1], 'Prior', 'empirical','Lambda',"auto");	
elseif method.balance_pretrained && ~method.balance
    % oversample the pretrained dataset
    dataset_b.features = features_pretrain;
    dataset_b.labels   = labeled_ex01_pretrain;
    dataset_b.labels(dataset_b.labels==0) = -1;
    method.balance_ratio = method.balance_ratio * method.balance_ratio_decay;
    dataset_b = balance_dataset(dataset_b, method.balance_ratio);
    dataset_b.labels(dataset_b.labels==-1) = 0;

    features_cat     = [features_this; dataset_b.features];
    labeled_ex01_cat = [labeled_ex01_this; dataset_b.labels];
    mdl = fitclinear(features_cat, labeled_ex01_cat, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [0, 1], 'Prior', 'empirical','Lambda',"auto");
elseif ~method.balance_pretrained && method.balance
    % oversample the current dataset
    dataset_b.features = features_this;
    dataset_b.labels   = labeled_ex01_this;
    dataset_b.labels(dataset_b.labels==0) = -1;
    method.balance_ratio = method.balance_ratio * method.balance_ratio_decay;
    dataset_b = balance_dataset(dataset_b, method.balance_ratio);
    dataset_b.labels(dataset_b.labels==-1) = 0;
    
    features_cat     = [dataset_b.features; features_pretrain];
    labeled_ex01_cat = [dataset_b.labels; labeled_ex01_pretrain];
    mdl = fitclinear(features_cat, labeled_ex01_cat, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [0, 1], 'Prior', 'empirical','Lambda',"auto");
else
    % oversample both the datasets (this and pretrain)
    features_cat     = [features_this; features_pretrain];
    labeled_ex01_cat = [labeled_ex01_this; labeled_ex01_pretrain];

    dataset_b.features = features_cat;
    dataset_b.labels   = labeled_ex01_cat;
    dataset_b.labels(dataset_b.labels==0) = -1;
    method.balance_ratio = method.balance_ratio * method.balance_ratio_decay;
    dataset_b = balance_dataset(dataset_b, method.balance_ratio);
    dataset_b.labels(dataset_b.labels==-1) = 0;

    mdl = fitclinear(dataset_b.features, dataset_b.labels, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [0, 1], 'Prior', 'empirical','Lambda',"auto");
end
N = size(dataset.features, 1);
[~, pred_probs] = predict(mdl, dataset.features);
pred = zeros(N, 1) - 1;  % because we label it in -1 and 1
pred_one_idxs = pred_probs(:,2) > method.cls_threshold;
pred(pred_one_idxs) = 1;

dataset.labels_ml_prob = pred_probs(:,2);
dataset.labels_ml = pred;

dataset.mdl = mdl;
%% Throw away uncertain confusing samples in the pretrained dataset
if sum(pretrained.labels_ex ~= 0) ~= 0  % if there are annotated samples  
    % throw away a wrong sample from the pretrained dataset
    threshold = method.threshold;
    
    [~, pred_probs] = predict(mdl, pretrained.features(labeled_idxs_pretrain, :));
    pred1_probs = pred_probs(:,2);
    errors = zeros(size(pred,1), 1);
    errors(labeled_ex01_pretrain==1) = 1 - pred1_probs(labeled_ex01_pretrain==1);
    errors(labeled_ex01_pretrain==0) = pred1_probs(labeled_ex01_pretrain==0);
    
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
    pretrained.labels_ex(idx_throwaway) = 0;
end
end