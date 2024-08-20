% this file is the runner of the active learning
clear;clc;
rng(19991112)
%% LOAD DATA
load('hemisphere_dataset_summary.mat')
choices    = choices_all{2,3};
choices_gt = choices_gt_all{2,3};
metrics = metrics_all{3};
%% Hyperparameters
ratio = 0.01;

method_rand = struct("name", "random");
method_cal  = struct("name", "cal");
method_dal  = struct("name", "dal");
methods     = {method_rand, method_cal, method_dal};
for i=[]
    weight = i / 10;
    method_dcal = struct("name", "dcal", "weight", weight);
    methods{end+1} = method_dcal;
end
%% ActSort
dataset_lst = {};
eval_lst    = {};
for k=1:1:length(methods)
    method = methods{k}
    [valid, eval_metrics, dataset] = play_active_learning_new(metrics,choices,choices_gt,ratio,method);
    dataset_lst{end+1} = dataset;
    eval_lst{end+1}    = eval_metrics;
end 
%% Evaluation
for i=1:length(eval_lst)
    method = methods{i};
    dispname = get_legend_name(method);
    figure(1)
    plot(eval_lst{i}.ACC, 'DisplayName',dispname)
    hold on
    figure(2)
    plot(eval_lst{i}.TPR, 'DisplayName',dispname)
    hold on
    figure(3)
    plot(eval_lst{i}.TNR, 'DisplayName',dispname)
    hold on
    figure(4)
    plot(eval_lst{i}.Precision, 'DisplayName',dispname)
    hold on 
    figure(5)
    plot(eval_lst{i}.Recall, 'DisplayName',dispname)
    hold on 
    figure(6)
    plot(eval_lst{i}.Fscore, 'DisplayName',dispname)
    hold on
    figure(7)
    plot(eval_lst{i}.AUC, 'DisplayName',dispname)
    hold on
end
figure(1)
title('Accuracy')
legend()
figure(2)
title('True Positive Rate')
legend()
figure(3)
title('True Negative Rate')
legend()
figure(4)
title('Precision')
legend()
figure(5)
title('Recall')
legend()
figure(6)
title('F-Score')
legend()
figure(7)
title('AUC')
legend()