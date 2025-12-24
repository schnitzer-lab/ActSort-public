clear;clc;

rng(54135)

features  = cell(1, 1);
labels    = cell(1, 1);
labels_gt = cell(1, 1);

features_ft  = cell(1, 1);
labels_ft    = cell(1, 1);
labels_gt_ft = cell(1, 1);

load('m1_hemisphere.mat')
features{1}  = metrics';
labels{1} = koala_choices';
combinedChoices = [guinea_pig_choices; lion_choices; panda_choices];
labels_gt{1} = mode(combinedChoices, 1)';
clear metrics koala_choices guinea_pig_choices lion_choices panda_choices;

load('m2_hemisphere.mat')
features_ft{1}  = metrics';
labels_ft{1} = dragon_choices';
combinedChoices = [guinea_pig_choices; lion_choices; panda_choices];
labels_gt_ft{1} = mode(combinedChoices, 1)';
clear metrics guinea_pig_choices dragon_choices lion_choices panda_choices;

% load('m3_hemisphere.mat')
% features{3}  = metrics';
% labels{3} = koala_choices';
% combinedChoices = [cheetah_choices; guinea_pig_choices; lion_choices];
% labels_gt{3} = mode(combinedChoices, 1)';
% clear metrics cheetah_choices guinea_pig_choices koala_choices lion_choices;
% clear combinedChoices;

ratio_pretrain = 0.2;
ratio_finetune = 0.05;
method_lst = {'cal'}; %{'random', 'algo-rank', 'dal', 'cal', 'dcal-0.3', 'dcal-0.5', 'dcal-0.7'};

config_pretrain.zscore = true;
config_pretrain.n = 1;
config_pretrain.repeat = 1;
config_pretrain.cls_threshold = 0.65;
config_pretrain.continue      = false;

config_finetune.zscore = true;
config_finetune.n = 1;
config_finetune.repeat = 1;
config_finetune.balance = 1; % for balancing dataset when training from scratch
config_finetune.balance_ratio = 1;
config_finetune.balance_pretrained = 1; % for balancing pretrain data
config_finetune.cls_threshold = 0.65;
config_finetune.continue      = true;
config_finetune.threshold     = -1;
config_finetune.align = false;

eval_lst = cell(1, length(method_lst));
for k=1:length(method_lst)
    fprintf("Running method %s", method_lst{k})
    method_name = method_lst{k};
    %% pretrain
    [~, pretrained, ~] = play_active_learning_new(method_name,features,labels,labels_gt,ratio_pretrain,config_pretrain);
    %% fine-tune
    [eval_metrics, dataset, method] = play_active_learning_new(method_name,features_ft,labels_ft,labels_gt_ft,ratio_finetune,config_finetune,pretrained);
   
    eval_lst{k} = eval_metrics;
end
%% baseline 
labels_gt_all = vertcat(labels_gt{:});
labels_all    = vertcat(labels{:});
TPR = mean(labels_all(labels_gt_all==1) == 1);
TNR = mean(labels_all(labels_gt_all==-1) == -1);
ACC = (TPR + TNR) / 2;
%% plot evaluation for each method
color_map = [0,      0.4470, 0.7410; % blue
             0.8500, 0.3250, 0.0980; % orange
             0.9290, 0.6940, 0.1250; % yellow
             0.4940, 0.1840, 0.5560; % purple
             0.4660, 0.6740, 0.1880; % green
             0.6350, 0.0780, 0.1840; % red
             0.3010 0.7450 0.9330];  % light blue
for k=1:length(method_lst)
    method_name = method_lst{k};
    eval_metrics = eval_lst{k};
    H = length(eval_metrics.ACC);
    % plot ACC
    subplot(1,3,1)
    plot(eval_metrics.ACC, 'DisplayName',method_name, 'Color',color_map(k,:), 'LineStyle','-', 'LineWidth',2)
    hold on
    legend() 
    ylabel('Accuracy')
    xlabel('Percentage')
    % plot TPR 
    subplot(1,3,2)
    plot(eval_metrics.TPR, 'DisplayName',method_name, 'Color',color_map(k,:), 'LineStyle','-', 'LineWidth',2)
    hold on
    legend() 
    ylabel('True Positive Rate')
    xlabel('Percentage')
    % plot TNR
    subplot(1,3,3)
    plot(eval_metrics.TNR, 'DisplayName',method_name, 'Color',color_map(k,:), 'LineStyle','-', 'LineWidth',2)
    hold on
    legend() 
    ylabel('True Negative Rate')
    xlabel('Percentage')
end
subplot(1,3,1)
line([1, H], [ACC, ACC], 'Color', 'k', 'LineStyle', '--', 'DisplayName', 'human', 'LineWidth', 0.5);
hold off

subplot(1,3,2)
line([1, H], [TPR, TPR], 'Color', 'k', 'LineStyle', '--', 'DisplayName', 'human', 'LineWidth', 0.5);
hold off

subplot(1,3,3)
line([1, H], [TNR, TNR], 'Color', 'k', 'LineStyle', '--', 'DisplayName', 'human', 'LineWidth', 0.5);
hold off