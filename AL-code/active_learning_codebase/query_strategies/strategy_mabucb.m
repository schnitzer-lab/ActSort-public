function [q_idxs, scores] = strategy_mabucb(dataset, n, mdl)
alpha = dataset.alpha;
N = size(dataset.features, 1);

[~, probs] = predict(mdl, dataset.features);
probs = probs(:,2);

ucb_scores = zeros(1, N);
for i = 1:N
    if dataset.labels_ex(i) == 0
        ucb_scores(i) = probs(i) + alpha * sqrt(log(sum(dataset.labels_ex~=0))/2);
    end
end
[scores, q_idxs] = max(ucb_scores);
end