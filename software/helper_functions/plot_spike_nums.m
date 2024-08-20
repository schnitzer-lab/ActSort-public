% Plots the number of spikes on the trace plot
function plot_spike_nums(axes, spike_points, trace)
    xPoints = remove_nans(spike_points);
    yPoints = trace(xPoints);
    numbers = string(1:numel(xPoints));

    % Can be customized
    COLOR = [0.3, 0.5, 1];
    FONT_WEIGHT = 'bold';
    text(xPoints, yPoints, numbers, ...
        'Parent', axes, ...
        'Fontweight', FONT_WEIGHT, ...
        'color', COLOR);
end