function result = replace_nans_with_mean(matrix)
% This function replaces all the NaNs with column means.

    % Find the mean value for each column
    columnMeans = sum(matrix, 1, 'omitnan') / size(matrix, 1);
    % Find NaN elements in the array
    nanIndices = isnan(matrix);
    % Replace NaNs with the mean of their respective column
    expandedArray = repmat(columnMeans, size(matrix,1), 1);
    % Turn NaN values into 1s 
    matrix(nanIndices) = 0; 
    newValuesToReplace = expandedArray.*nanIndices;
    % Return the result
    result = matrix + newValuesToReplace;
end