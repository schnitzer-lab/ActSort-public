function [dataset_obj, method_obj] = initialization(features, config, pretrained)
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
    features = zscore(features, 0, 1);
end

if isstruct(config)
    if ~isfield(config, "method_name"); config.method_name = "dcal-0.7"; end
    if ~isfield(config, "weight"); config.weight = NaN; end
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

method_obj = al_class_package.method(config); 
dataset_obj = al_class_package.dataset(features, pretrained); 
end