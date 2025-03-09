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
dataset_id = q_idxs(1);
cell_id    = q_idxs(2);

dataset.labels_ex{dataset_id}(cell_id) = label;
dataset = dataset.update_sorting_order(q_idxs);
end