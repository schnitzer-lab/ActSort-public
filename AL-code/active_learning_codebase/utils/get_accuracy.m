function [eval_metrics] = get_accuracy(dataset, labels_gt, eval_metrics)
% update the eval_metrics for current time-step
% [INPUT]
%   [dataset] a structure that contain fields
%       - features : N x d
%       - labels_ex : N x 1 human / expert labels
%       - labels_ml : N x 1 cell classifier / ML labels 

% unlabeled_idxs = find(dataset.labels_ex==0);
% labels_exml = dataset.labels_ex(:);
% labels_exml(unlabeled_idxs) = dataset.labels_ml(unlabeled_idxs);
labels_exml = dataset.labels_ml;
TPR = mean(labels_exml(labels_gt==1) == 1);
TNR = mean(labels_exml(labels_gt==-1) == -1);
eval_metrics.TPR(end+1) = TPR;
eval_metrics.TNR(end+1) = TNR;
eval_metrics.ACC(end+1) = (TPR + TNR) / 2; % mean(labels_exml == labels_gt);

TP = sum(labels_exml(labels_gt==1) == 1);
FP = sum(labels_exml(labels_gt==-1) == 1);
TN = sum(labels_exml(labels_gt==-1) == -1);
FN = sum(labels_exml(labels_gt==1) == -1);
P  = sum(labels_gt==1);
N  = sum(labels_gt==-1);

eval_metrics.Precision(end+1) = TP / (TP + FP);
eval_metrics.Recall(end+1)    = TP / (TP + FN);
eval_metrics.Fscore(end+1)    = 2*TP / (2*TP + FP + FN);

[fp_temp,tp_temp] = calculate_roc(labels_gt,dataset.labels_ml_prob);
eval_metrics.AUC(end+1) = trapz(fp_temp,tp_temp); 

eval_metrics.TP(end+1) = TP;
eval_metrics.FP(end+1) = FP;
eval_metrics.TN(end+1) = TN;
eval_metrics.FN(end+1) = FN;
eval_metrics.P(end+1)  = P;
eval_metrics.N(end+1)  = N;
eval_metrics.ACC_mean(end+1) = mean(labels_exml == labels_gt);
end