classdef method
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        weight
        continue_sorting
        balance
        balance_ratio
        balance_ratio_decay
        balance_pretrained
        cls_threshold
        threshold
        lam
        n
    end
    
    methods
        function obj = method(config)
            obj.name                = config.method_name;
            obj.weight              = config.weight;
            obj.continue_sorting    = config.continue_sorting;            
            obj.balance             = config.balance;
            obj.lam                 = config.lam;
            obj.n                   = config.n;
            obj.cls_threshold       = config.cls_threshold;
            obj.balance_ratio       = config.balance_ratio;
            obj.balance_ratio_decay = config.balance_ratio_decay;
            obj.balance_pretrained  = config.balance_pretrained;

            if obj.continue_sorting
                obj.threshold       = -1; % throw away the least certain sample from the pretrained dataset
            else
                obj.threshold       = [];
            end
        end

        function obj = update_method(obj, new_config)
            obj.name = new_config.method_name;
            obj.weight = new_config.weight;
            obj.cls_threshold = new_config.cls_threshold;
        end
    end
end

