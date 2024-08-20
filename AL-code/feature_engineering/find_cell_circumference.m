function cell_circumferences = find_cell_circumference(S, parallel)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Find total cell circumference from its boundaries.
% Cells with more circumference tend to be garbage cell.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-

numCells = size(S, 3);
treshold = 0.05;
binaryIm = S >= treshold;

cell_boundaries = cell(1, numCells);
circumferenceFunc = @(cell_boundary) sum(sqrt(diff(cell_boundary(:, 1)).^2 + diff(cell_boundary(:, 2)).^2));

if parallel
    parfor i = 1:numCells
        currentCell = full(binaryIm(:,:,i));
        boundaries = bwboundaries(currentCell, 'noholes');
    
        cell_boundaries{i} = vertcat(boundaries{:});
    end
else
    for i = 1:numCells
        currentCell = full(binaryIm(:,:,i));
        boundaries = bwboundaries(currentCell, 'noholes');
    
        cell_boundaries{i} = vertcat(boundaries{:});
    end
end

cell_circumferences = cellfun(circumferenceFunc, cell_boundaries, 'UniformOutput', true);

end