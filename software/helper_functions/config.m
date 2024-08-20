classdef config
    properties
        zscore
        method_name
        weight
        balance
        balance_ratio
        balance_ratio_decay
        balance_pretrained
        cls_threshold
        continue_sorting
        lam
        n
    end
    
    methods
        function obj = config(varargin)
            % Create an input parser object
            p = inputParser;
            
            % Define the parameters and their default values
            addParameter(p, 'zscore', true); % ALWAYS TRUE
            addParameter(p, 'method_name', 'dcal'); % {'random', 'cal', 'dal', 'dcal'} [CAN BE CHANGED WHILE SORTING]
            addParameter(p, 'weight', 0.5); % between 0-1 [CAN BE CHANGED WHILE SORTING]
            addParameter(p, 'balance', false); % ALWAYS FALSE
            addParameter(p, 'balance_ratio', 1); % ALWAYS 1
            addParameter(p, 'balance_ratio_decay', 1); % ALWAYS 1
            addParameter(p, 'balance_pretrained', false); % {true, false}, only if a pretrained model is present [ASK HUMAN AT BEGINNING]
            addParameter(p, 'lam', 'auto');  % ALWAYS AUTO 
            addParameter(p, 'n', 1); % ALWAYS 1
            addParameter(p, 'cls_threshold', 0.65); % between 0-1 [CAN BE CHANGED WHILE SORTING]
            addParameter(p, 'continue_sorting', false); % 0 if training from scartch, 1 if pretrained
            
            % Parse the input arguments
            parse(p, varargin{:});
            
            % Assign the parsed values to the object properties
            obj.zscore = p.Results.zscore;
            obj.method_name = p.Results.method_name;
            obj.continue_sorting = p.Results.continue_sorting;
            
            % Assign weight only if method_name is 'dcal'
            if strcmp(obj.method_name, 'dcal')
                obj.weight = p.Results.weight;
            else
                obj.weight = [];
            end
            
            % Assign balance-related properties
            obj.balance = p.Results.balance;
            if obj.balance
                obj.balance_ratio = p.Results.balance_ratio;
                obj.balance_ratio_decay = p.Results.balance_ratio_decay;
            else
                obj.balance_ratio = [];
                obj.balance_ratio_decay = [];
            end
            
            % Assign balance_pretrained if continuing from a pretrained model
            if obj.continue_sorting
                obj.balance_pretrained = p.Results.balance_pretrained;
            else
                obj.balance_pretrained = [];
            end
            
            obj.lam = p.Results.lam;
            obj.n = p.Results.n;
            obj.cls_threshold = p.Results.cls_threshold;
        end

        function obj = update_method_name(obj, new_method_name, weight)
            obj.method_name = new_method_name;
            if strcmp(obj.method_name, 'dcal')
                obj.weight = weight;
            else
                obj.weight = [];
            end
        end
    end
end