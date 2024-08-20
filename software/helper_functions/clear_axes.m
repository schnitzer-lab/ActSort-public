function clear_axes(ax_list)
% Clears content from the specified axes.
% INPUT:
%   [ax_list] : array of axes handles to be cleared.

    for ax = ax_list
        cla(ax);
    end
end