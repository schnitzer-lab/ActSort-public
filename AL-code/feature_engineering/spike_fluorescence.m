function metric = spike_fluorescence(T, threshold)
    if nargin < 2 || isempty(threshold)
        threshold = 99;
    end

    if ~isempty(threshold)
      threshold = threshold*100;
    end

    p_threshold = prctile(T, threshold, 2);
    
    filtered_T = zeros(size(T));
    for i = 1:size(T, 1)
        % Keep values that are greater than or equal to tunable 
        % percentile value for that row
        filtered_T(i, T(i, :) >= p_threshold(i)) = T(i, T(i, :) >= p_threshold(i));
    end

    cell_trace_sum = sum(filtered_T, 2);
    metric = cell_trace_sum;
end
