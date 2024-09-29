function cell_boundaries = find_cell_boundaries(spatial_weights, parallel)
% This function calculates the cell boundaries from the given spatial weights.
% INPUT
%   [spatial_weights] : A 2D array of spatial weights.
%
% OUTPUT
%   [cell_boundaries] : 2xn array of XY-coordinate values of the detected boundaries.
%
    numCells = size(spatial_weights,3);
    treshold = 0.05;
    binary_sw = spatial_weights >= treshold;

    cell_boundaries = cell(2, numCells);

    if parallel
        cellBoundaryX = cell(1,numCells);
        cellBoundaryY = cell(1,numCells);
        parfor i = 1:numCells
            slice = full(binary_sw(:,:,i));
            [cellBoundaryX{i}, cellBoundaryY{i}] = find_boundary(slice);
        end
        cell_boundaries = [cellBoundaryX; cellBoundaryY];
    else
        for i = 1:numCells
            slice = full(binary_sw(:,:,i));
            [cell_boundaries{1,i}, cell_boundaries{2,i}] = find_boundary(slice);
        end
    end
end