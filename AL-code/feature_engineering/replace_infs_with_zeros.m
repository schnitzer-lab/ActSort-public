function result = replace_infs_with_zeros(matrix)
% This function converts all infs into 0s

    % Convert inf values into 0
    inf_locations = isinf(matrix);
    matrix(inf_locations) = 0;
    result = matrix;
end