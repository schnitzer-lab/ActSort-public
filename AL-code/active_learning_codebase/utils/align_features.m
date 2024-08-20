function X_saligned = align_features(X_target, X_source)
% this function align the domain of X2 to X1
% [INPUT]
%   X1 : shape N1 x d, the feature matrix
%   X2 : shape N2 x d, the feature matrix
    
cov_source = cov(X_source) + eye(size(X_source, 2));
cov_target = cov(X_target) + eye(size(X_target, 2));
A_coral = cov_source^(-1/2)*cov_target^(1/2);
X_saligned = X_source * A_coral';
end