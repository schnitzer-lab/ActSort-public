function cell_metric = trace_similarity(T_norm, correlation_threshold)
    
    if nargin < 2 || isempty(correlation_threshold)
        correlation_threshold = 0.9;
    end
    similarity_matrix = T_norm * T_norm';
    num_cells = size(T_norm, 1);


    % Optimized code below:
    
    % Set the diagonal elements to -Inf to exclude self-correlation
    similarity_matrix(1:num_cells+1:end) = -Inf;
    
    % Vectorized operation to count the number of cells above the threshold
    % for each cell, normalized by the number of other cells
    cell_metric = sum(similarity_matrix > correlation_threshold, 2) / (num_cells - 1);

    % Older code below:

%     cell_metric = zeros(num_cells, 1);
%    
%     for i = 1:num_cells
%         current_row = similarity_matrix(i, :);
%     
%         % Exclude self-correlation
%         current_row(i) = -Inf;
%     
%         % Count the number of cells exceeding the correlation threshold
%         num_above_threshold = sum(current_row > correlation_threshold);
%         cell_metric(i) = num_above_threshold / (num_cells - 1);
%     end

end