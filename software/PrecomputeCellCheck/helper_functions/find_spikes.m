function spike_indices = find_spikes(trace, n_spikes)
% This function finds spike points for a given trace.
% INPUT
%   [traceData] : An nx1 array containing trace activity data for the cell.
%   [n_spikes] : The number of spikes to detect.
%
% OUTPUT
%   [spike_indices] : Indices of the spikes found. If the number of detected spikes 
%                   is less than n_spikes, the remaining indices are filled with NaN.

    MPP = std(trace);  % Min Peak Prominence
    MPD = size(trace, 1) * 0.01;  % Min Peak Distance

    [~, spikeIdx] = findpeaks(trace, 'MinPeakProminence', MPP, ...
                               'MinPeakDistance', MPD, ...
                               'SortStr', 'descend', ...
                               'NPeaks', n_spikes);

    if isempty(spikeIdx) 
        [~, I] = max(trace);
        spikeIdx = I(1);
    end

    % Preallocate and fill the spike indices
    spike_indices = NaN(n_spikes, 1);
    spike_indices(1:length(spikeIdx)) = spikeIdx;
end