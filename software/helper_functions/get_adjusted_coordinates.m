% Adjusts coordinates from a click event to the axes
function [adjustedX, adjustedY] = get_adjusted_coordinates(event, width, height)
    ax = event.Source.Parent;
    axesPoint = event.IntersectionPoint(1:2);
    xLimits = ax.XLim;
    yLimits = ax.YLim;
    adjustedX = xLimits(1) + axesPoint(1) * diff(xLimits) / width;
    adjustedY = yLimits(1) + axesPoint(2) * diff(yLimits) / height;
end