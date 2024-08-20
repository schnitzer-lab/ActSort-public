function cell_centers = find_cell_centers(spatial_weights)
% This function returns centers for all the cells/
% INPUT
%   [spatial_weights] : An 3D array containing spatial footprint. This
%   comes form the output of neuron extraction algorithm.
%
% OUTPUT
%   [cell_centers] : 2xn array containing cell centers. First row is for X
%   values and second row is for Y values.
%
    numCells = size(spatial_weights,3);
    cell_centers = zeros(2,numCells); 
    binary_spatial_weights = spatial_weights > 0; %Convert to binary for efficiency

    for i = 1:numCells
        cell_centers(:,i) = find_center(binary_spatial_weights(:,:,i)); 
    end
end