function snapshots = capture_snapshots_in_chunks(movie_path, dataset_name, spike_idxs, limits, frame_size, n_spikes, dt)
    
    % Extract number of frames from movie path
    dataInfo = h5info(movie_path);
    dataset_name_modified = dataset_name(2:end);
    index = find(strcmp({dataInfo.Datasets.Name}, dataset_name_modified));
    numFrames = dataInfo.Datasets(index).Dataspace.Size(3);

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
            start = [lowYlim, lowXlim, lowFrameNum];
            count = [upYlim-lowYlim+1, upXlim-lowXlim+1, upFrameNum-lowFrameNum+1];
            snap = h5read(movie_path, dataset_name, start, count);
            snapshots{i}(:,:,1:size(snap,3),j) = snap;
        end
    end
end