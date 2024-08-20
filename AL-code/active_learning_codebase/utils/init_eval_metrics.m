function [eval_metrics] = init_eval_metrics()
eval_metrics.ACC = [];
eval_metrics.TPR = [];
eval_metrics.TNR = [];

eval_metrics.Precision = [];
eval_metrics.Recall    = [];
eval_metrics.Fscore    = [];

eval_metrics.AUC = [];

eval_metrics.TP = [];
eval_metrics.FP = [];
eval_metrics.TN = [];
eval_metrics.FN = [];
eval_metrics.P  = [];
eval_metrics.N  = [];
eval_metrics.ACC_mean = [];
end