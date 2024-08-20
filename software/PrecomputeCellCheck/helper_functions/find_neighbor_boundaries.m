function neighbor_boundaries = find_neighbor_boundaries(cell_boundaries, neighbor_idxs)
    numCells = size(cell_boundaries,2);
    neighbor_boundaries = cell(1,numCells);
    
    for i = 1:numCells
        neighborIdx = neighbor_idxs{i};
        if isempty(neighborIdx)
            neighbor_boundaries{i} = nan(2,1);
        else
            for n = 1:size(neighborIdx,2)
                neighborBoundaryX = cell_boundaries{1,neighborIdx(n)};
                neighborBoundaryY = cell_boundaries{2,neighborIdx(n)};
                boundariesToAdd = [neighborBoundaryX; neighborBoundaryY];
                neighbor_boundaries{i} = [neighbor_boundaries{i} boundariesToAdd];
            end
        end
    end
end