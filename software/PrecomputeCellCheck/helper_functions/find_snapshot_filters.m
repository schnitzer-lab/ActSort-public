function snapshot_filters = find_snapshot_filters(spatial_weights, limits)
    numCells = size(spatial_weights, 3);
    snapshot_filters = cell(1, numCells);
    for i = 1:numCells
        [lowXlim, upXlim, lowYlim, upYlim] = deal(limits(1, i), limits(2, i), limits(3, i), limits(4, i));
        snapshot_filters{i} = spatial_weights(lowYlim:upYlim, lowXlim:upXlim, i);
    end
end