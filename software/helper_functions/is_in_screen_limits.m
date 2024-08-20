function [binary] = is_in_screen_limits(point, x_lims, y_lims)
% This function checks if the x and y point is within the screen limits.
% This function is spesifically used in GUI operations.
% Point is [x, y]
    
    x_point = point(1);
    y_point = point(2);
    if is_in_range(x_point, x_lims) && is_in_range(y_point, y_lims)
        binary = true;
    else
        binary = false;
    end
end