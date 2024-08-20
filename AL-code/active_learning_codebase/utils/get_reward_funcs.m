function [reward_func_lst, reward_name_lst] = get_reward_funcs(select_idxs)
% Return a reward function list that include the first k functions defined
% here
% [INPUT]
%   [select_idxs] : the selected function indices (array). Return all if
%                   empty.
% [OUTPUT]
%   [reward_func_lst] : a list of reward function that takes in (tp, tn,
%                       fp, fn) and output a value between 0 and 1. 
%                       (cell of function 1 x k)
%   [reward_name_lst] : a list of the associate reward name (string array 1 x k)

% cal
func1 = @(tp, tn, fp, fn, cal_score, dal_score) (cal_score);
% dal
func2 = @(tp, tn, fp, fn, cal_score, dal_score) (dal_score);
% 0.3 * dal + 0.7 * cal
func3 = @(tp, tn, fp, fn, cal_score, dal_score) (0.3*dal_score + 0.7*cal_score);
% 0.5 * dal + 0.5 * cal
func4 = @(tp, tn, fp, fn, cal_score, dal_score) (0.5*dal_score + 0.5*cal_score);
% 0.7 * dal + 0.3 * cal
func5 = @(tp, tn, fp, fn, cal_score, dal_score) (0.7*dal_score + 0.3*cal_score);
% 0.5 * TPR + 0.5 * TNR
func6 = @(tp, tn, fp, fn, cal_score, dal_score) (0.5*(tp / (tp + fn)) + 0.5*(tn / (fp + tn)));
% 0.2 * TPR + 0.8 * TNR
func7 = @(tp, tn, fp, fn, cal_score, dal_score) (0.2*(tp / (tp + fn)) + 0.8*(tn / (fp + tn)));
% precision
func8 = @(tp, tn, fp, fn, cal_score, dal_score) (tp / (tp + fp));
% recall
func9 = @(tp, tn, fp, fn, cal_score, dal_score) (tp / (tp + fn));
% fscore
func10 = @(tp, tn, fp, fn, cal_score, dal_score) (2*tp / (2*tp + fp + fn));
% TNR
func11 = @(tp, tn, fp, fn, cal_score, dal_score) (tn / (fp + tn));
% TPR
func12 =  @(tp, tn, fp, fn, cal_score, dal_score) (tp / (tp + fn));

reward_func_lst = {func1, func2, func3, func4, func5, func6, func7, func8, func9, func10, func11, func12};
reward_name_lst = ["CAL", "DAL", "0.3DAL+0.7CAL", "0.5DAL+0.5CAL", "0.7DAL+0.3CAL", "0.5TPR+0.5TNP", "0.2TPR+0.8TNR", "precision", "recall", "fscore", "TNR", "TPR"];

assert(length(reward_func_lst) == length(reward_name_lst), 'reward function list and reward name list have different length')


if length(select_idxs) == 1
    reward_func_lst = {reward_func_lst{select_idxs}};
    reward_name_lst = [reward_name_lst(select_idxs)];
elseif ~isempty(select_idxs)
    reward_func_lst = {reward_func_lst{select_idxs}};
    reward_name_lst = reward_name_lst(select_idxs);
end
end