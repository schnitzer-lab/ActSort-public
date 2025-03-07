function [dataset, method] = initialization(features, config, pretrained)
% INPUT
%   [features] N x d.
%   [config]   configuration object
%   [pretrained]   pretrained dataset (optional). Speficied if fine-tuning.
%
% OUTPUT
%   [dataset] a dataset object that contains necessary elements for AL
%   [method] the active learning query method

%% Initialize the dataset and method
if config.zscore
    features = cellfun(@(x) zscore(x, 0, 1), features, 'UniformOutput', false);
end

if isstruct(config)
    if ~isfield(config, "zscore"); config.zscore = true; end
    if ~isfield(config, "n"); config.n = 1; end
    if ~isfield(config, "method_name"); config.method_name = "dcal"; end
    if ~ismember(config.method_name, ["dal", "cal", "algo-rank", "linear"])
        if ~isfield(config, "weight"); config.weight = 0.7; end
    end
    if ~isfield(config, "continue_sorting"); config.continue_sorting = false; end
    if ~isfield(config, "lam"); config.lam = "auto"; end
    if ~isfield(config, "balance_ratio"); config.balance_ratio = 1; end
    if ~isfield(config, "balance_ratio_decay"); config.balance_ratio_decay = 1; end
    if ~isfield(config, "cls_threshold"); config.cls_threshold = 0.65; end
    if ~isfield(config, "balance"); config.balance = false; end
    if ~config.balance
        if ~isfield(config, "balance_pretrained"); config.balance_pretrained = NaN; end
    else
        if ~isfield(config, "balance_pretrained"); config.balance_pretrained = false; end
    end
end

if nargin < 3
    pretrained = [];
end

method = al_class_package.method(config); 
dataset = al_class_package.dataset(features, pretrained); 
end