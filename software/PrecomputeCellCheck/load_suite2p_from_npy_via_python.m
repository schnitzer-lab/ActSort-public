function s2p = load_suite2p_from_npy_via_python(suite2p_path, python_cmd)
%LOAD_SUITE2P_FROM_NPY_VIA_PYTHON
% Load Suite2p outputs from .npy files by calling a Python script through
% system(...), then reading a temporary .mat file back into MATLAB.
%
% INPUT
%   suite2p_path : path to Suite2p plane folder, e.g. ".../suite2p/plane0"
%   python_cmd   : full path to python executable
%
% OUTPUT
%   s2p : struct with fields
%         - F
%         - Fneu
%         - spks
%         - iscell
%         - ops
%         - stat
%
% NOTES
%   This function expects these files when available:
%       F.npy        (required)
%       Fneu.npy     (optional)
%       spks.npy     (optional)
%       iscell.npy   (optional)
%       stat.npy     (required)
%       ops.npy      (optional)

    suite2p_path = char(string(suite2p_path));
    python_cmd   = char(string(python_cmd));

    if ~isfolder(suite2p_path)
        error('Suite2p path not found: %s', suite2p_path);
    end

    if ~isfile(python_cmd)
        error('Python executable not found: %s', python_cmd);
    end

    temp_dir = tempname;
    mkdir(temp_dir);

    py_script = fullfile(temp_dir, 'convert_suite2p_to_mat.py');
    out_mat   = fullfile(temp_dir, 'suite2p_temp.mat');

    try
        write_python_converter(py_script);

        cmd = sprintf('"%s" "%s" "%s" "%s"', python_cmd, py_script, suite2p_path, out_mat);
        [status, cmdout] = system(cmd);

        if status ~= 0
            error('Python conversion failed:\n%s', cmdout);
        end

        if ~exist(out_mat, 'file')
            error('Temporary MAT file was not created by Python converter.');
        end

        L = load(out_mat);

        % ---------------------------
        % Reconstruct MATLAB struct
        % ---------------------------
        s2p = struct;

        if isfield(L, 'F')
            s2p.F = single(L.F);
        else
            error('F missing from converted Suite2p data.');
        end

        if isfield(L, 'Fneu')
            s2p.Fneu = single(L.Fneu);
        else
            s2p.Fneu = [];
        end

        if isfield(L, 'spks')
            s2p.spks = single(L.spks);
        else
            s2p.spks = [];
        end

        if isfield(L, 'iscell')
            s2p.iscell = double(L.iscell);
        else
            s2p.iscell = [];
        end

        % ops fields
        ops = struct;
        if isfield(L, 'Ly')
            ops.Ly = double(L.Ly);
        end
        if isfield(L, 'Lx')
            ops.Lx = double(L.Lx);
        end
        if isfield(L, 'meanImg')
            ops.meanImg = single(L.meanImg);
        end
        if isfield(L, 'max_proj')
            ops.max_proj = single(L.max_proj);
        end
        s2p.ops = ops;

        % stat fields reconstructed from saved object arrays
        if ~isfield(L, 'ypix_list') || ~isfield(L, 'xpix_list')
            error('stat-derived ROI pixel lists were not found in temporary MAT file.');
        end

        n_roi = numel(L.ypix_list);
        stat(n_roi,1) = struct('ypix', [], 'xpix', [], 'lam', [], 'overlap', []);

        for i = 1:n_roi
            stat(i).ypix = unwrap_mat_cell_numeric(L.ypix_list{i});
            stat(i).xpix = unwrap_mat_cell_numeric(L.xpix_list{i});

            if isfield(L, 'lam_list') && numel(L.lam_list) >= i && ~isempty(L.lam_list{i})
                stat(i).lam = unwrap_mat_cell_numeric(L.lam_list{i});
            else
                stat(i).lam = [];
            end

            if isfield(L, 'overlap_list') && numel(L.overlap_list) >= i && ~isempty(L.overlap_list{i})
                stat(i).overlap = logical(unwrap_mat_cell_numeric(L.overlap_list{i}));
            else
                stat(i).overlap = [];
            end
        end

        s2p.stat = stat;

    catch ME
        cleanup_temp(temp_dir);
        rethrow(ME);
    end

    cleanup_temp(temp_dir);
end


function write_python_converter(py_script)
%WRITE_PYTHON_CONVERTER
% Write a temporary Python script that converts Suite2p .npy outputs
% into a MATLAB-readable .mat file.

    py_code = strjoin([
"import os, sys"
"import numpy as np"
"from scipy.io import savemat"
""
"def opt_load(path, allow_pickle=False):"
"    if os.path.exists(path):"
"        return np.load(path, allow_pickle=allow_pickle)"
"    return None"
""
"def main(folder, out_mat):"
"    F = opt_load(os.path.join(folder, 'F.npy'))"
"    if F is None:"
"        raise FileNotFoundError('F.npy not found')"
""
"    Fneu = opt_load(os.path.join(folder, 'Fneu.npy'))"
"    spks = opt_load(os.path.join(folder, 'spks.npy'))"
"    iscell = opt_load(os.path.join(folder, 'iscell.npy'))"
"    stat = opt_load(os.path.join(folder, 'stat.npy'), allow_pickle=True)"
"    ops = opt_load(os.path.join(folder, 'ops.npy'), allow_pickle=True)"
""
"    if stat is None:"
"        raise FileNotFoundError('stat.npy not found')"
""
"    if ops is not None:"
"        try:"
"            ops = ops.item()"
"        except Exception:"
"            pass"
"    else:"
"        ops = {}"
""
"    mdict = {}"
"    mdict['F'] = np.asarray(F, dtype=np.float32)"
"    if Fneu is not None:"
"        mdict['Fneu'] = np.asarray(Fneu, dtype=np.float32)"
"    if spks is not None:"
"        mdict['spks'] = np.asarray(spks, dtype=np.float32)"
"    if iscell is not None:"
"        mdict['iscell'] = np.asarray(iscell, dtype=np.float32)"
""
"    if isinstance(ops, dict):"
"        if 'Ly' in ops:"
"            mdict['Ly'] = np.array([[ops['Ly']]], dtype=np.float64)"
"        if 'Lx' in ops:"
"            mdict['Lx'] = np.array([[ops['Lx']]], dtype=np.float64)"
"        if 'meanImg' in ops and ops['meanImg'] is not None:"
"            mdict['meanImg'] = np.asarray(ops['meanImg'], dtype=np.float32)"
"        if 'max_proj' in ops and ops['max_proj'] is not None:"
"            mdict['max_proj'] = np.asarray(ops['max_proj'], dtype=np.float32)"
""
"    ypix_list = []"
"    xpix_list = []"
"    lam_list = []"
"    overlap_list = []"
""
"    for roi in stat:"
"        ypix_list.append(np.asarray(roi['ypix']).astype(np.float64).ravel())"
"        xpix_list.append(np.asarray(roi['xpix']).astype(np.float64).ravel())"
""
"        if 'lam' in roi and roi['lam'] is not None:"
"            lam_list.append(np.asarray(roi['lam']).astype(np.float64).ravel())"
"        else:"
"            lam_list.append(np.array([], dtype=np.float64))"
""
"        if 'overlap' in roi and roi['overlap'] is not None:"
"            overlap_list.append(np.asarray(roi['overlap']).astype(np.float64).ravel())"
"        else:"
"            overlap_list.append(np.array([], dtype=np.float64))"
""
"    mdict['ypix_list'] = np.array(ypix_list, dtype=object)"
"    mdict['xpix_list'] = np.array(xpix_list, dtype=object)"
"    mdict['lam_list'] = np.array(lam_list, dtype=object)"
"    mdict['overlap_list'] = np.array(overlap_list, dtype=object)"
""
"    savemat(out_mat, mdict, do_compression=True)"
""
"if __name__ == '__main__':"
"    if len(sys.argv) != 3:"
"        raise SystemExit('Usage: python convert_suite2p_to_mat.py <suite2p_folder> <out_mat>')"
"    main(sys.argv[1], sys.argv[2])"
], newline);

    fid = fopen(py_script, 'w');
    if fid == -1
        error('Could not create temporary Python script.');
    end

    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', py_code);
end


function x = unwrap_mat_cell_numeric(x)
% Handle how scipy.io.savemat object arrays arrive in MATLAB.

    while iscell(x) && numel(x) == 1
        x = x{1};
    end

    if isempty(x)
        x = [];
        return;
    end

    x = double(x(:));
end


function cleanup_temp(temp_dir)
    if exist(temp_dir, 'dir')
        try
            rmdir(temp_dir, 's');
        catch
        end
    end
end