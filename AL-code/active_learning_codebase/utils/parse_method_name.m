function [config] = parse_method_name(method_name, config)
% Return the updated config for given [method_name]
% INPUT
%   [method_name]  : (str) the query algorithm method name, e.g., random,
%                     cal, dal, algo-rank, dcal-{weight}
%   [config]   configuration 
%       - zscore      : True or False (optional, default=True).
%       - balance     : Default=false.
%       - lam         : Classifier's regularization scale. Default 'auto'
%       - n           : number of queried samples for annotating.
%                                                           Default=1.
% OUTPUT
%   [method_name]  : (str)
if startsWith(method_name, 'dcal-')
    float_str = extractAfter(method_name, 'dcal-');
    method_name = 'dcal';
    weight = str2double(float_str);
    assert(weight>0 && weight<1, 'Please input dcal-{float} where float is between 0 and 1.')
end

switch method_name
    case {'random', 'cal', 'dal', 'algo-rank'}
        config.method_name = method_name;
        if isfield(config, 'weight')
            config = rmfield(config, 'weight');
        end
    case 'dcal'
        config.method_name = 'dcal';
        config.weight      = weight;
end