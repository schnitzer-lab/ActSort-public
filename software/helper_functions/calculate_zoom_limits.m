function [newXLim, newYLim] = calculate_zoom_limits(width, height, cell_center, zoom_level)
% Calculates new zoom limits based on cell center and zoom level.
% INPUT:
%   [width]       : width of the full field.
%   [height]      : height of the full field.
%   [cell_center] : coordinates of the center cell [x, y].
%   [zoom_level]  : zoom level (0 for full field, higher values for zoom).
% OUTPUT:
%   [newXLim]     : adjusted x-axis limits based on zoom.
%   [newYLim]     : adjusted y-axis limits based on zoom.

    % If sliderValue is zero, we show the full field; otherwise, we calculate a reduced field
    if zoom_level == 0
        windowWidth = width*2;
        windowHeight = height*2;
    else
        % Minimum field dimensions at maximum zoom
        MIN_FIELD_WIDTH = 10;  % Can be adjusted
        MIN_FIELD_HEIGHT = 10;  % Can be adjusted

        % Linear interpolation between minField and maxField based on the slider value
        windowWidth = width - (zoom_level / 100) * (width - MIN_FIELD_WIDTH);
        windowHeight = height - (zoom_level / 100) * (height - MIN_FIELD_HEIGHT);
    end

    xLim = [cell_center(1) - windowWidth/2, cell_center(1) + windowWidth/2];
    yLim = [cell_center(2) - windowHeight/2, cell_center(2) + windowHeight/2];

    % Correct the limits according to borders
    newXLim = max(min(xLim, width), 1);
    newYLim = max(min(yLim, height), 1);
end