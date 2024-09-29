function metric = has_multiple_bodies(S, parallel)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Find if cells have a multiple cell bodies.
% Cells with bodies more then one tend to be garbage cells.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% [~, ~, numCells] = size(S);
% metric = zeros(1,numCells);
% treshold = 0.05;
% binaryIm = S >= treshold;
% 
% if parallel
%     parfor i = 1:numCells
%         currentCell = full(binaryIm(:,:,i));
%         labeledImage = bwlabel(currentCell);
%         metric(i) = max(labeledImage(:));
%     end
% else
%     for i = 1:numCells
%         currentCell = full(binaryIm(:,:,i));
%         labeledImage = bwlabel(currentCell);
%         metric(i) = max(labeledImage(:));
%     end
% end
% 
% metric = metric > 1;
[~, ~, numCells] = size(S);
metric = zeros(1,numCells,'logical');
if parallel
    parfor i = 1:numCells
        currentCell = full(S(:,:,i));
        binaryIm = imbinarize(currentCell,'adaptive');
        labeledImage = bwlabel(binaryIm);
        n_parts = max(labeledImage(:));
        metric(i) = abs(n_parts-1);
    end
else
    for i = 1:numCells
        currentCell = full(S(:,:,i));
        binaryIm = imbinarize(currentCell,'adaptive');
        labeledImage = bwlabel(binaryIm);
        n_parts = max(labeledImage(:));
        metric(i) = abs(n_parts-1);
    end
end
end