function limits = find_viewing_limits(cellBoundaries, neighborBoundaries, margin, size_hw)
    numCells = size(cellBoundaries,2);
    limits = zeros(4,numCells);

    for i = 1:numCells
        cb = cellBoundaries(:,i);
        nb = neighborBoundaries{i};
        [limits(1,i), limits(2,i), limits(3,i), limits(4,i)] = find_limits(cb, nb, margin,size_hw);
    end
end