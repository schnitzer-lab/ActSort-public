function [preds, w] = ml_predict_dal(features, labels, do_zscoring)
    if nargin < 3 || isempty(do_zscoring)
        do_zscoring = false;
    end
    
    if do_zscoring
        % replace infs with 0s
        infs = isinf(features);
        features(infs) = 0;
        features = zscore(features, 0, 1);
        features(infs) = 0;
    end

    mdl = fitclinear(features, labels, ...
        'learner', 'logistic', 'regularization', 'lasso',...
         'ClassNames', [0, 1], 'Prior', 'empirical');
    [~, preds] = predict(mdl, features);
    preds = preds(:, 2);
    w = mdl.Beta;
%     w = zeros(size(features, 2) + 1, 1);
end