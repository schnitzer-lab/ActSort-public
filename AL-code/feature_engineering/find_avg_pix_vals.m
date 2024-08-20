function avg_pix_vals = find_avg_pix_vals(S)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Find total pixel values (activity) of spatial filters.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
numCells = size(S,3);
avg_pix_vals = zeros(1,numCells);
for i = 1:numCells
    currentCell = S(:,:,i);
    sum_pixvals = sum(currentCell(:));
    avg_pix_vals(i) = sum_pixvals;
end
end