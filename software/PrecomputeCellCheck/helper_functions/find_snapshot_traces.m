function snapshot_traces = find_snapshot_traces(traces_dt, spikeIdxs, snapshotFrameSize, dt)

    spikeIdxs(isnan(spikeIdxs)) = 0; % Convert NaNs into zeros
    numFrames = size(traces_dt, 1);
    numCells = size(spikeIdxs, 2);
    
    snapshot_traces = cell(1,numCells);
    for i = 1:numCells
        topSpikeIndices = ceil(spikeIdxs(:, i)/dt);
        numValidSpikes = numel(topSpikeIndices);
        for j = 1:numValidSpikes
            lowFrameNum = max(topSpikeIndices(j)-(snapshotFrameSize/2), 1);
            upFrameNum = min(topSpikeIndices(j)+(snapshotFrameSize/2), numFrames);

            snapshot_traces{i}(j,1:(upFrameNum-lowFrameNum+1)) = traces_dt(lowFrameNum:upFrameNum,i)';
        end
    end
end