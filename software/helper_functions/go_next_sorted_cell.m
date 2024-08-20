function idx = go_next_sorted_cell(sorting_order, current_cell)
    % Move along the already sorted cells
    % Enforce and assume that current_cell is never the last cell in
    % sorting_order!!
    nextIdx = find(sorting_order == current_cell) + 1;
    idx = sorting_order(nextIdx);
end