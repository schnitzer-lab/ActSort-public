function cell_boundaries = find_cell_boundaries(spatial_weights, parallel)
% This function calculates the cell boundaries from the given spatial weights.
% INPUT
%   [spatial_weights] : A 2D array of spatial weights.
%
% OUTPUT
%   [cell_boundaries] : 1xn cell array of XY-coordinate values of the detected boundaries.
%
    numCells = size(spatial_weights,3);
    THRESHOLD = 0.05;
    binary_sw = spatial_weights >= THRESHOLD;

    cell_boundaries = cell(1, numCells);

    if parallel
        parfor i = 1:numCells
            slice = full(binary_sw(:,:,i));
            
            [cellBoundaryX, cellBoundaryY] = find_boundary(slice);
            cell_boundaries{i} = [cellBoundaryX; cellBoundaryY];
        end
    else
        for i = 1:numCells
            slice = full(binary_sw(:,:,i));
            
            [cellBoundaryX, cellBoundaryY] = find_boundary(slice);
            cell_boundaries{i} = [cellBoundaryX; cellBoundaryY];
        end
    end
end