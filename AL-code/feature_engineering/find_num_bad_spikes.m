function num_spikes = find_num_bad_spikes(T)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Find the difference between 'good' spikes and 'all' spikes within trace.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
T = T ./max(T,[],1);
[~,numCells] = size(T);
num_spikes = zeros(1,numCells);
for i = 1:numCells
    traceData = T(:, i);

    MPP = max(quantile(traceData,0.9)*0.5,0.1);
    [~,bestSpikeIndices] = findpeaks(traceData,'MinPeakProminence',MPP);
    [~,allSpikeIndices] = findpeaks(traceData);
    num_spikes(i) = numel(allSpikeIndices)-numel(bestSpikeIndices);
end