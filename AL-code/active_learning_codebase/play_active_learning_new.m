function [eval_metrics, dataset, method] = play_active_learning_new(method_name,metrics,choices,choices_gt,ratio,config,pretrained)
% this function run the active learning algorithm on [ratio] on the original
% cells based using [method]
% [INPUT]
%   [method_name] : the query algorithm name in string, e.g., 'cal',
%                   'dcal-0.5'. 
%   [metrics]    : the original features for all cells based on feature
%                  engineering (76 x num_cells).
%   [choices]    : the labels from one annotator. Same as choice_gt is we 
%                  are not comparing with the consensus labelings (1 x num_cells)
%   [choices_gt] : the groundtruth labeling (1 x num_cells).
%   [ratio]      : the ratio of cell sorted with active learning (int).
%   [config]     : data preprocessing configuration
%       - zscore  : true then z-scored the input
%       - n            : number of cells returned from query algorithm for
%                        user to label
%       - repeat       : number of repeat iteration for random 3 good 3 bad
%                        initialization.
% [OUTPUT]
%   [valid]   : True if all final predictions has probability > 0.5, False
%               otherwise (bool).
%   [eval_metric] : (struct) includes all evaluation metrics for every 1%
%                   step. 
%       - ACC : accuracy
%       - TPR : true positive rate
%       - TNR : true negative rate
%       - Precision : precision score
%       - Recall    : recall score
%       - Fscore    : F-score
%       - ROC       : ROC curve
%   [dataset] : the final dataset (struct). 
%       - features       : N x d
%       - labels_ex      : N x 1 human / expert labels
%       - labels_ml      : N x 1 cell classifier / ML labels 
%       - labels_ml_prob : N x 1 ML labels corresponding probablities
features  = metrics';
labels    = choices';
labels_gt = choices_gt';
% DEFINE NUMBER OF SORTED CELLS
num_cells = size(metrics,2);
stop_cell = floor(ratio*num_cells);
p1percent_cell = floor(0.001*num_cells);
% UPDATE CONFIG
config = parse_method_name(method_name, config);

% check for input, assert for pretrained dataset requirement for
% fine-tuning
if config.continue
    assert(nargin>6, 'please input the pretrained dataset for fine-tuning')
end

% randomize the inital 3 good 3 bad cells
eval_lst = cell(1,config.repeat);
for nexp = 1:config.repeat
    fprintf("repeat %i>>>", nexp);
    % INITIALIZE DATASET and METHOD
    if ~(config.continue)
        [dataset, method] = initialization(features, config);
    else
        [dataset, method] = initialization(features, config, pretrained);
    end
    % INITIALIZE EVALUATION METRICS
    eval_metrics = init_eval_metrics();
    % INITIALIZE CELL CLASSIFIER
    labels_1_indices = find(labels == 1);
    labels_minus1_indices = find(labels == -1);
    q_iscells = randsample(labels_1_indices, 3);
    q_nocells = randsample(labels_minus1_indices, 3);
    dataset.labels_ex(q_iscells) = labels(q_iscells);
    dataset.labels_ex(q_nocells) = labels(q_nocells);
    dataset.q_idx_lst = [dataset.q_idx_lst, q_iscells', q_nocells'];
    if ~(method.continue_sorting)
        [dataset, method] = train_classifier(dataset,method);
    else
        % align the distribution between dataset and pretrained
        if config.align
            dataset_feature_aligned = align_features(pretrained.features, dataset.features);
            dataset.features = dataset_feature_aligned;
        end
        [dataset, pretrained, method] = fine_tune(dataset, pretrained, method);
    end
    % ACTSORT
    for i=1:stop_cell
        % select next data to be labeled
        if ~method.continue_sorting
            [q_idxs, ~, dataset] = step_al(dataset, method);
        else
            [q_idxs, ~, dataset] = step_al(dataset, method, pretrained);
        end
        % label the data
        label = labels(q_idxs);
        % add the label to the training dataset
        dataset = annotate(dataset, q_idxs, label);
        % train the classifier
        if ~method.continue_sorting
            [dataset, method] = train_classifier(dataset,method);
        else
            [dataset, pretrained, method] = fine_tune(dataset, pretrained, method);
        end
        if i==1 || mod(i, p1percent_cell) == 0
            eval_metrics = get_accuracy(dataset, labels_gt, eval_metrics);
        end
    end
    eval_lst{nexp} = eval_metrics;
    %fprintf('Random initialization %i has accuracy %.2f%% and AUC %.2f\n', nexp, eval_metrics.ACC(end)*100, eval_metrics.AUC(end));
end
clear eval_metrics;
eval_metrics = avg_eval_lst(eval_lst);
fprintf("Finish %s\n", get_legend_name(method))
end
