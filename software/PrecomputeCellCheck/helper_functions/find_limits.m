function [lowXlim, upXlim, lowYlim, upYlim] = find_limits(cellBoundary, neighborBoundary, margin, size)
% This function calculates the viewing limits for snapshots.
% It is primarily useful for future calculations and GUI visuals.
% INPUT
%   [cellBoundary] : An array containing the boundaries of the current cell.
%   [neighborBoundary] : An array containing the boundaries of neighboring cells.
%   [margin] : The margin amount used in the calculation.
%   [size] : An array specifying the size of the movie.
%
% OUTPUT
%   [lowXlim] : The lower X-axis limit coordinate value.
%   [upXlim] : The upper X-axis limit coordinate value.
%   [lowYlim] : The lower Y-axis limit coordinate value.
%   [upYlim] : The upper Y-axis limit coordinate value.
%
    H = size(1);
    W = size(2);

    maxX = max([cellBoundary(1,:)+margin, neighborBoundary(1,:)]);
    minX = min([cellBoundary(1,:)-margin, neighborBoundary(1,:)]);
    maxY = max([cellBoundary(2,:)+margin, neighborBoundary(2,:)]);
    minY = min([cellBoundary(2,:)-margin, neighborBoundary(2,:)]);

    lowXlim = max(minX , 1);
    upXlim = min(maxX, W);
    lowYlim = max(minY, 1);
    upYlim = min(maxY, H);
end