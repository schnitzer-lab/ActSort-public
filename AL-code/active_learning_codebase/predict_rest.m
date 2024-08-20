function [labels] = predict_rest(dataset)
% This function will predict all the unlabeled dataset with the latest cell
% sorter
% INPUT
%  [dataset] : a structure that contain fields
%       - features : N x d
%       - labels_ex : N x 1 human / expert labels
%       - labels_ml : N x 1 cell classifier / ML labels 
% OUTPUT
%  [labels] : expert labels complemented with cell classifier's prediction
%             on all unlabeled data (N x 1)
labels_ml = dataset.labels_ml;
labels_ex = dataset.labels_ex;
zeroIndices = dataset.labels_ex == 0;

% Replace zeros in labels_ex with corresponding values from labels_ml
labels_ex(zeroIndices) = labels_ml(zeroIndices);
labels = labels_ex;
end