clear; clc;

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

method_lst = {'cal','random','algo-rank','dal','dcal-0.1','dcal-0.3','dcal-0.5','dcal-0.7','dcal-0.9'};
eval_lst = cell(1, length(method_lst));

for k = 1:length(method_lst)
    method_name = method_lst{k};
    fprintf("Running method %s\n", method_name)

    config.zscore = true;
    config.n = 1;
    [config] = parse_method_name(method_name, config);
    [dataset, method] = initialization(features, config);

    %% Initialize cell classifier
    for i = 1:dataset.num_datasets
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

    % Train classifier after initialization
    [dataset, method] = train_classifier(dataset, method);

    %% Start Active Learning
    num_cells = sum(cellfun(@(x) size(x, 1), dataset.features, 'UniformOutput', true));
    ratio = 0.5;
    stop_cell = floor(ratio * num_cells);
    p1percent_cell = floor(0.001 * num_cells);
    eval_metrics = init_eval_metrics();

    %% Perform PCA once on all features
    X = zscore(features{1});
    [coeff, score, latent] = pca(X);
    pca_coords = score(:, 1:2);
    gt_labels = labels_gt{1};
    x_limits = [min(pca_coords(:,1)) max(pca_coords(:,1))];
    y_limits = [min(pca_coords(:,2)) max(pca_coords(:,2))];

    %% Initialize GIF file
    gif_filename = sprintf('pca_progress_%s.gif', method_name);
    gif_delay = 0.4;

    for i = 1:stop_cell
        [q_idxs, scores, dataset] = step_al(dataset, method);
        data_id = q_idxs(1);
        cell_id = q_idxs(2);
        label = labels{data_id}(cell_id);
        dataset = annotate(dataset, q_idxs, label);
        [dataset, method] = train_classifier(dataset, method);

        % --- Create GIF every 100 steps or at end ---
        if mod(i, 100) == 0 || i == 1 || i == stop_cell
            labeled_mask = dataset.labels_ex{1} ~= 0;
            fig = figure('Visible', 'off', 'Position', [100 100 800 700], 'Color', 'w');
            hold on;

            % Unlabeled (gray)
            plot(pca_coords(~labeled_mask,1), pca_coords(~labeled_mask,2), 'o', ...
                'MarkerSize',3,'MarkerEdgeColor','none','MarkerFaceColor',[0.8 0.8 0.8]);

            % Labeled +1 (blue)
            plot(pca_coords(gt_labels==1 & labeled_mask,1), pca_coords(gt_labels==1 & labeled_mask,2), 'o', ...
                'MarkerSize',4,'MarkerEdgeColor','none','MarkerFaceColor',[0 0.45 0.74]);

            % Labeled -1 (red)
            plot(pca_coords(gt_labels==-1 & labeled_mask,1), pca_coords(gt_labels==-1 & labeled_mask,2), 'o', ...
                'MarkerSize',4,'MarkerEdgeColor','none','MarkerFaceColor',[0.85 0.33 0.1]);

            title(sprintf('PCA Projection – %s (Step %d / %d)', method_name, i, stop_cell));
            xlabel('PC1'); ylabel('PC2');
            xlim(x_limits); ylim(y_limits);
            axis equal; axis off; box on; drawnow;

            frame = getframe(fig);
            [A,map] = rgb2ind(frame2im(frame),256);
            if i == 1
                imwrite(A,map,gif_filename,'gif','LoopCount',inf,'DelayTime',gif_delay);
            else
                imwrite(A,map,gif_filename,'gif','WriteMode','append','DelayTime',gif_delay);
            end
            close(fig);
        end

        % --- Evaluate performance ---
        if i == 1 || mod(i, p1percent_cell) == 0
            eval_metrics = get_accuracy(dataset, labels_gt, eval_metrics);
        end
    end

    eval_lst{k} = eval_metrics;

    %% ===== Save Final PCA =====
    figure('Position',[100 100 800 700],'Color','w'); hold on;
    scatter(pca_coords(gt_labels==-1,1), pca_coords(gt_labels==-1,2), ...
        15, [0.85 0.33 0.1], 'filled', 'DisplayName', 'GT = -1');
    scatter(pca_coords(gt_labels==1,1), pca_coords(gt_labels==1,2), ...
        15, [0 0.45 0.74], 'filled', 'DisplayName', 'GT = +1');
    explainedVar = 100 * latent(1:2) / sum(latent);
    xlabel(sprintf('PC1 (%.1f%%)', explainedVar(1)));
    ylabel(sprintf('PC2 (%.1f%%)', explainedVar(2)));
    title(sprintf('Final PCA – %s', method_name));
    legend('Location','bestoutside');
    xlim(x_limits); ylim(y_limits);
    axis equal; box on; grid on;
    saveas(gcf, sprintf('final_pca_%s.png', method_name));
    close(gcf);
end

fprintf('\nAll GIFs and PCA plots saved successfully!\n');