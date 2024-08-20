function neighbor_idxs = find_neighbor_idxs(boundaries, centers, margin, size_HW)
% This function finds the indices of neighboring cells to the current cell.
% It is mainly useful for future calculations.
% INPUT
%   [boundaries] : An array containing the boundary values of the current cell.
%   [centers] : An array containing the center values of all cells.
%   [margin] : The margin amount used in the calculation.
%   [idx] : The index of the current cell.
%   [size] : An array containing the size of the movie.
%
% OUTPUT
%   [neighborIdxs] : Indices of all neighboring cells.
%
    numCells = size(boundaries,2);
    neighbor_idxs = cell(1,numCells);
    for i = 1:numCells
        neighbor_idxs{i} = find_neighbors(boundaries, centers, margin, i, size_HW);
    end
end