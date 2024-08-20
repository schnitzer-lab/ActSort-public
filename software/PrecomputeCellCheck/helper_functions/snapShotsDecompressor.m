% function [snapShotsReco] = snapShotsDecompressor(fileNameComp)
% Load the binary file [fileNameComp].
% Recovery [snapShots] using properties attached delicately. 
% INPUT 

% [fileNameComp]  : 'String', the filename of the compressed binary file.
% 							- This function will detect whether the [fileNameComp] contains
%                 '.bin'. If not, will add '.bin' automatically.

% OUTPUT
%  [snapShotsReco] : 'Cell' array, 1 x N, where N is the number of cells

function [snapShotsReco] = snapShotsDecompressor(fileNameComp)

% Determine whether the filename provided by the user has the [.bin]
% extension.
charFileName = lower(char(fileNameComp));
if ~strcmp(charFileName(end-3:end),'.bin')
    fileNameComp = string([char(fileNameComp),'.bin']);
    fprintf('----------\n')
    fprintf('SnapShotsDecompressor:\n')
    fprintf('    File extension [.bin] added.\n');
    fprintf('    New file name is: [%s]\n',fileNameComp)
    fprintf('----------\n')
end

% Recover from binary files.
% read the binary file
fid = fopen(fileNameComp,'rb');
nCells = fread(fid,1, 'uint32');% get the nCell first.
loadedSnapShots = cell(1,nCells);
% Iteratively load each snapshots of each cell.
for cellCur = 1:nCells
    thisSize =  fread(fid,4, 'uint8');
    thisMax  = fread(fid,1, 'single');
    thisMin  = fread(fid,1, 'single');
    thisSnapShotUint8 = fread(fid,prod(thisSize), 'uint8');
    thisSnapShotUint8 = reshape(thisSnapShotUint8,thisSize');
    thisSnapShot = thisSnapShotUint8/255*(thisMax-thisMin)+thisMin;
    loadedSnapShots{cellCur} = single(thisSnapShot);
end
fclose(fid);

% Print results.
fprintf('----------\n')
fprintf('SnapShotsDecompressor:\n')
fprintf('    Successfully recovered compression [%s].\n',fileNameComp)
fprintf('----------\n')
snapShotsReco = loadedSnapShots;
end