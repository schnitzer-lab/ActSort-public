classdef dataset
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        num_datasets % the number of datasets included in this dataset structure
        features  % a cell that include multiple features from different datasets
        labels_ex % a cell that include expert labels from different datasets
        labels_ml % a cell that include classifier's predicted labels for different datasets
        labels_ml_prob % a cell that include classifier's predicted probablity for different datasets
        q_idx_lst      % a 2-D array where the first entry is the dataset_id and the second entry is query_id (the corresponding cell id)
        sorting_order  % a 2-D array where the first entry is the dataset_id and the second entry is the cell id that is being sorted by the user.  
        pretrained     % one dataset structure that include one mdl inside. 
        mdl            % the classifier model
        INFO
    end
    
    methods
        function obj = dataset(features_lst, pretrained)
            assert(obj.num_datasets == numel(features_lst), ...
                'Assertion failed: obj.num_datasets (%d) does not match numel(features_lst) (%d).', ...
                obj.num_datasets, numel(features_lst));
            for i = 1:num_datasets  
                features   = features_lst{i};

                N = size(features, 1);
                matrix = zeros(N, 1); % label = 1 if is cell, = 0 if not labeled, = -1 if not cell
    
                obj.features{i}       = features;
                obj.labels_ex{i}      = matrix; % expert / human labels
                obj.labels_ml{i}      = matrix; % cell classifier / ML labels
                obj.labels_ml_prob{i} = matrix; % probability associated with ml_labels of being a cell      
            end
            obj.q_idx_lst      = [NaN, NaN]; % query cells indices (based on the EXTRACT output indices)
            obj.sorting_order  = [NaN, NaN];
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

        function obj = update_sorting_order(obj, q_idxs)
            cell_idx    = q_idxs(1);
            dataset_idx = q_idxs(2);
            order = obj.sorting_order(:,:);  % Ensure sorting_order is a row vector
            row_to_find = [dataset_idx, cell_idx];
            is_row_present = ismember(order', row_to_find', 'rows');
            if any(is_row_present)
                obj.order(:, is_row_present) = []; % Remove the row
            end
            order = [order, row_to_find'];
            obj.sorting_order = order;  
        end

        function stats = get_expert_stats(obj)
            stats = cell(1, obj.num_datasets);
            for i=1:obj.num_datasets
                % Cell Stats based on expert annotations
                num_good = sum(obj.labels_ex{i} == 1);
                num_bad = sum(obj.labels_ex{i} == -1);  
                num_unlabeled = sum(obj.labels_ex{i} == 0);  
                stats{i} = [num_good, num_bad, num_unlabeled];
            end
        end
        
        function stats = get_model_stats(obj)
            stats = cell(1, obj.num_datasets);
            for i=1:obj.num_datasets
                % Cell Stats based on model decisions
                num_good = sum(obj.labels_ml{i} == 1);
                num_bad = sum(obj.labels_ml{i} == -1);
                num_unlabeled = sum(obj.labels_ml{i} == 0);
                stats{i} = [num_good, num_bad, num_unlabeled];
            end
        end

        function stats = get_overall_stats(obj)
            [~, stats] = predict_rest(obj); % cell of N x 1
        end

        function update_INFO(obj, extract_name_lst, h5_name_lst, downsample_rate)
            obj.INFO.extract_file_names = extract_name_lst;
            obj.INFO.h5_file_names      = h5_name_lst;
            obj.INFO.downsample_rate    = downsample_rate;
            obj.INFO.data_created       = datetime('now');
            obj.INFO.cpu                = computer('arch');
        end

    end
end

