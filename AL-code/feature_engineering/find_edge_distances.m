function edge_distances = find_edge_distances(S, parallel)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Find distances from edges of the movie. 
% This calculates distance to the closest edge.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-

[H, W, numCells] = size(S);
edge_distances = zeros(1,numCells);

% Find indices of all cell points
binaryMatrix = S > 0; %Convert to binary for efficiency

if parallel
    parfor i = 1:numCells
        slice = binaryMatrix(:,:,i); 
        [row, col] = find(slice); 
        % Calculate mean of the positions
        x = mean(col);
        y = mean(row);
    
        edge_distances(i) = min(min(y,H-y),min(x,W-x));
    end
else
    for i = 1:numCells
        slice = binaryMatrix(:,:,i); 
        [row, col] = find(slice); 
        % Calculate mean of the positions
        x = mean(col);
        y = mean(row);
    
        edge_distances(i) = min(min(y,H-y),min(x,W-x));
    end
end

end