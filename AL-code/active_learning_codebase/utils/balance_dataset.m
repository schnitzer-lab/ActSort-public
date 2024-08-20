function [dataset] = balance_dataset(dataset, balance_ratio)
% This function balance the pretrained dataset by augmenting the expert
% labeled data such that the number of samples == cell is approximately
% equal to the number of samples == not cell.
% INPUT
%   [dataset] : a structure that contain fields
%       - features : N x d
%       - labels   : N x 1 expert / ml labels {-1,1}
% OUTPUT
%   [pretrained] : 
if nargin < 2
    balance_ratio = 1;
end
labeled_cellidxs = find(dataset.labels == 1);
labeled_notcidxs = find(dataset.labels == -1);

num_cells = sum(dataset.labels == 1);
num_notcs = sum(dataset.labels == -1);

assert(num_cells + num_notcs == size(dataset.labels,1), 'labels include not labeled cells')

if balance_ratio > 0
    if num_cells > num_notcs && num_cells ~= 0 && num_notcs ~= 0 % oversample if there are cells and not cells candidates
        num_aug = ceil((num_cells - num_notcs) * balance_ratio);
        idx = randsample(labeled_notcidxs, num_aug, true);
    elseif num_notcs > num_cells && num_cells ~= 0 && num_notcs ~= 0
        num_aug = ceil((num_notcs - num_cells) *  balance_ratio);
        idx = randsample(labeled_cellidxs, num_aug, true);
    end
    
    if num_cells ~= num_notcs && num_cells ~= 0 && num_notcs ~= 0
        X_aug = [dataset.features; dataset.features(idx,:)];
        y_aug = [dataset.labels; dataset.labels(idx)];
    else
        X_aug = [dataset.features];
        y_aug = [dataset.labels];
    end

    dataset.labels   = y_aug;
    dataset.features = X_aug;
end
end