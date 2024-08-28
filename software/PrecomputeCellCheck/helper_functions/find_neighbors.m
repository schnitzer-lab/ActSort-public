function neighborIdxs = find_neighbors(boundaries, centers, margin, idx, size)
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
    H = size(1);
    W = size(2);
    cellCentersX = centers(1,:);
    cellCentersY = centers(2,:);
    boundaryX = boundaries{idx}(1,:);
    boundaryY = boundaries{idx}(2,:);
    
    upXlim = min(max(boundaryX) + margin, W);
    lowXlim = max(min(boundaryX) - margin, 1);
    upYlim = min(max(boundaryY) + margin, H);
    lowYlim = max(min(boundaryY) - margin, 1);
    
    isWithinXRange = (cellCentersX < upXlim) & (cellCentersX > lowXlim);
    isWithinYRange = (cellCentersY < upYlim) & (cellCentersY > lowYlim);
    isNotCurrentCell = (cellCentersX ~= cellCentersX(idx)) & (cellCentersY ~= cellCentersY(idx));
    
    neighborIdxs = find(isWithinXRange & isWithinYRange & isNotCurrentCell);
end