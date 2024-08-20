function [dataset, method] = train_classifier(dataset, method)
% This function train cell classifier (logistic regression)
% INPUT:
%   [dataset] a class that contain fields
%       - features       : N x d.
%       - labels_ex      : N x 1 human / expert labels.
%       - labels_ml      : N x 1 cell classifier / ML labels .
%       - labels_ml_probs: N x 1 ML labels corresponding probablities being
%                          a cell predicted by mdl.
%       - q_idx_lst      : the query list of selected annotated cell
%                          indices.
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
%% Ready for logistic regression (classes as 0 and 1)
N = size(dataset.features, 1);
labeled_idxs = find(dataset.labels_ex ~= 0);
labeled_ex01 = dataset.labels_ex(labeled_idxs);
labeled_ex01(labeled_ex01==-1) = 0;
assert(all(labeled_ex01 == 0 | labeled_ex01 == 1), 'The array labeled_ex01 is not binary.');

%% Define the logistic regression regularization term
lam = method.lam;
num_samples = size(labeled_idxs,1);
if ~isstring(lam) && ~ischar(lam)
        lam = lam / num_samples;
end
%% Train the classifier
if ~method.balance
    mdl = fitclinear(dataset.features(labeled_idxs,:), labeled_ex01, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [0, 1], 'Prior', 'empirical','Lambda',lam);
else
    % balance the training dataset (2bb stands for to be balanced)
    dataset_2bb.features = dataset.features(labeled_idxs,:);
    dataset_2bb.labels   = labeled_ex01;
    dataset_2bb.labels(dataset_2bb.labels==0) = -1;
    method.balance_ratio = method.balance_ratio * method.balance_ratio_decay;
    dataset_b = balance_dataset(dataset_2bb, method.balance_ratio); % balanced dataset
    dataset_b.labels(dataset_b.labels==-1) = 0; % change the class back to binary
    mdl = fitclinear(dataset_b.features, dataset_b.labels, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [0, 1], 'Prior', 'empirical','Lambda',lam);	
end
[~, pred_probs] = predict(mdl, dataset.features);
pred = zeros(N, 1) - 1;  % because we label it in -1 and 1
pred_one_idxs = pred_probs(:,2) > method.cls_threshold;
pred(pred_one_idxs) = 1;

dataset.labels_ml_prob = pred_probs(:,2);
dataset.labels_ml = pred;

dataset.mdl = mdl;
end