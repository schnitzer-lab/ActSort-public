%Stopping Criteria
function [avg_accuracy,cv_TPR, cv_TNR, avg_Precision, avg_Recall] = cross_val_on_labeled(dataset,k)
% Get labeled indices
labeled_idx = find(dataset.labels_ex{1} ~= 0);
X = dataset.features{1}(labeled_idx, :); % TODO: this need to be fixed for batch processing
y = dataset.labels_ex{1}(labeled_idx);   % TODO: this need to be fixed for batch processing
lam = dataset.mdl.Lambda;

if numel(unique(y)) == 1
    if all(y == 1)
        % 只有 cell，没有 not-cell
        cv = cvpartition(length(y), 'KFold', min(k,length(y)));
        TPR = zeros(cv.NumTestSets,1);
        for i = 1:cv.NumTestSets
            trainIdx = training(cv,i);
            testIdx  = test(cv,i);
            XTrain = X(trainIdx,:);
            yTrain = y(trainIdx,:);
            XTest  = X(testIdx,:);
            yTest  = y(testIdx,:);
            mdl = fitclinear(XTrain,yTrain,'Learner','logistic',...
                'Regularization','lasso','ClassNames',[1],...
                'Lambda',lam);
            predictions = predict(mdl,XTest);
            TPR(i) = mean(predictions==yTest); % only TPR meaningful
        end
        avg_TPR = mean(TPR);
        avg_TNR = NaN;
        avg_acc = avg_TPR; % fallback: BA = TPR
        return;
    elseif all(y == -1)
        % 只有 not-cell，没有 cell
        cv = cvpartition(length(y), 'KFold', min(k,length(y)));
        TNR = zeros(cv.NumTestSets,1);
        for i = 1:cv.NumTestSets
            trainIdx = training(cv,i);
            testIdx  = test(cv,i);
            XTrain = X(trainIdx,:);
            yTrain = y(trainIdx,:);
            XTest  = X(testIdx,:);
            yTest  = y(testIdx,:);
            mdl = fitclinear(XTrain,yTrain,'Learner','logistic',...
                'Regularization','lasso','ClassNames',[-1],...
                'Lambda',lam);
            predictions = predict(mdl,XTest);
            TNR(i) = mean(predictions==yTest); % only TNR meaningful
        end
        avg_TNR = mean(TNR);
        avg_TPR = NaN;
        avg_acc = avg_TNR; % fallback: BA = TNR
        return;
    end
end
% Set up k-fold cross-validation
cv = cvpartition(length(y), 'KFold', k);
TPR = zeros(k, 1);
TPN = zeros(k, 1);



for i = 1:k
    trainIdx = training(cv, i);
    testIdx = test(cv, i);
    
    % Split the data into training and test sets for this fold
    XTrain = X(trainIdx, :);
    yTrain = y(trainIdx, :);
    XTest = X(testIdx, :);
    yTest = y(testIdx, :);
    
    % Train the model on the training set
    mdl = fitclinear(XTrain, yTrain, ...
            'learner', 'logistic', 'regularization', 'lasso',...
             'ClassNames', [-1, 1], 'Prior', 'empirical','Lambda',lam);
    
    % Test the model on the test set
    predictions = predict(mdl, XTest);
    
    % Calculate accuracy for the current fold
    % FIXME: change to TPR and TNR
    TP = sum((yTest == 1) & (predictions == 1));
    FN = sum((yTest == 1) & (predictions == -1));
    TN = sum((yTest == -1) & (predictions == -1));
    FP = sum((yTest == -1) & (predictions == 1));
    Precision = TP / (TP+FP);
    Recall    = TP / (TP+FN); 

    TPR(i) = TP / (TP + FN);
    TNR(i) = TN / (TN + FP);

    fprintf('Fold %d TPR: %.2f%%, TNR: %.2f%%\n', i, 100 * TPR(i), 100 * TNR(i));
end

% Return average accuracy
% FIXME: change to TPR and TNR
cv_TPR = nanmean(TPR);
cv_TNR = nanmean(TNR);
avg_Precision = nanmean(Precision);
avg_Recall    = nanmean(Recall);
avg_accuracy  = nanmean([cv_TPR, cv_TNR]);

fprintf('5-Fold CV Balanced Accuracy: TPR = %.2f%%, TNR = %.2f%%, Avg Acc = %.2f%%\n', ...
    100 * cv_TPR, 100 * cv_TNR, 100 * avg_accuracy);
end


