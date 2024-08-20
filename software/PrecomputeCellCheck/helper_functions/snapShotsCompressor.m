% function snapShotsCompressor(snapShots,fileNameComp)
% - Normalize pixel values('Single') of snapshots in [snapShots].
% - Rearrange data structure and convert to 'uint8'.
% - Save snapshots as a binary file delicately with the necessary 
%   properties of the original [snapShots] for recovery.

% INPUT 
% [snapShots]    : 'Cell' array, 1 x N, where N is the number of cells

% [fileNameComp] : 'String', the filename of the compressed binary file.
% 							- This function will detect whether the [fileNameComp] contains
%                 '.bin'. If not, will add '.bin' automatically.

% OUTPUT
%  No output but notification messages will print out.

function snapShotsCompressor(snapShots,fileNameComp)

% Determine whether the filename provided by the user has the [.bin]
% extension.
charFileName = lower(char(fileNameComp));
if ~strcmp(charFileName(end-3:end),'.bin')
    fileNameComp = string([char(fileNameComp),'.bin']);
    fprintf('----------\n')
    fprintf('SnapShotsCompressor:\n')
    fprintf('    File extension [.bin] added.\n');
    fprintf('    New file name is: [%s]\n',fileNameComp)
    fprintf('----------\n')
end

% Decompose the snapshots cell array and write into a binary file.
nCells = length(snapShots);
% Save the snapshots array information for reference.
matrixSizeArray = zeros(nCells,4);
matrixMinArray = zeros(nCells,1);
matrixMaxArray = zeros(nCells,1);

% Write into a binary file.
fid = fopen(fileNameComp,'wb');
fwrite(fid,nCells,'uint32'); % save the nCell at the beginning.

% Iteratively save the snapshots of each cell.
for cellCur = 1:nCells
    thisSnapShot = snapShots{cellCur};
    thisSize = size(thisSnapShot);
    thisMax = max(thisSnapShot(:));
    thisMin = min(thisSnapShot(:));
    matrixMinArray(cellCur) = thisMin;
    matrixMaxArray(cellCur) = thisMax;
    matrixSizeArray(cellCur,:) = thisSize;
    % convert to 0-255.
    thisSnapShotUint8 = round((thisSnapShot-thisMin)./(thisMax-thisMin)*255);
    fwrite(fid, thisSize, 'uint8'); % srite the size of the matrix
    fwrite(fid, thisMax, 'single'); % srite the matrix data in single precision
    fwrite(fid, thisMin, 'single');
    fwrite(fid, thisSnapShotUint8(:),'uint8');
end
fclose(fid);

% Show results, not necessary for actual implementation
% if you want to compare the compression rate, provide the original file
% name.
% oriFileInfo = dir(outputFileName);
% binFileInfo = dir(fileNameComp);
% fprintf('----------\n')
% fprintf('Compression:\n    Succussfully compressed [%s] to [%s]\nFrom [%.2f MB] to [%.2f MB], [%.1f%%] of the original size.\n',...
%     outputFileName,fileNameComp,oriFileInfo.bytes/(1024^2),binFileInfo.bytes/(1024^2),...
%     binFileInfo.bytes/oriFileInfo.bytes*100);
% fprintf('----------\n')

% Print results
fprintf('----------\n')
fprintf('SnapShotsCompressor:\n')
fprintf('    Successfully Compressed [%s].\n',fileNameComp)
fprintf('----------\n')
end