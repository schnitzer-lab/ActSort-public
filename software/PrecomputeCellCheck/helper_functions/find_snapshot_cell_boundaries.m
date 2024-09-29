function snapshot_cell_boundaries = find_snapshot_cell_boundaries(cell_boundaries, limits)

    numCells = size(cell_boundaries,2);
    snapshot_cell_boundaries = cell(1, numCells); %(:,1) for X and (:,2) for Y
    for i = 1: numCells
        lowXlim = limits(1,i);
        lowYlim = limits(3,i);
        boundaryX = cell_boundaries{1,i};
        boundaryY = cell_boundaries{2,i};

        snapshot_cell_boundaries{i} = single([boundaryX-lowXlim+1; boundaryY-lowYlim+1]);
    end
end