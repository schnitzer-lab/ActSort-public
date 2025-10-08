clear;clc;

addpath(genpath('C:/Users/Yiqi/Desktop/ActSort-public/AL-code/active_learning_codebase'));

rng(54135)

num_datasets = 1;
features  = cell(1, num_datasets);
labels    = cell(1, num_datasets);
labels_gt = cell(1, num_datasets);

load('C:\Users\Yiqi\Desktop\data\ActSort-raw\m1_hempishere.mat')

features{1}  = metrics';
labels{1} = koala_choices';
combinedChoices = [guinea_pig_choices; lion_choices; panda_choices];
labels_gt{1} = mode(combinedChoices, 1)';
clear metrics koala_choices guinea_pig_choices lion_choices panda_choices;

% load('m2_hemisphere.mat')
% features{2}  = metrics';
% labels{2} = dragon_choices';
% combinedChoices = [guinea_pig_choices; lion_choices; panda_choices];
% labels_gt{2} = mode(combinedChoices, 1)';
% clear metrics guinea_pig_choices dragon_choices lion_choices panda_choices;
% 
% load('m3_hemisphere.mat')
% features{3}  = metrics';
% labels{3} = koala_choices';
% combinedChoices = [cheetah_choices; guinea_pig_choices; lion_choices];
% labels_gt{3} = mode(combinedChoices, 1)';
% clear metrics cheetah_choices guinea_pig_choices koala_choices lion_choices;
% clear combinedChoices;

method_lst = {'cal'}; % {'random', 'algo-rank', 'dal', 'cal', 'dcal-0.3', 'dcal-0.5', 'dcal-0.7'};

eval_lst = cell(1, length(method_lst));
for k=1:length(method_lst)
    fprintf("Running method %s", method_lst{k})
    config.zscore = true;
    config.n = 1;
    method_name = method_lst{k};
    [config] = parse_method_name(method_name, config);
    
    
    [dataset, method] = initialization(features, config);
    
    %% Initialize cell classifier
    for i=1:dataset.num_datasets
        labels_1_indices = find(labels{i} == 1);
        labels_minus1_indices = find(labels{i} == -1);
        q_iscells = randsample(labels_1_indices, 3);
        q_nocells = randsample(labels_minus1_indices, 3);
        dataset.labels_ex{i}(q_iscells) = labels{i}(q_iscells);
        dataset.labels_ex{i}(q_nocells) = labels{i}(q_nocells);
        
        q_idxs_iscells = [i * ones(numel(q_iscells), 1), q_iscells];
        q_idxs_nocells = [i * ones(numel(q_nocells), 1), q_nocells];
        dataset.q_idx_lst = [dataset.q_idx_lst; q_idxs_iscells; q_idxs_nocells];
    end
    
    % Train the classifier after initialization
    [dataset, method] = train_classifier(dataset, method);
    
    %% Start Active Learning
    num_cells = sum(cellfun(@(x) size(x, 1), dataset.features, 'UniformOutput', true));
    ratio = 0.05;
    stop_cell = floor(ratio*num_cells);
    p1percent_cell = floor(0.001*num_cells);
    
    eval_metrics = init_eval_metrics();
    
    for i=1:stop_cell
        [q_idxs, scores, dataset] = step_al(dataset, method);
        data_id = q_idxs(1);
        cell_id = q_idxs(2);
        label = labels{data_id}(cell_id);
        dataset = annotate(dataset, q_idxs, label);
        [dataset, method] = train_classifier(dataset,method);
        if i==1 || mod(i, p1percent_cell) == 0
            eval_metrics = get_accuracy(dataset, labels_gt, eval_metrics);
            % TODO: Add the stopping criteria function here
            % based on the labeled samples, what is the accuracy. Here you
            % only know labels, you don't have access to labels_gt
        end
    end
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

%% ===== PCA visualization at the end =====
fprintf('\nPerforming PCA visualization...\n');

% Run PCA on the features (use zscore to standardize columns)
X = zscore(features{1});
[coeff, score, latent] = pca(X);
pca_coords = score(:, 1:2);  % first two principal components

% Extract labels for coloring
gt_labels = labels_gt{1};

% Create figure
figure('Position', [100 100 800 700], 'Color', 'w');
hold on;

% Plot negative class (-1) in red
scatter(pca_coords(gt_labels == -1, 1), pca_coords(gt_labels == -1, 2), ...
    15, [0.85 0.33 0.1], 'filled', 'DisplayName', 'GT = -1');

% Plot positive class (+1) in blue
scatter(pca_coords(gt_labels == 1, 1), pca_coords(gt_labels == 1, 2), ...
    15, [0 0.45 0.74], 'filled', 'DisplayName', 'GT = +1');

% Optional: label variance explained
explainedVar = 100 * latent(1:2) / sum(latent);
xlabel(sprintf('PC1 (%.1f%%)', explainedVar(1)));
ylabel(sprintf('PC2 (%.1f%%)', explainedVar(2)));

title('PCA Projection of Feature Space (Colored by Ground Truth)');
legend('Location', 'bestoutside');
axis equal; box on; grid on;

hold off;





%correct PCA code
clear;clc;

addpath(genpath('C:/Users/Yiqi/Desktop/ActSort-public/AL-code/active_learning_codebase'));

rng(54135)

num_datasets = 1;
features  = cell(1, num_datasets);
labels    = cell(1, num_datasets);
labels_gt = cell(1, num_datasets);

load('C:\Users\Yiqi\Desktop\data\ActSort-raw\m1_hempishere.mat')

features{1}  = metrics';
labels{1} = koala_choices';
combinedChoices = [guinea_pig_choices; lion_choices; panda_choices];
labels_gt{1} = mode(combinedChoices, 1)';
clear metrics koala_choices guinea_pig_choices lion_choices panda_choices;

% load('m2_hemisphere.mat')
% features{2}  = metrics';
% labels{2} = dragon_choices';
% combinedChoices = [guinea_pig_choices; lion_choices; panda_choices];
% labels_gt{2} = mode(combinedChoices, 1)';
% clear metrics guinea_pig_choices dragon_choices lion_choices panda_choices;
% 
% load('m3_hemisphere.mat')
% features{3}  = metrics';
% labels{3} = koala_choices';
% combinedChoices = [cheetah_choices; guinea_pig_choices; lion_choices];
% labels_gt{3} = mode(combinedChoices, 1)';
% clear metrics cheetah_choices guinea_pig_choices koala_choices lion_choices;
% clear combinedChoices;

method_lst = {'cal'}; % {'random', 'algo-rank', 'dal', 'cal', 'dcal-0.3', 'dcal-0.5', 'dcal-0.7'};

eval_lst = cell(1, length(method_lst));
for k=1:length(method_lst)
    fprintf("Running method %s", method_lst{k})
    config.zscore = true;
    config.n = 1;
    method_name = method_lst{k};
    [config] = parse_method_name(method_name, config);
    
    
    [dataset, method] = initialization(features, config);
    
    %% Initialize cell classifier
    for i=1:dataset.num_datasets
        labels_1_indices = find(labels{i} == 1);
        labels_minus1_indices = find(labels{i} == -1);
        q_iscells = randsample(labels_1_indices, 3);
        q_nocells = randsample(labels_minus1_indices, 3);
        dataset.labels_ex{i}(q_iscells) = labels{i}(q_iscells);
        dataset.labels_ex{i}(q_nocells) = labels{i}(q_nocells);
        
        q_idxs_iscells = [i * ones(numel(q_iscells), 1), q_iscells];
        q_idxs_nocells = [i * ones(numel(q_nocells), 1), q_nocells];
        dataset.q_idx_lst = [dataset.q_idx_lst; q_idxs_iscells; q_idxs_nocells];
    end
    
    % Train the classifier after initialization
    [dataset, method] = train_classifier(dataset, method);
    
    %% Start Active Learning
    num_cells = sum(cellfun(@(x) size(x, 1), dataset.features, 'UniformOutput', true));
    ratio = 0.05;
    stop_cell = floor(ratio*num_cells);
    p1percent_cell = floor(0.001*num_cells);
    
    eval_metrics = init_eval_metrics();
    
    %% Perform PCA once on all features
    X = zscore(features{1});
    [coeff, score, latent] = pca(X);
    pca_coords = score(:,1:2);
    gt_labels = labels_gt{1};

% Initialize GIF file
gif_filename = 'pca_progress.gif';
gif_delay = 0.4; % seconds per frame

    for i=1:stop_cell
        [q_idxs, scores, dataset] = step_al(dataset, method);
        data_id = q_idxs(1);
        cell_id = q_idxs(2);
        label = labels{data_id}(cell_id);
        dataset = annotate(dataset, q_idxs, label);
        [dataset, method] = train_classifier(dataset,method);
        if i==1 || mod(i, p1percent_cell) == 0
            eval_metrics = get_accuracy(dataset, labels_gt, eval_metrics);
            % TODO: Add the stopping criteria function here
            % based on the labeled samples, what is the accuracy. Here you
            % only know labels, you don't have access to labels_gt
        end
    end
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

%% ===== PCA visualization at the end =====
fprintf('\nPerforming PCA visualization...\n');

% Run PCA on the features (use zscore to standardize columns)
X = zscore(features{1});
[coeff, score, latent] = pca(X);
pca_coords = score(:, 1:2);  % first two principal components

% Extract labels for coloring
gt_labels = labels_gt{1};

% Create figure
figure('Position', [100 100 800 700], 'Color', 'w');
hold on;

% Plot negative class (-1) in red
scatter(pca_coords(gt_labels == -1, 1), pca_coords(gt_labels == -1, 2), ...
    15, [0.85 0.33 0.1], 'filled', 'DisplayName', 'GT = -1');

% Plot positive class (+1) in blue
scatter(pca_coords(gt_labels == 1, 1), pca_coords(gt_labels == 1, 2), ...
    15, [0 0.45 0.74], 'filled', 'DisplayName', 'GT = +1');

% Optional: label variance explained
explainedVar = 100 * latent(1:2) / sum(latent);
xlabel(sprintf('PC1 (%.1f%%)', explainedVar(1)));
ylabel(sprintf('PC2 (%.1f%%)', explainedVar(2)));

title('PCA Projection of Feature Space (Colored by Ground Truth)');
legend('Location', 'bestoutside');
axis equal; box on; grid on;

hold off;