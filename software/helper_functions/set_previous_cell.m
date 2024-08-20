function idx = set_previous_cell(current_cell_idx, sorting_order)

if isempty(sorting_order)
    idx = current_cell_idx - 1;
    idx = max(idx, 1);
else    
    if ismember(current_cell_idx, sorting_order)
        previousIdx = find(sorting_order == current_cell_idx) - 1;
        idx = sorting_order(max(previousIdx,1));
    else
        idx = sorting_order(end);
    end
end

end