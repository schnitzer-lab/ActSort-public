% Creates an alpha mask for the cell map layers
function alphaMask = create_alpha_mask(layer, alpha_value)
    cellMask = im2gray(layer) > 0;
    alphaMask = double(cellMask);
    alphaMask(~cellMask) = 0;
    alphaMask(cellMask) = alpha_value;
end