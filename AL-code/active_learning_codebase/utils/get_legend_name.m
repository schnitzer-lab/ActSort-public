function legend_name = get_legend_name(method)
% Return the legend name for each method including its hyperparameters
% [INPUT]
%   [method]     : query algorithm (struct)
%       - name : [random, algo-rank, cal, dcal, multi-arm] (string) 
%       - (algorithm specific params)
%           -- dcal      : weight
%           -- multi-arm : wt, gamma, reward_func

switch method.name
    case 'random'
        legend_name = method.name;
    case 'algo-rank'
        legend_name = method.name;
    case 'cal'
        legend_name = method.name;
    case 'dal'
        legend_name = method.name;
    case 'dcal'
        legend_name = strcat(method.name, '-', num2str(method.weight));
    case 'dal-entropy'
        legend_name = method.name;
    case 'mab-exp3'
        legend_name = strcat(method.name, '-', num2str(method.gamma), '-', method.reward_name);
    case 'mab-ucb'
        legend_name = strcat(method.name, '-', num2str(method.alpha));
end