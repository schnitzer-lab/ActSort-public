function metric = max_positive_correlation(S)
    % MAXPOSITIVECORRELATIONOPTIMIZED Computes the maximum positive correlation for each column in S with all other columns
    % Inputs:
    %   S - A matrix where each column represents spatial weights for a brain region
    % Outputs:
    %   metric - A row vector where each element is the max positive correlation of a column in S with any other column

    [~, numCols] = size(S);
    metric = zeros(1, numCols);  % Preallocate the metric vector

    for i = 1:numCols
        temp = S(:,i);
        cors = temp' * S; % Dot product of column i with all columns

        % Logical indexing to find positive correlations, excluding self-correlation
        validInd = cors > 0 & (1:numCols) ~= i;
        
        % Extract columns that have a positive correlation
        temp2 = S(:, validInd);
        
        % Calculate the correlation
        if isempty(temp2)
            metric(i) = 0;
        else
            a = full(corr(temp, temp2));
            metric(i) = max(a);
        end
    end
end
