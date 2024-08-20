function [alpha_mask] = create_alpha_mask(layer, alpha_value)
% Creates an alpha mask for the cell map layers. This is used for
% controlling cell transparency in cell map. 
% INPUT:
%   [layer]       : image layer used to generate the mask.
%   [alpha_value] : opacity value to assign to the cell regions.
% OUTPUT:
%   [alphaMask]   : alpha mask with specified opacity for cell regions.

    cell_mask = im2gray(layer) > 0;
    alpha_mask = double(cell_mask);
    alpha_mask(~cell_mask) = 0;
    alpha_mask(cell_mask) = alpha_value;
end