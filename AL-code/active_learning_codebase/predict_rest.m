function [labels, stats] = predict_rest(dataset)
% This function will predict all the unlabeled dataset with the latest cell
% sorter
% INPUT
%  [dataset] : a structure that contain fields
%       - features  : cell of N x d
%       - labels_ex : cell of N x 1 human / expert labels
%       - labels_ml : cell of N x 1 cell classifier / ML labels 
% OUTPUT
%  [labels] : expert labels complemented with cell classifier's prediction
%             on all unlabeled data (cell of N x 1)
%  [stats]  : a cell of stats for each dataset, including the # of sorted 
%             good cells, # of sorted bad cells, and the # of unlabeled
%             cells in each individual datasets_i. 
labels       = cell(1, dataset.num_datasets);
stats      = cell(1, dataset.num_datasets);

for i=1:dataset.num_datasets
    labels_ml = dataset.labels_ml{i};
    labels_ex = dataset.labels_ex{i};
    zeroIndices = dataset.labels_ex{i} == 0;
    
    % Replace zeros in labels_ex with corresponding values from labels_ml
    labels_ex(zeroIndices) = labels_ml(zeroIndices);
    labels{i} = labels_ex;

    numGood      = sum(labels_ex == 1);
    numBad       = sum(labels_ex == -1);
    numUnlabeled = sum(labels_ex == 0);
    stats{i}     = [numGood, numBad, numUnlabeled];
end
end