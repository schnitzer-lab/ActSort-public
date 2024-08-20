% Clears empty axes to maintain a clean UI
function clear_axes(ax_list)
    for ax = ax_list
        cla(ax);
    end
end