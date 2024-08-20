function snapshots = capture_snapshots_from_memory(movie, spike_idxs, limits, frame_size, n_spikes, dt)
    numFrames = size(movie, 3);
    numCells = size(spike_idxs, 2);
    snapshots = cell(1, numCells);

    for i = 1:numCells
        [lowXlim, upXlim, lowYlim, upYlim] = deal(limits(1, i), limits(2, i), limits(3, i), limits(4, i));
        topSpikeIndices = ceil(spike_idxs(~isnan(spike_idxs(:, i)), i)/dt);
        numValidSpikes = numel(topSpikeIndices);
        snapshots{i} = zeros(upYlim-lowYlim+1, upXlim-lowXlim+1, frame_size+1, n_spikes, 'single');
    
        for j = 1:numValidSpikes
            lowFrameNum = max(topSpikeIndices(j)-(frame_size/2), 1);
            upFrameNum = min(topSpikeIndices(j)+(frame_size/2), numFrames);
            snap = movie(lowYlim:upYlim, lowXlim:upXlim, lowFrameNum:upFrameNum);
            snapshots{i}(:,:,1:size(snap,3),j) = snap;
        end
    end
end