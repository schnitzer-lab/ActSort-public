function [t_good, t_bad, t_all] = find_time_elapsed_spikes(T)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Find the average time elapsed between 'good','bad' and 'all' spikes within trace.
% This measures regularity of events. Bad spikes tend to be more frequent
% while good spikes are less frequent.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
numCells = size(T,2);
time_elapsed_spikes = zeros(3,numCells);
for i = 1:numCells
    traceData = T(:, i);
    MPP = quantile(traceData,0.9)*0.5;
    if MPP <= 0
        MPP = std(traceData);
    end
    [~,goodSpikeIndices] = findpeaks(traceData,'MinPeakProminence',MPP);
    [~,allSpikeIndices] = findpeaks(traceData);
    badSpikeIndices= setdiff(allSpikeIndices, goodSpikeIndices);
    
    if ~isempty(goodSpikeIndices)
        time_elapsed_spikes(1,i) = sum(diff(goodSpikeIndices))/numel(goodSpikeIndices);
    end
    if ~isempty(badSpikeIndices)
        time_elapsed_spikes(2,i) = sum(diff(badSpikeIndices))/numel(badSpikeIndices);
    end
    if ~isempty(allSpikeIndices)
        time_elapsed_spikes(3,i) = sum(diff(allSpikeIndices))/numel(allSpikeIndices);
    end
end

t_good = time_elapsed_spikes(1,:);
t_bad = time_elapsed_spikes(2,:);
t_all = time_elapsed_spikes(3,:);