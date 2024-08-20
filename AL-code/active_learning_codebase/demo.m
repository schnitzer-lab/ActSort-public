% This is a demo file. It shows the general idea of the pipeline
clear;clc;

rng(54135)

load('yang_m1_features.mat')
load('yang_m1_mbp_labels.mat')

features  = metrics';
labels_gt = choices';
clear metics choices;

N = size(features, 1);

config.DO_ZSCORING = true;
config.n = 1;
methods = {'random', 'cal', 'algo-rank', 'dal','multi-arm', 'dcal'};
colors  = {"#A2142F", "#7E2F8E", "#0072BD", "#EDB120", "#77AC30", "#FF00FF"};
n = config.n;

stop_cell = round(ratio*num_cells);

for k=1:length(methods)
    method = methods{k}

    dataset = initialization(features, config);
%     q_idxs  = step(dataset, n, nan, 'random');
%     dataset.labels_ex(q_idxs) = labels_gt(q_idxs);
    %%%%%%%%%%%%%%%%
    %%% multi-arm bandit algorithm
    dataset.wt = ones(N,1);
    dataset.gamma = 0.6;
    dataset.reward_func = @(tp, tn, fp, fn) ((0.3*(tp / (tp + fn)) + 0.7*(tn / (fp + tn))) / 2); % user can define the reward function in multi-arm bandit
    %%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%
    %%% dcal algorithm
    [method, dataset] = parse_dcal(method, dataset);
    %%%%%%%%%%%%%%%%
    q_iscells = find(labels_gt==1,5);
    q_nocells = find(labels_gt==-1,5);
    dataset.labels_ex(q_iscells) = labels_gt(q_iscells);
    dataset.labels_ex(q_nocells) = labels_gt(q_nocells);

    [dataset, mdl] = train_classifier(dataset);

    accs    = [];
    accs_tp = [];
    accs_tn = [];
    precisions = [];
    recalls    = [];
    fscores    = [];

    prev_labels_ml = dataset.labels_ml;
%     sc_sps   = [];
% %     prev_scores = 0;
% %     sc_grads = [];
%     sc_ous = [];
    for i=11:600
        if mod(i, 100)==0
            i
        end
        % select next data to be labeled
        [q_idxs, scores, dataset] = step_al(dataset, n, mdl, method);
        % label the data
        label = labels_gt(q_idxs);
        % add the label to the training dataset
        dataset = annotate(dataset, q_idxs, label);
        % train the classifier
        [dataset, mdl] = train_classifier(dataset);
        
        % stopping criteria SP
%         curr_labels_ml = dataset.labels_ml;
%         agreement      = sc_sp(curr_labels_ml, prev_labels_ml);
%         sc_sps         = [sc_sps, agreement];
%         prev_labels_ml = curr_labels_ml;
%         % stopping criteria GRAD
% %         curr_scores = scores;
% %         grad        = sc_grad(curr_scores, prev_scores);
% %         sc_grads    = [sc_grads, grad];
% %         prev_scores = curr_scores;
%         % stopping criteria OU
%         curr_labels_ml_prob = dataset.labels_ml_prob;
%         ou = sc_ou(curr_labels_ml_prob);
%         sc_ous = [sc_ous, ou];

        eval_metrics = get_accuracy(dataset, labels_gt);
        accs    = [accs,eval_metrics.ACC];
        accs_tp = [accs_tp, eval_metrics.TPR];
        accs_tn = [accs_tn, eval_metrics.TNR];
        precisions = [precisions, eval_metrics.Precision];
        recalls    = [recalls, eval_metrics.Recall];
        fscores    = [fscores, eval_metrics.Fscore];
    end
%     sc_sps_smoothed   = smoothdata(sc_sps, 'movmean', 20);
% %     sc_grads_smoothed = sc_grads;
%     sc_ous_smoothed   = smoothdata(sc_ous, 'movmean', 20);
%     
    color = colors{k};
    figure(1)
    plot(accs, 'LineWidth',2, 'Color',color, 'DisplayName',method)
    hold on
%     plot(sc_ous_smoothed, 'LineWidth',2, 'LineStyle',':', 'Color',color, 'DisplayName',['SC-SP-',method])
%     hold on
    figure(2)
    plot(accs_tp, 'LineWidth',2,'Color',color, 'DisplayName',method)
    hold on
    figure(3)
    plot(accs_tn, 'LineWidth',2,'Color',color, 'DisplayName',method)
    hold on
    figure(4)
    plot(precisions, 'LineWidth',2,'Color',color, 'DisplayName',method)
    hold on
%     plot(sc_ous_smoothed, 'LineWidth',2, 'LineStyle',':', 'Color',color, 'DisplayName',['SC-SP-',method])
%     hold on
    figure(5)
    plot(recalls, 'LineWidth',2,'Color',color, 'DisplayName',method)
    hold on
%     plot(sc_ous_smoothed, 'LineWidth',2, 'LineStyle',':', 'Color',color, 'DisplayName',['SC-SP-',method])
%     hold on
    figure(6)
    plot(fscores, 'LineWidth',2,'Color',color, 'DisplayName',method)
    hold on
%     plot(sc_ous_smoothed, 'LineWidth',2, 'LineStyle',':', 'Color',color, 'DisplayName',['SC-SP-',method])
%     hold on
end
figure(1)
title('Accuracy')
xlabel('# of cells')
hold off
legend()
figure(2)
title('True Positive Rate')
xlabel('# of cells')
hold off
legend()
figure(3)
title('True Negative Rate')
xlabel('# of cells')
hold off
legend()
figure(4)
title('Precision')
xlabel('# of cells')
hold off
legend()
figure(5)
title('Recall')
xlabel('# of cells')
hold off 
legend()
figure(6)
title('F score')
xlabel('# of cells')
hold off
legend()
function [method, dataset] = parse_dcal(method, dataset)
    parts = split(method, "-");
    if strcmpi(parts(1), "dcal")
        dataset.weight = str2double(parts(2));
        method = "dcal";
    end
end
function [eval_metrics] = get_accuracy(dataset, labels_gt)
unlabeled_idxs = find(dataset.labels_ex==0);
labels_exml = dataset.labels_ex(:);
labels_exml(unlabeled_idxs) = dataset.labels_ml(unlabeled_idxs);

eval_metrics.ACC = mean(labels_exml == labels_gt);
eval_metrics.TPR = mean(labels_exml(labels_gt==1) == 1);
eval_metrics.TNR = mean(labels_exml(labels_gt==-1) == -1);

TP = sum(labels_exml(labels_gt==1) == 1);
FP = sum(labels_exml(labels_gt==-1) == 1);
TN = sum(labels_exml(labels_gt==-1) == -1);
FN = sum(labels_exml(labels_gt==1) == -1);
P = sum(labels_gt==1);
N = sum(labels_gt==-1);

eval_metrics.Precision = TP / (TP + FP);
eval_metrics.Recall    = TP / (TP + FN);
eval_metrics.Fscore    = 2*TP / (2*TP + FP + FN);
end