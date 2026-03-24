function output = caiman_converter(filepath)
% This function used to convert CAIMAN-cnmfe output into the form of EXTRACT output
% that could be precomputed by ActSort.
% 
% INPUT:
%   [filepath]: A string or char array containing the file path to the dataset.
%   [savepath]: A string or char array containing the saving path.
%
% OUTPUT:
%   [output]: A structure containing spatial_weights, temporal_weights, max_im, config, info.
%

%% check 1: file form

try
    info = h5info(filepath);
catch
    warning("Please check your input. Expected an HDF5 file.");
    return;
end

%% check 2: runmode

attr_names = {info.Attributes.Name};
idx_runmode = find(strcmp(attr_names, 'runmode'), 1);

if isempty(idx_runmode)
    warning("No 'runmode' attribute found. This may not be a CAIMAN CNMF output.");
    return;
end

runmode_val = info.Attributes(idx_runmode).Value;

if ~strcmp(runmode_val, 'CNMF')
    warning("runmode is not 'CNMF'.Please check your input.");
    return;
end

%%
dims = double(h5read(filepath, '/dims'));  % Group '/estimates' -- dim.shape = [ W , H ]

temporal_weights = double(h5read(filepath, '/estimates/C'));  % Group '/estimates' -- C.shape = [ T , N ]

Cn = double(h5read(filepath, '/estimates/Cn'));  % Group '/estimates' -- Cn.shape = [ W , H ]
max_im = Cn';
% Group '/estimates/A'
% case: CSC sparse matrix
% construct:  A.shape = [ W*H , N ]

data    = double(h5read(filepath, '/estimates/A/data'));
indices = double(h5read(filepath, '/estimates/A/indices'));
indptr  = double(h5read(filepath, '/estimates/A/indptr'));
shape   = double(h5read(filepath, '/estimates/A/shape'));

n_rows = shape(1);   % H*W
n_cols = shape(2);   % N

% Python to MATLAB indexing (+1)
indices = double(indices) + 1;
indptr  = double(indptr) + 1;

% construct sparse
A = sparse(n_rows, n_cols);

for col = 1:n_cols
    start_idx = indptr(col);
    end_idx   = indptr(col+1) - 1;

    if start_idx <= end_idx
        rows = indices(start_idx:end_idx);
        vals = data(start_idx:end_idx);

        A(rows, col) = vals;
    end
end


Y = dims(1);
X = dims(2);
N = size(A, 2);


[rows, cols, vals] = find(A);
[y_idx, x_idx] = ind2sub([Y, X], rows);

coords = [x_idx, y_idx, cols];
values = vals;  % double type
spatial_weights = ndSparse.build(coords, values, [X, Y, N]);

config = struct();
info = struct();

output = struct();
output.spatial_weights = spatial_weights;
output.temporal_weights = temporal_weights;
output.max_im = max_im;
output.config = config;
output.info = info;

if strlength(filepath) > 0 
    % 获取 h5 文件所在目录和文件名
    [path, name, ~] = fileparts(filepath);

    % 生成新文件名
    newFileName = name + "_precomputed.mat";
    savepath = fullfile(path, newFileName);

    save(savepath, 'output', '-v7.3');
    fprintf('Converted data saved to %s\n', savepath);
end

end

