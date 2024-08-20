function dataset = cat_twodatasets(dataset1, dataset2)
% INPUT
%   [dataset1] : the final dataset (struct). 
%       - features       : N1 x d
%       - labels_ex      : N1 x 1 human / expert labels
%       - labels_ml      : N1 x 1 cell classifier / ML labels 
%       - labels_ml_prob : N1 x 1 ML labels corresponding probablities
% OUTPUT
%   [dataset] : the final dataset (struct). 
%       - features       : (N1 + N2) x d
%       - labels_ex      : (N1 + N2) x 1 human / expert labels
dataset.features  = [dataset1.features; dataset2.features];
dataset.labels_ex = [dataset1.labels_ex; dataset2.labels_ex];
dataset.labels_ml = [dataset1.labels_ml; dataset2.labels_ml];
dataset.labels_ml_prob = [dataset1.labels_ml_prob; dataset2.labels_ml_prob];
if isfield(dataset1, 'balance'), dataset.balance = dataset1.balance; end
if isfield(dataset1, 'balance_pretrained'), dataset.balance_pretrained = dataset1.balance_pretrained; end
if isfield(dataset1, 'align'), dataset.align = dataset1.algin; end
end