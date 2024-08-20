function [zoomed_traces, zoomed_spike_idxs] = find_zoomed_traces(trace, spikes, zoom_interval)
    % [trace] : (1 x numFrames) trace activity
    % [spikes]: (1 x spikeNum) spike point indices
    % [zoomInterval] : (scalar) denotes how much zoom is intended
    % [zoomedTraces] : (frameNum x spike_point) 

    num_spikes = numel(spikes);
    zoomed_traces = cell(1 , num_spikes);
    zoomed_spike_idxs = zeros(1,num_spikes);
    for i = 1:num_spikes
        spikeIdx = spikes(i);
        min_lim = max(1, spikeIdx - zoom_interval);
        max_lim = min(spikeIdx + zoom_interval, size(trace,1));
        zoomed_spike_idxs(i) = max(1, spikeIdx - min_lim + 1);
        trace_cropped = trace(min_lim:max_lim);
        zoomed_traces{i} =  trace_cropped;    
    end
end