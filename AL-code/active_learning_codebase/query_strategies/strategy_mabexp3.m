function [q_idxs, scores, dataset] = strategy_mabexp3(dataset, n, mdl)
% Active learning query strategy 
% Output selected query indices [q_idxs] for the unlabeled training dataset
% i.e., [dataset.features[~labeled_idxs,:]]. 
% Update the [dataset] with [dataset.labeled_idxs]
wt    = dataset.wt;
gamma = dataset.gamma;
reward_func = dataset.reward_func;
N = size(dataset.features,1);
%%%%%%%%%%%%%%%%%%% SAMPLE %%%%%%%%%%%%%%%%%%%
% Note: we do not sample the labeled ones
p = (1-gamma) .* wt ./ (sum(wt)) + gamma / N;
p(dataset.labels_ex ~= 0) = 0;
q_idxs = randsample(N,n,true,p);
%%%% CALCULATE THE REWARD BASED ON STATISTICS %%%%
preds = dataset.labels_ml;

labeled_idxs   = (dataset.labels_ex ~= 0);
labeled = dataset.labels_ex(labeled_idxs);
preds    = preds(labeled_idxs);

TP = sum(preds(labeled==1) == 1);
FP = sum(preds(labeled==-1) == 1);
TN = sum(preds(labeled==-1) == -1);
FN = sum(preds(labeled==1) == -1);
fscore   = 2*TP / (2*TP + FP + FN);
accuracy = mean(preds == labeled);
tpr = mean(preds(labeled==1) == 1);
tnr = mean(preds(labeled==-1) == -1);
%%%%%%%%%%%% CALCULATE CAL AND DAL %%%%%%%%%%%%
[~, probs] = predict(mdl, dataset.features(q_idxs,:));

cal_score = 1-2*abs(probs(2)-0.5);

labeled_idxs   = (dataset.labels_ex ~= 0);
Xbc = dataset.features;
ybc = (labeled_idxs);
bc_mdl = fitclinear(Xbc, ybc, ...
        'Learner', 'logistic', 'regularization', 'lasso',...
        'ClassNames', [0, 1], 'Prior', 'empirical');        
% select
[~, probs] = predict(bc_mdl, dataset.features(q_idxs,:));
dal_score = probs(1);
%%%%%%%%%%%% CALCULAT ASSOCIATE REWARD %%%%%%%%%%%%
reward = reward_func(TP, TN, FP, FN, cal_score, dal_score); %(0.3*tpr + 0.7*tnr) / 2;

wt(q_idxs) = wt(q_idxs) * exp(gamma * reward / p(q_idxs)/N);

dataset.wt = wt;
scores = reward;