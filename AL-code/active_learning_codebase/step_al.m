function [q_idxs, scores, dataset] = step_al(dataset, method)
% This function select the next [n] cells for human to annotate based on
% the AL algorithm [method]
% INPUT:
%   [dataset] a structure that contain fields
%       - features       : Cell of N x d.
%       - labels_ex      : Cell of N x 1 human / expert labels.
%       - labels_ml      : Cell of N x 1 cell classifier / ML labels .
%       - labels_ml_probs: Cell of N x 1 ML labels corresponding probablities being
%                          a cell predicted by mdl.
%       - q_idx_lst      : The query list of selected annotated cell
%                          indices.
%       - mdl            : The classifier.
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
%
% OUTPUT:
%   [q_idxs] : (1 x n) selected cell indices 
%   [scores] : (1 x n) selected cell corresponding scores
%   [dataset]: update the q_idx_lst with the newly selected sample(s).
n = method.n;
method_name = method.name;

%% Check if there are annotated samples
% Start using the query algorithm until at least 3 good cells and 3 bad cells are 
% annotated. Otherwise, use random as the query algorithm.

THRESHOLD = 3; % number of cells to annotate before AL query algorithm
labels_ex_all = vertcat(dataset.labels_ex{:});
num_good_cells = sum(labels_ex_all==1);
num_bad_cells =  sum(labels_ex_all==-1);
num_sorted_cells = num_good_cells + num_bad_cells;

if (num_good_cells<THRESHOLD || num_bad_cells<THRESHOLD)
    if (num_sorted_cells == 0) % If no cells sorted use random
        method_name = 'random';
    else
        method_name = 'dal';
    end
end

%% Query Algorithm Pick Sample to be Annotated

switch method_name
    case 'algo-rank'
        [q_idxs, scores] = strategy_algo_rank(dataset, n);
    case 'random'
        [q_idxs, scores] = strategy_random_sampling(dataset, n);
    case 'cal'
        [q_idxs, scores] = strategy_cal(dataset, n, dataset.mdl);
    case 'dal'
        [q_idxs, scores] = strategy_dal(dataset, n);
    case 'dcal'
        [q_idxs, scores] = strategy_dcal(dataset, n, dataset.mdl, method.weight);
end

dataset.q_idx_lst = [dataset.q_idx_lst; q_idxs];