function snapshotCLims = compute_snapshot_clims(snapshots)

    numCells = size(snapshots, 2);
    snapshotCLims = zeros(4, numCells, 'single');
    
    for i = 1:numCells
        flatSnap = snapshots{i}(:);
        [snapshotCLims(1,i), snapshotCLims(2,i), snapshotCLims(3,i), snapshotCLims(4,i)] = compute_clims(flatSnap);
    end

    % Vectorized but doesn't work faster!
%     flattenedCells = cellfun(@(c) c(:), snapshots, 'UniformOutput', false);
%     minCells = cellfun(@min, flattenedCells, 'UniformOutput', true);
%     maxCells = cellfun(@max, flattenedCells, 'UniformOutput', true);
%     sortedCells = cellfun(@sort, flattenedCells, 'UniformOutput', false);
%     def_min = cellfun(@(c) c(max(1, round(0.1 * length(c)))), sortedCells, 'UniformOutput', true);
%     def_max = cellfun(@(c) c(min(length(c), round(0.999 * length(c)))), sortedCells, 'UniformOutput', true);
%     
%     snapshotCLims(1,:) = minCells;
%     snapshotCLims(2,:) = maxCells;
%     snapshotCLims(3,:) = def_min;
%     snapshotCLims(4,:) = def_max;
end