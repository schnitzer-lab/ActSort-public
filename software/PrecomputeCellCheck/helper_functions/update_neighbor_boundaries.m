function new_boundaries = update_neighbor_boundaries(neighbor_boundaries, limits)
    
    numCells = size(neighbor_boundaries,2);
    new_boundaries = cell(1,numCells);

    for i = 1:numCells
        lowXlim = limits(1,i);
        lowYlim = limits(3,i);

        new_boundaries{i}(1,:) = single(neighbor_boundaries{i}(1,:)-lowXlim+1);
        new_boundaries{i}(2,:) = single(neighbor_boundaries{i}(2,:)-lowYlim+1);
    end

end