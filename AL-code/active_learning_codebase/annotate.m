function dataset = annotate(dataset, q_idxs, label)
% This function record the newly annotated cell with label [label] and
% update the sorting order
% INPUT
%   [dataset] a structure that contain fields
%       - features : N x d
%       - labels_ex : N x 1 human / expert labels
%       - labels_ml : N x 1 cell classifier / ML labels 
%   [q_idxs] the selected cell id from the features matrix
%   [label]  -1/1 the human label for cell [q_idxs]
%
% OUTPUT
%   [dataset] : modify the labels_ex field

dataset.labels_ex(q_idxs) = label;
dataset = dataset.update_sorting_order(q_idxs);
end