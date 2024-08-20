% Removes NaN values from an array
function [removed_array] = remove_nans(array)
    removed_array = array(~isnan(array));
end