function [labels_ml, probs] = classify_cells(model, features, cls_threshold)
% This function uses the model to classify samples based on precomputed features.
% It outputs labels (-1 for negative, 1 for positive) and their probabilities.
%
% INPUT
%   [model] : Pretrained classifier
%   [features] : Features for classification.
%   [cls_threshold] : (Optional) A numeric value setting the classification threshold.
%                     Default value is 0.5.
%
% OUTPUT
%   [labels_ml] : A vector of predicted labels (-1 or 1) for each sample.
%   [probs] : A vector of associated probabilities for the positive class.
%
% USAGE
%   [labels, probabilities] = classify_cells(model, precomputedOutput, 0.6);
%

    % If classification threshold is not provided, set it to default 0.5
    if nargin < 3 || isempty(cls_threshold)
        cls_threshold = 0.5;
    end

    % Perform classification using the pretrained model
    [~, pred_probs] = predict(model, features);

    % Initialize predictions with -1 (negative class)
    N = size(features, 1);
    pred = zeros(N, 1) - 1;  

    % Assign label 1 to samples with probability above threshold
    pred_one_idxs = pred_probs(:,2) > cls_threshold;
    pred(pred_one_idxs) = 1;

    % Extract probabilities for the positive class
    probs = pred_probs(:,2);

    % Return predicted labels and probabilities
    labels_ml = pred;
end
