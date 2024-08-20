function [agreement] = sc_sp(curr_labels_ml, prev_labels_ml)
% This function return the quantity for stability prediction stopping
% criterion 
%
% INPUT
%   [curr_labels_ml] : N x 1 current ML labels {-1, 1}
%   [prev_labels_ml] : N x 1 previous ML labels {-1,1}
N = length(curr_labels_ml);
Ao = sum(curr_labels_ml == prev_labels_ml) / N;
prob_curr_labels_ml_cell = length(curr_labels_ml(curr_labels_ml==1)) / N;
prob_curr_labels_ml_notc = length(curr_labels_ml(curr_labels_ml==-1)) / N;
prob_prev_labels_ml_cell = length(prev_labels_ml(prev_labels_ml==1)) / N;
prob_prev_labels_ml_notc = length(prev_labels_ml(prev_labels_ml==-1)) / N;

Ae =  prob_curr_labels_ml_cell  * prob_prev_labels_ml_cell + prob_curr_labels_ml_notc * prob_prev_labels_ml_notc;

agreement = (Ao - Ae) / (1 - Ae);
