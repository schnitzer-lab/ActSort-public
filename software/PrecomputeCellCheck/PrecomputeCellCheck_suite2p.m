function PrecomputeCellCheck_suite2p(suite2p_path, movie_path, varargin)

%INPUT
%   [suite2p_path]: path to Suite2p plane folder, e.g. ".../suite2p/plane0"
%   [movie_path]: path to movie file (currently assumes H5 movie, same as
%                 original PrecomputeCellCheck pipeline)
% OUTPUT
%   Saves a MAT file containing precomputedOutput

    pythoncmd = getPythonCommand(); % [new] debug: let users choose their own python.
    fprintf('python successfully found in: %s \n',char(string(pythoncmd)));
   
    p = inputParser;
    addRequired(p, 'suite2p_path', @(x) (ischar(x) || isstring(x)));
    addRequired(p, 'movie_path', @(x) (ischar(x) || isstring(x)));

    addParameter(p, 'output_path', "", @(x) (ischar(x) || isstring(x)));
    addParameter(p, 'parallel', true, @islogical);
    addParameter(p, 'dt', 1, @isnumeric);
    addParameter(p, 'fast_features', false, @islogical);
    addParameter(p, 'progressDlg', [], @(x) true);
    addParameter(p, 'UIFigure', [], @(x) true);

    addParameter(p, 'trace_source', 'Fcorr', @(x) ischar(x) || isstring(x));
    addParameter(p, 'cell_only', true, @islogical);
    addParameter(p, 'exclude_overlap', true, @islogical);
    % addParameter(p, 'python_cmd', "/Users/mitiao/opt/anaconda3/envs/matlab_py/bin/python", ...
    % @(x) (ischar(x) || isstring(x)));   % [new] debug: path notfound.
    
    addParameter(p, 'python_cmd', pythoncmd, ...
    @(x) (ischar(x) || isstring(x)));
    
    parse(p, suite2p_path, movie_path, varargin{:});
    
    output_path      = p.Results.output_path;
    parallel         = p.Results.parallel;
    dt               = p.Results.dt;
    fast_features    = p.Results.fast_features;
    progressDlg      = p.Results.progressDlg;
    UIFigure         = p.Results.UIFigure;
    trace_source     = char(string(p.Results.trace_source));
    cell_only        = p.Results.cell_only;
    exclude_overlap  = p.Results.exclude_overlap;
    python_cmd       = char(string(p.Results.python_cmd));

    % Start parallel pool if requested
    if parallel && isempty(gcp('nocreate'))
        parpool;
        if ~isempty(UIFigure)
            figure(UIFigure);
        end
    end

    TIME_SUMMARY = struct;
    PRECOMPUTE_TIME_SUMMARY = struct;
    start_time = posixtime(datetime);

    update_progress_safe("Starting Suite2p precomputation...", 0, progressDlg);
    
    % STEP 0: Read movie dataset name and size
    [dataset_name, m_size] = extract_dataset(movie_path, UIFigure);
    m_size = m_size([2 1 3]);
    if isnan(dataset_name)
        disp("Stopping precomputation...");
        return;
    end

    % STEP 1: Load movie if possible, otherwise process in chunks later
    try
        movie = single(h5read(movie_path, dataset_name));
        movie = permute(movie, [2 1 3]);
        inMemory = true;
        PRECOMPUTE_TIME_SUMMARY.h5read = posixtime(datetime) - start_time;
    catch
        inMemory = false;
        movie = [];
        warning("H5 file is too large for memory. It will be processed in chunks.");
        PRECOMPUTE_TIME_SUMMARY.h5read = 0;
    end

    if is_cancelled(progressDlg, UIFigure); return; end
    update_progress_safe("Loading movie... DONE!", 0.08, progressDlg);

    % STEP 2: Load Suite2p outputs and convert to core ActSort inputs
    start_load_s2p = posixtime(datetime);

    try
        s2p = load_suite2p_from_npy_via_python(suite2p_path, python_cmd);
    catch ME
        raise_alert_safe("Failed to load Suite2p outputs: " + string(ME.message), ...
            'error', progressDlg, UIFigure);
        rethrow(ME);
    end

    PRECOMPUTE_TIME_SUMMARY.load_suite2p = posixtime(datetime) - start_load_s2p;
    update_progress_safe("Loading Suite2p outputs... DONE!", 0.16, progressDlg);

    % STEP 3: Convert Suite2p outputs -> spatial_weights, traces, max_im
    start_parse_s2p = posixtime(datetime);

    try
        [spatial_weights, traces, max_im, suite2p_info] = ...
            parse_suite2p_core(s2p, m_size, trace_source, cell_only, exclude_overlap);
    catch ME
        raise_alert_safe("Suite2p outputs do not contain expected fields or shapes.", ...
            'error', progressDlg, UIFigure);
        rethrow(ME);
    end

    PRECOMPUTE_TIME_SUMMARY.parse_suite2p = posixtime(datetime) - start_parse_s2p;

    if is_cancelled(progressDlg, UIFigure); return; end

    % Movie / ROI size consistency check
    [H, W, ~] = size(spatial_weights);
    if H ~= m_size(1) || W ~= m_size(2)
        msg = sprintf(["Input files do not match. Movie size is [%dx%dx%d] but " + ...
            "Suite2p ROI stack is [%dx%dx%d]. Please verify your input!"], ...
            m_size(1), m_size(2), m_size(3), H, W, size(traces,1));
        raise_alert_safe(msg, 'error', progressDlg, UIFigure);
        return;
    end

    % Convert to ndSparse to match original ActSort expectations
    if ~issparse(spatial_weights)
        try
            spatial_weights = ndSparse(spatial_weights);
        catch
            % If ndSparse is not available, leave as dense; some helper
            % functions may still work, but original pipeline expects ndSparse.
            warning("ndSparse conversion failed; keeping spatial_weights dense.");
        end
    end

    % Downsample traces if needed
    if dt == 1
        traces_dt = traces;
        PRECOMPUTE_TIME_SUMMARY.downsample_time = 0;
    else
        start_downsample_time = posixtime(datetime);
        traces_dt = downsample_time(traces', dt)';
        PRECOMPUTE_TIME_SUMMARY.downsample_time = posixtime(datetime) - start_downsample_time;
    end

    update_progress_safe("Parsing Suite2p outputs... DONE!", 0.24, progressDlg);
    update_progress_safe("Processing ROI geometry...", [], progressDlg);

    % STEP 4: Find cell centers
    start_find_cell_centers = posixtime(datetime);
    cellCenters = find_cell_centers(spatial_weights);
    PRECOMPUTE_TIME_SUMMARY.find_cell_centers = posixtime(datetime) - start_find_cell_centers;

    % STEP 5: Find spike indices from traces
    start_find_spike_indices = posixtime(datetime);
    numSpikes = 5;
    snapshotFrameSize = 10;
    spikeIdxs = find_spike_indices(traces', snapshotFrameSize, numSpikes, parallel);
    PRECOMPUTE_TIME_SUMMARY.find_spike_indices = posixtime(datetime) - start_find_spike_indices;

    % STEP 6: Find cell boundaries
    start_find_cell_boundaries = posixtime(datetime);
    cellBoundaries = find_cell_boundaries(spatial_weights, parallel);
    PRECOMPUTE_TIME_SUMMARY.find_cell_boundaries = posixtime(datetime) - start_find_cell_boundaries;

    if is_cancelled(progressDlg, UIFigure); return; end

    % STEP 7: Find neighbor indices
    start_find_neighbor_idxs = posixtime(datetime);
    MARGIN = 7;
    neighbor_idxs = find_neighbor_idxs(cellBoundaries, cellCenters, MARGIN, [H W]);
    PRECOMPUTE_TIME_SUMMARY.find_neighbor_idxs = posixtime(datetime) - start_find_neighbor_idxs;

    % STEP 8: Save neighbor boundaries
    start_find_neighbor_boundaries = posixtime(datetime);
    neighborBoundaries = find_neighbor_boundaries(cellBoundaries, neighbor_idxs);
    PRECOMPUTE_TIME_SUMMARY.find_neighbor_boundaries = posixtime(datetime) - start_find_neighbor_boundaries;

    % STEP 9: Compute local viewing limits
    start_find_viewing_limits = posixtime(datetime);
    limits = find_viewing_limits(cellBoundaries, neighborBoundaries, MARGIN, [H W]);
    PRECOMPUTE_TIME_SUMMARY.find_viewing_limits = posixtime(datetime) - start_find_viewing_limits;

    % STEP 10: Cell boundaries in snapshot coordinates
    start_find_snapshot_cell_boundaries = posixtime(datetime);
    snapshotCellBoundaries = find_snapshot_cell_boundaries(cellBoundaries, limits);
    PRECOMPUTE_TIME_SUMMARY.find_snapshot_cell_boundaries = ...
        posixtime(datetime) - start_find_snapshot_cell_boundaries;

    % STEP 11: Update neighbor boundaries into snapshot coordinates
    start_update_neighbor_boundaries = posixtime(datetime);
    neighborBoundaries = update_neighbor_boundaries(neighborBoundaries, limits);
    PRECOMPUTE_TIME_SUMMARY.update_neighbor_boundaries = ...
        posixtime(datetime) - start_update_neighbor_boundaries;

    update_progress_safe("Processing ROI geometry... DONE!", 0.40, progressDlg);
    update_progress_safe("Processing movie snapshots...", [], progressDlg);

    % STEP 12: Capture snapshots from movie
    start_capture_snapshots = posixtime(datetime);

    if inMemory
        snapshots = capture_snapshots_from_memory(movie, spikeIdxs, limits, ...
            snapshotFrameSize, numSpikes, dt);
    else
        snapshots = capture_snapshots_in_chunks(movie_path, dataset_name, ...
            spikeIdxs, limits, snapshotFrameSize, numSpikes, dt);
    end

    PRECOMPUTE_TIME_SUMMARY.capture_snapshots = posixtime(datetime) - start_capture_snapshots;

    if is_cancelled(progressDlg, UIFigure); return; end

    % STEP 13: Snapshot traces
    start_find_snapshot_traces = posixtime(datetime);
    snapshot_traces = find_snapshot_traces(traces_dt', spikeIdxs, snapshotFrameSize, dt);
    PRECOMPUTE_TIME_SUMMARY.find_snapshot_traces = posixtime(datetime) - start_find_snapshot_traces;

    % STEP 14: Snapshot filters
    start_find_snapshot_filters = posixtime(datetime);
    snapshot_filters = find_snapshot_filters(spatial_weights, limits);
    PRECOMPUTE_TIME_SUMMARY.find_snapshot_filters = posixtime(datetime) - start_find_snapshot_filters;

    % STEP 15: Snapshot display limits
    start_compute_snapshot_clims = posixtime(datetime);
    snapshotCLims = compute_snapshot_clims(snapshots);
    PRECOMPUTE_TIME_SUMMARY.compute_snapshot_clims = ...
        posixtime(datetime) - start_compute_snapshot_clims;

    if is_cancelled(progressDlg, UIFigure); return; end

    % STEP 16: max projection if not available from Suite2p
    if isempty(max_im)
        start_create_max_im = posixtime(datetime);
        if inMemory
            max_im = max(movie, [], 3);
        else
            max_im = create_max_im_in_chunks(movie_path, dataset_name, m_size);
        end
        PRECOMPUTE_TIME_SUMMARY.create_max_im = posixtime(datetime) - start_create_max_im;
    else
        PRECOMPUTE_TIME_SUMMARY.create_max_im = 0;
    end

    update_progress_safe("Processing movie snapshots... DONE!", 0.60, progressDlg);
    update_progress_safe("Extracting features...", [], progressDlg);

    % STEP 17: Create precomputedOutput struct
    precomputedOutput = create_precomputed_output();
    PRECOMPUTE_TIME_SUMMARY.TOTAL = posixtime(datetime) - start_time;

    if is_cancelled(progressDlg, UIFigure); return; end

    % STEP 18: Feature extraction
    precomputedOutput_for_features = precomputedOutput;
    precomputedOutput_for_features.traces = precomputedOutput_for_features.traces';

    [features, FEATURE_TIME_SUMMARY] = create_features(precomputedOutput_for_features, parallel, fast_features);
    precomputedOutput.features = features;

    %FEATURE_TIME_SUMMARY = struct;
    %FEATURE_TIME_SUMMARY.TOTAL = 0;
    %precomputedOutput.features = [];

    if is_cancelled(progressDlg, UIFigure); return; end

    update_progress_safe("Feature extraction... DONE!", 0.90, progressDlg);
    update_progress_safe("Saving the precomputed sorting file...", [], progressDlg);

    % STEP 19: INFO struct
    INFO = struct;

    [~, suite2p_folder_name] = fileparts(char(suite2p_path));
    INFO.suite2p_folder = suite2p_folder_name;

    [~, movie_file_name, movie_file_ext] = fileparts(char(movie_path));
    INFO.movie_file_name = strcat(movie_file_name, movie_file_ext);

    INFO.dataset_name = dataset_name;
    INFO.date_created = datestr(datetime('now'), 'yyyy-mm-dd HH:MM:SS');

    INFO.parallel = parallel;
    INFO.inMemory = inMemory;
    INFO.dt = dt;
    INFO.fast_features = fast_features;
    INFO.trace_source = trace_source;
    INFO.cell_only = cell_only;
    INFO.exclude_overlap = exclude_overlap;

    INFO.n_cells = size(traces, 1);
    INFO.n_frames = size(traces, 2);
    INFO.image_height = H;
    INFO.image_width = W;

    if isfield(suite2p_info, 'has_iscell')
        INFO.has_iscell = suite2p_info.has_iscell;
    end
    if isfield(suite2p_info, 'kept_idx')
        INFO.kept_idx = suite2p_info.kept_idx;
    end

    [system_model, cpu_info] = get_system_info();
    INFO.system_model = system_model;
    INFO.cpu_info = cpu_info;

    if isempty(UIFigure)
        INFO.platform = 'Command Window';
    else
        INFO.platform = 'GUI';
    end

    TIME_SUMMARY.PRECOMPUTE_TIME_SUMMARY = PRECOMPUTE_TIME_SUMMARY;
    TIME_SUMMARY.FEATURE_TIME_SUMMARY = FEATURE_TIME_SUMMARY;
    TIME_SUMMARY.TOTAL = FEATURE_TIME_SUMMARY.TOTAL + PRECOMPUTE_TIME_SUMMARY.TOTAL;
    INFO.TIME_SUMMARY = TIME_SUMMARY;

    precomputedOutput.INFO = INFO;

    % STEP 20: Save
    if strlength(output_path) > 0
        [~, ~, ext] = fileparts(output_path);

        if strcmp(ext, '.mat')
            newFileName = output_path;
        elseif isfolder(output_path)
            defaultName = "precomputed_suite2p_" + suite2p_folder_name + ".mat";
            newFileName = fullfile(output_path, defaultName);
        else
            newFileName = "precomputed_suite2p_" + suite2p_folder_name + ".mat";
        end
    else
        newFileName = "precomputed_suite2p_" + suite2p_folder_name + ".mat";
    end

    save(newFileName, 'precomputedOutput', '-v7.3');

    update_progress_safe("Sorting file created!", 1, progressDlg);
    raise_alert_safe("-- File saved as " + string(newFileName), 'success', progressDlg, UIFigure);
    disp("-- Suite2p precomputation done in: " + num2str(TIME_SUMMARY.TOTAL) + "s");

    % Nested helper: assemble precomputedOutput
    % =====================================================================
    function precomputedOutput = create_precomputed_output()
        precomputedOutput = struct;
        precomputedOutput.spatial_weights = spatial_weights;
        precomputedOutput.traces = single(traces);
        precomputedOutput.cellCenters = single(cellCenters);
        precomputedOutput.spikeIdxs = single(spikeIdxs);
        precomputedOutput.cellBoundaries = cellBoundaries;
        precomputedOutput.snapshots = snapshots;
        precomputedOutput.snapshot_filters = snapshot_filters;
        precomputedOutput.snapshot_traces = snapshot_traces;
        precomputedOutput.snapshotCellBoundaries = snapshotCellBoundaries;
        precomputedOutput.snapshotCLims = snapshotCLims;
        precomputedOutput.neighborBoundaries = neighborBoundaries;
        precomputedOutput.max_im = single(max_im);
    end
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


function v = to_col_vector(v)
    v = v(:);
end


function cleanup_temp(temp_dir)
    if exist(temp_dir, 'dir')
        try
            rmdir(temp_dir, 's');
        catch
        end
    end
end


function tf = is_cancelled(progressDlg, UIFigure)
    tf = false;
    if ~isempty(progressDlg)
        try
            if progressDlg.CancelRequested
                if ~isempty(UIFigure)
                    figure(UIFigure);
                end
                close(progressDlg);
                tf = true;
            end
        catch
        end
    end
end


function update_progress_safe(msg, val, progressDlg)
    try
        if nargin == 3
            update_progress(msg, val, progressDlg);
        else
            update_progress(msg, progressDlg);
        end
    catch
        % no-op
    end
end


function raise_alert_safe(msg, type, progressDlg, UIFigure)
    try
        raise_alert(msg, type, progressDlg, UIFigure);
    catch
        warning('%s', msg);
    end
end