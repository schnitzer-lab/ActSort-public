function neighbor_boundaries = find_neighbor_boundaries(cell_boundaries, neighbor_idxs)
    numCells = size(cell_boundaries,2);
    neighbor_boundaries = cell(1,numCells);
    
    for i = 1:numCells
        neighborIdx = neighbor_idxs{i};
        if isempty(neighborIdx)
            neighbor_boundaries{i} = nan(2,1);
        else
            for n = 1:size(neighborIdx,2)
                cellIdx = neighborIdx(n);
                neighborBoundaryX = cell_boundaries{cellIdx}(1,:);
                neighborBoundaryY = cell_boundaries{cellIdx}(2,:);
                boundariesToAdd = [neighborBoundaryX; neighborBoundaryY];
                neighbor_boundaries{i} = [neighbor_boundaries{i} boundariesToAdd];
            end
        end
    end
end