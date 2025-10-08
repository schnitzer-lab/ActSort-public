clear; clc;

%% Setup
ratio = 0.20;
seeds = [54135, 9, 324];
num_seeds = numel(seeds);

method_lst   = {'cal'}; 
num_methods  = numel(method_lst);

num_datasets = 1;
features  = cell(1, num_datasets);
labels_gt = cell(1, num_datasets);

load('m1_hemisphere.mat')
features{1}  = metrics';

labelers = {koala_choices', guinea_pig_choices', lion_choices', panda_choices'};
num_labelers = numel(labelers);

% Ground truth = majority vote of 3 labelers
combinedChoices = [guinea_pig_choices; lion_choices; panda_choices];
labels_gt{1} = mode(combinedChoices, 1)';

clear metrics koala_choices guinea_pig_choices lion_choices panda_choices;

%% Storage
cv_acc_all    = cell(num_seeds, num_labelers, num_methods);
cv_TPR_all    = cell(num_seeds, num_labelers, num_methods);
cv_TNR_all    = cell(num_seeds, num_labelers, num_methods);
cv_prec_all   = cell(num_seeds, num_labelers, num_methods);
cv_recall_all = cell(num_seeds, num_labelers, num_methods);

eval_lst      = cell(num_seeds, num_labelers, num_methods); % for GT curves

%% Run
for s = 1:num_seeds
    rng(seeds(s));
    fprintf('Seed %d\n', seeds(s));

    for l = 1:num_labelers
        fprintf('  Labeler %d/%d\n', l, num_labelers);
        labels_for_run = {labelers{l}};  % wrap for compatibility

        for k = 1:num_methods
            method_name = method_lst{k};
            fprintf('    Method %s\n', method_name);

            config.zscore = true;
            config.n      = 1;
            [config] = parse_method_name(method_name, config);
            [dataset, method] = initialization(features, config);

            % --- Initialize classifier with 3 positive & 3 negative ---
            for di = 1:dataset.num_datasets
                l1_idx  = find(labels_for_run{di} == 1);
                l_1_idx = find(labels_for_run{di} == -1);
                n_init  = min([3, numel(l1_idx), numel(l_1_idx)]);
                if n_init < 1, continue; end

                q_iscells = randsample(l1_idx,  n_init);
                q_nocells = randsample(l_1_idx, n_init);
                dataset.labels_ex{di}(q_iscells) = labels_for_run{di}(q_iscells);
                dataset.labels_ex{di}(q_nocells) = labels_for_run{di}(q_nocells);

                q_idxs_iscells = [di*ones(numel(q_iscells),1), q_iscells];
                q_idxs_nocells = [di*ones(numel(q_nocells),1), q_nocells];
                dataset.q_idx_lst = [dataset.q_idx_lst; q_idxs_iscells; q_idxs_nocells];
            end

            [dataset, method] = train_classifier(dataset, method);

            % --- Active Learning Loop ---
            num_cells = sum(cellfun(@(x) size(x,1), dataset.features));
            stop_cell = floor(ratio * num_cells);
            step_unit = max(1, floor(0.01 * num_cells));
            warmup    = max(2*step_unit, 1);

            eval_metrics = init_eval_metrics();

            cv_acc_list = []; cv_TPR_list = []; cv_TNR_list = [];
            cv_prec_list = []; cv_recall_list = [];

            for i = 1:stop_cell
                [q_idxs, scores, dataset] = step_al(dataset, method);
                data_id = q_idxs(1); cell_id = q_idxs(2);
                new_label = labels_for_run{data_id}(cell_id);
                dataset = annotate(dataset, q_idxs, new_label);
                [dataset, method] = train_classifier(dataset, method);

                if i >= warmup && ( (i-warmup)==0 || mod(i-warmup,step_unit)==0 )
                    % CV performance
                    [cv_acc, cv_TPR, cv_TNR, cv_prec, cv_recall] = cross_val_on_labeled(dataset,5);
                    cv_acc_list(end+1)    = cv_acc;
                    cv_TPR_list(end+1)    = cv_TPR;
                    cv_TNR_list(end+1)    = cv_TNR;
                    cv_prec_list(end+1)   = cv_prec;
                    cv_recall_list(end+1) = cv_recall;

                    % GT performance
                    eval_metrics = get_accuracy(dataset, labels_gt, eval_metrics);
                end
            end

            cv_acc_all{s,l,k}    = cv_acc_list;
            cv_TPR_all{s,l,k}    = cv_TPR_list;
            cv_TNR_all{s,l,k}    = cv_TNR_list;
            cv_prec_all{s,l,k}   = cv_prec_list;
            cv_recall_all{s,l,k} = cv_recall_list;

            eval_lst{s,l,k} = eval_metrics;
        end
    end
end

%% Baseline (constant human performance)
labels_gt_all = vertcat(labels_gt{:});
labels_all    = vertcat(labelers{:}); % combine all annotators
TPR_base = mean(labels_all(labels_gt_all==1) == 1);
TNR_base = mean(labels_all(labels_gt_all==-1) == -1);
ACC_base = (TPR_base + TNR_base) / 2;

%% Plotting: CV vs GT vs Baseline
metrics = {'ACC','TPR','TNR','Precision','Recall'};
colors  = {'k','b','r','g','m'};

figure;
for m = 1:length(metrics)
    metric_name = metrics{m};
    col = colors{m};

    % === CV mean ± SEM ===
    switch metric_name
        case 'ACC'
            cv_all = cv_acc_all;
        case 'TPR'
            cv_all = cv_TPR_all;
        case 'TNR'
            cv_all = cv_TNR_all;
        case 'Precision'
            cv_all = cv_prec_all;
        case 'Recall'
            cv_all = cv_recall_all;
    end

    % flatten across seeds,labelers,methods
    min_len = min(cellfun(@length, cv_all(:)));
    tmp = cellfun(@(x) reshape(x(1:min(end, min_len)), [], 1), cv_all(:), 'UniformOutput', false);
    cv_mat = cat(2, tmp{:});   % [min_len x num_runs]
    cv_mean = mean(cv_mat,2);
    cv_sem  = std(cv_mat,0,2) / sqrt(size(cv_mat,2));

    % === GT curves from eval_metrics ===
    eval_metrics_gt = eval_lst{1,1,1};  % first seed, first labeler, first method
    if isfield(eval_metrics_gt, metric_name)
        gt_curve = eval_metrics_gt.(metric_name);
    else
        gt_curve = nan(min_len,1);
    end

    % X axis in %
    x_vals = linspace(0, 100*ratio, min_len);

    % === Plot ===
    subplot(3,2,m);
    hold on;

    % CV band
    fill([x_vals fliplr(x_vals)], ...
         [(cv_mean-cv_sem)' fliplr((cv_mean+cv_sem)')], ...
         col, 'FaceAlpha',0.2, 'EdgeColor','none');
    plot(x_vals, cv_mean, col, 'LineWidth', 2, 'DisplayName',['CV ' metric_name]);

    % GT line (majority vote only)
    plot(x_vals(1:length(gt_curve)), gt_curve, 'r--', 'LineWidth', 2, 'DisplayName','GT (majority)');

    % Baseline constant
    switch metric_name
        case 'ACC'
            yline(ACC_base,'k:','DisplayName','Human baseline');
        case 'TPR'
            yline(TPR_base,'k:','DisplayName','Human baseline');
        case 'TNR'
            yline(TNR_base,'k:','DisplayName','Human baseline');
    end

    xlabel('% of Cells Queried');
    ylabel(metric_name);
    ylim([0,1]); grid on;
    title([metric_name ': CV vs GT']);
    legend('Location','best');
    hold off;
end


