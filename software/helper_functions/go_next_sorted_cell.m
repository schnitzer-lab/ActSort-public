function [dataset_idx, cell_idx] = go_next_sorted_cell(sorting_order, dataset_idx, cell_idx)
    % Move along the already sorted cells
    % Enforce and assume that current_cell is never the last cell in sorting_order!!

    % Filter the sorting order for the given dataset_idx
    filtered_sorting_order = sorting_order(sorting_order(:,1) == dataset_idx, :);

    % Find the logical index where the current cell is located
    logical_idx = (filtered_sorting_order(:,2) == cell_idx);

    if ~any(logical_idx)
        error('Current cell not found in sorting_order');
    end
    
    % Convert logical index to numeric index
    currentIdx = find(logical_idx, 1);

    if currentIdx == size(filtered_sorting_order, 1)
        error('Current cell is the last cell in sorting_order');
    end

    % Get the next sorted cell
    dataset_idx = filtered_sorting_order(currentIdx + 1, 1);
    cell_idx = filtered_sorting_order(currentIdx + 1, 2);
end