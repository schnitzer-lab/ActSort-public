function [eval_metrics] = get_ex_accuracy(labels, labels_gt)
% This function calculate the evaluation metrics for individual human
% annotators. 
% INPUT
%   [labels] ： human annotator's labels (N x 1).
%   [labels_gt]: the concensus of other three annotators (N x 1).
% OUTPUT
%   [eval_metrics] evaluation metrics
%       - TPR
%       - TNR
%       - ACC 
%       - Precision
%       - Recall
%       - Fscore
TPR = mean(labels(labels_gt==1) == 1);
TNR = mean(labels(labels_gt==-1) == -1);
eval_metrics.TPR = TPR;
eval_metrics.TNR = TNR;
eval_metrics.ACC = (TPR + TNR) / 2; % mean(labels_exml == labels_gt);

TP = sum(labels(labels_gt==1) == 1);
FP = sum(labels(labels_gt==-1) == 1);
TN = sum(labels(labels_gt==-1) == -1);
FN = sum(labels(labels_gt==1) == -1);
P  = sum(labels_gt==1);
N  = sum(labels_gt==-1);

eval_metrics.Precision = TP / (TP + FP);
eval_metrics.Recall    = TP / (TP + FN);
eval_metrics.Fscore    = 2*TP / (2*TP + FP + FN);

% [fp_temp,tp_temp] = calculate_roc(labels_gt,labels);
% eval_metrics.AUC = trapz(fp_temp,tp_temp); 

eval_metrics.TP = TP;
eval_metrics.FP = FP;
eval_metrics.TN = TN;
eval_metrics.FN = FN;
eval_metrics.P  = P;
eval_metrics.N  = N;
eval_metrics.ACC_mean = mean(labels == labels_gt);
end