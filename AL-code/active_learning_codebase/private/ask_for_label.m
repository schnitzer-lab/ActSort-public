function [idx_active_label, preds, mdl,w] = ...
    ask_for_label(features, labels, ml_labels, varargin)

    method = 'min_conf';
    lam = "auto";
%     do_zscoring = true;
    
    if ~isempty(varargin)
        for k = 1:length(varargin)
            vararg = varargin{k};
            if ischar(vararg)
                switch lower(vararg)
                    case 'method'
                        method = varargin{k+1};
                    case 'distances'
                        D = varargin{k+1};
                    case 'normalize'
                        do_zscoring = varargin{k+1};
                    case 'lam'
                        lam = varargin{k+1};
                end
            end
        end
    end
    
    n = size(features, 1);

    % Train classifier to get predictions
    [preds, mdl,w] = ...
        ml_predict_labels(features, ml_labels,lam);
    

    competences = preds;
    confidences = abs(preds - 0.5);
    confidences(labels ~= 0) = inf;

    if strcmpi(method, 'min_conf')
        [~, idx_active_label] = min(confidences);
    elseif strcmpi(method, 'algo_rank')
        ind = find(confidences < inf);
        idx_active_label = ind(1);
    elseif strcmpi(method, 'dal')
        conf_labels = (ml_labels ~= 0);
        [preds_conf, ~] = ...
        ml_predict_dal(features, conf_labels);
        preds_conf(labels ~= 0) = inf;
        [~, idx_active_label] = min(preds_conf);
    elseif strcmpi(method, 'dal_entropy')
        conf_labels = (ml_labels ~= 0);
        [preds_conf, ~] = ...
        ml_predict_dal(features, conf_labels);
        preds_conf = abs(preds_conf - 0.5);
        preds_conf(labels ~= 0) = inf;
        [~, idx_active_label] = min(preds_conf);
    elseif strcmpi(method, 'random')
        idx_active_label = randsample(find(confidences < inf), 1);
    end
    

end
