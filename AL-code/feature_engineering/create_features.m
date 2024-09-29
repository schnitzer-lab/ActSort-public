function [features, time_summary] = create_features(precomputedOutput, parforFlag, fastFeatureFlag)
    % This function create training samples with hard-coded features
% INPUT
%   [precomputedOutput] : a struct that is obtained from the precomputation code
%   [parforFlag]        : logical flag to enable parallel processing.
%   [fastFeatureFlag]   : logical flag to enable fast feature calculation by
%                         omitting some features.
%
% OUTPUT
%   [features]          : a matrix of size (n_cell x feature_size). 
%

    [S, T, M_cell, T_cell, S_cell] = parse_precomputed_output(precomputedOutput);
    [features, time_summary] = get_features(S, T, M_cell, S_cell, T_cell, parforFlag, fastFeatureFlag);
    % Replace all nans with mean values
    features = replace_infs_with_zeros(features);
    features = replace_nans_with_mean(features);
end