function metric = max_positive_correlation(S)
    % MAXPOSITIVECORRELATIONOPTIMIZED Computes the maximum positive correlation for each column in S with all other columns
    % Inputs:
    %   S - A matrix where each column represents spatial weights for a brain region
    % Outputs:
    %   metric - A row vector where each element is the max positive correlation of a column in S with any other column

    [~, numCols] = size(S);
    metric = zeros(1, numCols);  % Preallocate the metric vector

    norms = sqrt(sum(S.^2, 1));  % Compute the norm of each column (2-norm or Euclidean norm)

    for i = 1:numCols
        temp = S(:,i);
        cors = temp' * S;  % Dot product of column i with all columns

        % Normalize the dot products to get correlation coefficients
        cors = cors ./ (norms(i) * norms);  % Normalize with the norms of i-th column and all columns

        % Set self-correlation to negative infinity to exclude it from max calculation
        cors(i) = -Inf;

        % Find the maximum positive correlation
        maxCor = max(cors(cors > 0));
        if isempty(maxCor)
            metric(i) = 0;
        else
            metric(i) = maxCor;
        end
    end
end
