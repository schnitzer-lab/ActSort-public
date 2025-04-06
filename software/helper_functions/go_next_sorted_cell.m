function [dataset_idx, cell_idx] = go_next_sorted_cell(sorting_order, current_cell)
    % Move to the next cell in the full sorting_order list
    % Assumes current_cell = [dataset_idx, cell_idx]
    % and that this cell exists in sorting_order and is not the last one.

    % Find the row matching the current cell
    match_idx = find(ismember(sorting_order, current_cell, 'rows'), 1);

    if isempty(match_idx)
        error('Current cell not found in sorting_order');
    end

    if match_idx == size(sorting_order, 1)
        error('Current cell is the last cell in sorting_order');
    end

    % Get the next cell in sorting_order
    dataset_idx = sorting_order(match_idx + 1, 1);
    cell_idx    = sorting_order(match_idx + 1, 2);
end
