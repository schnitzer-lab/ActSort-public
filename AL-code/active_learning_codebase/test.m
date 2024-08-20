%% Load data
clear;clc;
load("data\hemisphere_dataset_summary.mat", 'choices_all', 'choices_gt_all', 'metrics_all', 'annotator_names')
annotator_lst = [1, 2, 3, 4; % dataset 1
                 1, 3, 4, 5; % dataset 2
                 1, 2, 3, 6];% dataset 3
d   = 1;
ann = 2;
choices    = choices_all{ann,d}; % annotator, dataset
choices_gt = choices_gt_all{ann,d}; 
metrics    = metrics_all{d};

% labels    = choices';
% labels_gt = choices_gt';
% features  = metrics';

% DEFINE NUMBER OF SORTED CELLS
ratio = 0.2;
num_cells = size(metrics,2);
stop_cell = floor(ratio*num_cells);
p1percent_cell = floor(0.001*num_cells);

% define methods
method_name_lst = {'random', 'cal', 'dal', 'dcal-0.3', 'dcal-0.5', 'dcal-0.7'};
num_methods = length(method_name_lst);
%%
config.repeat = 1;
config.continue    = 0;
config.balance     = 0;
config.zscore      = true;

eval_lst = cell(1,num_methods);
for k=1:num_methods
    method_name = method_name_lst{k};
    fprintf("[INFO] start running %s...", method_name);
    [eval_metrics, dataset] = play_active_learning_new(method_name, metrics,choices,choices_gt,ratio,config);
    eval_lst{k} = eval_metrics;
end
%% plot
H = length(eval_lst{1}.ACC);
x = 1:1:H;
x = x ./ 10;
eval_metrics_human = get_ex_accuracy(choices', choices_gt');
for k=1:num_methods
    eval_metrics = eval_lst{k};
    method_name = method_name_lst{k};
    plot(x, eval_metrics.ACC, 'DisplayName', method_name)
    hold on
end
line([1, H]./10, [eval_metrics_human.ACC, eval_metrics_human.ACC], ...
    'Color', 'k', 'LineStyle', '--', 'DisplayName', 'human', 'LineWidth', 0.5);
hold off
legend()