function cell_circumferences = find_cell_circumference(S, parallel)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Find total cell circumference from its boundaries.
% Cells with more circumference tend to be garbage cells.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
if ~issparse(S)
    S = ndSparse(S);
end
[H, W, numCells] = size(S);
cell_circumferences = zeros(1,numCells,'single');
    
% Parallel loop over each cell
if parallel
    parfor i = 1:numCells
        currentCell = S(:,:,i);
        [row, col, ~] = find(currentCell);
        binaryImage = false(H, W);
        binaryImage(sub2ind([H, W], row, col)) = true;
        boundaries = bwboundaries(binaryImage, 'noholes');
        if ~isempty(boundaries)
            circumference = 0;
            for f = 1:(length(boundaries))
                dX = diff(boundaries{f}(:,2));
                dY = diff(boundaries{f}(:,1));
                segment_lengths = sqrt(dX.^2 + dY.^2);
                circumference = circumference + sum(segment_lengths);
            end
            cell_circumferences(i) = circumference;
        end
    end
else
    for i = 1:numCells
        currentCell = S(:,:,i);
        [row, col, ~] = find(currentCell);
        binaryImage = false(H, W);
        binaryImage(sub2ind([H, W], row, col)) = true;
        boundaries = bwboundaries(binaryImage, 'noholes');
        if ~isempty(boundaries)
            circumference = 0;
            for f = 1:(length(boundaries))
                dX = diff(boundaries{f}(:,2));
                dY = diff(boundaries{f}(:,1));
                segment_lengths = sqrt(dX.^2 + dY.^2);
                circumference = circumference + sum(segment_lengths);
            end
            cell_circumferences(i) = circumference;
        end
    end
end
end

% function cell_circumferences = find_cell_circumference(S, parallel)
% %~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% % Find total cell circumference from its boundaries.
% % Cells with more circumference tend to be garbage cell.
% %~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% 
% numCells = size(S, 3);
% treshold = 0.0;
% binaryIm = S >= treshold;
% 
% cell_boundaries = cell(1, numCells);
% circumferenceFunc = @(cell_boundary) sum(sqrt(diff(cell_boundary(:, 1)).^2 + diff(cell_boundary(:, 2)).^2));
% 
% if parallel
%     parfor i = 1:numCells
%         currentCell = full(binaryIm(:,:,i));
%         boundaries = bwboundaries(currentCell, 'noholes');
%     
%         cell_boundaries{i} = vertcat(boundaries{:});
%     end
% else
%     for i = 1:numCells
%         currentCell = full(binaryIm(:,:,i));
%         boundaries = bwboundaries(currentCell, 'noholes');
%     
%         cell_boundaries{i} = vertcat(boundaries{:});
%     end
% end
% 
% cell_circumferences = cellfun(circumferenceFunc, cell_boundaries, 'UniformOutput', true);
% 
% end