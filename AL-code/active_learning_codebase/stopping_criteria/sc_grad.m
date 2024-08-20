function [gradient] = sc_grad(curr_scores, prev_scores)
% This function return the quantity for stability prediction stopping
% criterion 
%
% INPUT
%   [curr_selections_probs] : W x 1 last W selected labels predicted probs
%   [prev_selections_probs] : W x 1 current W selected labels predicted probs

gradient = median(curr_scores) - median(prev_scores);