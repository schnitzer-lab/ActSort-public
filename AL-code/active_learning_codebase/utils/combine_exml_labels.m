function [labels_exml] = combine_exml_labels(dataset)
% INPUT:
%   [dataset] a structure that contain fields
%       - features : N x d
%       - labels_ex : N x 1 human / expert labels
%       - labels_ml : N x 1 cell classifier / ML labels 
%       - labels_ml_prob : N x 1 ML labels equal to 1 probability

labels_ex_idx = find(dataset.labels_ex~=0);

labels_exml = dataset.labels_ml;
labels_exml(labels_ex_idx) = dataset.labels_ex(labels_ex_idx);
end