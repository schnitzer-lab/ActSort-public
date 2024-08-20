function cell_center = find_center(binaryMatrix)
% This function calculates the center of a cell, which is needed for future calculations.
% INPUT
%   [binaryMatrix] : A 2D binary array of spatial weights representing the cell.
%
% OUTPUT
%   [cell_center] : (x, y) coordinate values of the cell center.
%

    % Find indices of all cell points
    [row, col] = find(binaryMatrix); 

    % Calculate mean of the positions
    cell_center(1, :) = mean(col);
    cell_center(2, :) = mean(row);
end