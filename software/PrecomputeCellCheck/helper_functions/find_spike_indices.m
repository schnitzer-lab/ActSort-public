function spikeIdxs = find_spike_indices(trace, snapshotFrameSize, numSpikes, parallel)
% This function finds the spike indices within the trace activity.
% It is mainly useful for future calculations.
% INPUT
%   [trace] : An [frameNum x cellNum] array containing trace activity data for the cell.
%   [snapshotFrameSize] : Used to avoid detecting spikes close to the start 
%                         and end of the activity. This consideration is important 
%                         because extracting snapshots near the boundaries of the 
%                         activity can be challenging.
%   [numSpikes] : Number of spikes to detect.
%   [parallel] : Flag to use parallel computing.
%
% OUTPUT
%   [spikeIdxs] : Indices of the spikes found. If the number of detected spikes 
%                is less than [numSpikes], the remaining indices are filled with NaN.
%
    numCells = size(trace, 2);
    spikeIdxs = zeros(numSpikes, numCells);
    if parallel
        parfor i = 1:numCells
            traceData = trace(:,i);
            newTraceToDetect = set_trace_event_interval(traceData, snapshotFrameSize);
            spikeIdxs(:, i) = find_spikes(newTraceToDetect, numSpikes);
        end
    else
        for i = 1:numCells
            traceData = trace(:,i);
            newTraceToDetect = set_trace_event_interval(traceData, snapshotFrameSize);
            spikeIdxs(:, i) = find_spikes(newTraceToDetect, numSpikes);
        end
    end
    
end