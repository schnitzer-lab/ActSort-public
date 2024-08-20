function [ou] = sc_ou(curr_labels_ml_prob)
% This function return the quantity for stability prediction stopping
% criterion 
%
% INPUT
%   [curr_labels_ml] : N x 1 current ML labels {-1, 1}
%   [prev_labels_ml] : N x 1 previous ML labels {-1,1}
N = length(curr_labels_ml_prob);
um = curr_labels_ml_prob .* log(curr_labels_ml_prob) +...
    (1 - curr_labels_ml_prob) .* log(1 - curr_labels_ml_prob);

ou = sum(um) / N;