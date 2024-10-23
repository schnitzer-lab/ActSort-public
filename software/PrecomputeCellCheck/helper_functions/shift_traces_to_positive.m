function T_shifted = shift_traces_to_positive(T)
% This function shifts negative parts above the 0 and enforces neagtivity.
% This is useful for preparing the T for peak detection algorithm.
% T is assumed to be [trace x n_cell]

min_values = min(T, [], 1); % Find the minimum value for each column (cell)
shift_amounts = min(0, min_values);
T_shifted = T - shift_amounts; 
end