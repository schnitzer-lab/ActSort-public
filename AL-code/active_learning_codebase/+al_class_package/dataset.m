classdef dataset
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        features
        labels_ex
        labels_ml
        labels_ml_prob
        q_idx_lst
        sorting_order
        pretrained
        mdl
        INFO
    end
    
    methods
        function obj = dataset(features, pretrained)
            N = size(features, 1);
            matrix = zeros(N, 1); % label = 1 if is cell, = 0 if not labeled, = -1 if not cell

            obj.features       = features;
            obj.labels_ex      = matrix; % expert / human labels
            obj.labels_ml      = matrix; % cell classifier / ML labels
            obj.labels_ml_prob = matrix; % probability associated with ml_labels of being a cell
            obj.q_idx_lst      = []; % query cells indices (based on the EXTRACT output indices)
            obj.sorting_order  = [];
            obj.pretrained     = pretrained;

            if isempty(pretrained)
                obj.mdl = [];
            else
                obj.mdl = pretrained.mdl;
            end
        end

        function obj = add_info(obj, info_struct)
            obj.INFO = info_struct;
        end

        function obj = update_sorting_order(obj, idx)
            order = obj.sorting_order(:)';  % Ensure sorting_order is a row vector
            order(ismember(order, idx)) = [];  
            order = [order, idx(:)'];  
            obj.sorting_order = order;  
        end

        function stats = get_expert_stats(obj)
            % Cell Stats based on expert annotations
            num_good = sum(obj.labels_ex == 1);
            num_bad = sum(obj.labels_ex == -1);  
            num_unlabeled = sum(obj.labels_ex == 0);  
            stats = [num_good, num_bad, num_unlabeled];
        end
        
        function stats = get_model_stats(obj)
            % Cell Stats based on model decisions
            num_good = sum(obj.labels_ml == 1);
            num_bad = sum(obj.labels_ml == -1);
            num_unlabeled = sum(obj.labels_ml == 0);
            stats = [num_good, num_bad, num_unlabeled];
        end

        function stats = get_overall_stats(obj)
            % Cell Stats mixed with expert annotations and model decisions
            labels = predict_rest(obj);
            numGood = sum(labels == 1);
            numBad = sum(labels == -1);
            numUnlabeled = sum(labels == 0);
            stats = [numGood, numBad, numUnlabeled];
        end

    end
end

