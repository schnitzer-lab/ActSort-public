function set_trace_axis_lims(axis, traces)
% Sets the y and x limits for the trace plot
    MARGIN = 1e-6;
    yLim = [min(traces), max(traces)+MARGIN];
    xLim = [1, size(traces, 1)];
    set(axis, 'ylim', yLim,'xlim', xLim);
end