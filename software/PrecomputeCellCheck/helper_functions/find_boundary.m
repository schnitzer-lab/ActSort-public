function [boundaryX, boundaryY] = find_boundary(binary_im)
% This function calculates the cell boundaries from the given spatial weights.
% INPUT
%   [im] : A 2D array of spatial weights.
%
% OUTPUT
%   [boundaryX] : 1xn array of X-coordinate values of the detected boundaries.
%   [boundaryY] : 1xn array of Y-coordinate values of the detected boundaries.
%
    
    % Directly use the thresholded image for finding boundaries
    boundaries = bwboundaries(binary_im, 'noholes');
    
    % Preallocate the boundary arrays for efficiency
    boundaryX = zeros(0, 1, 'single');
    boundaryY = zeros(0, 1, 'single');
    
    windowSize = 3;
    for f = 1:length(boundaries)
        smoothX = smooth(boundaries{f}(:,2), windowSize);
        smoothY = smooth(boundaries{f}(:,1), windowSize);

        % Append to the existing arrays
        boundaryX = [boundaryX, round(smoothX'), NaN];
        boundaryY = [boundaryY, round(smoothY'), NaN];
    end
end