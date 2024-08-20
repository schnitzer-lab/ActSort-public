function PrecomputeCellCheck(matfile_path, h5file_path, varargin)
% This function performs a series of precomputations on cellular data from 
% a movie and its corresponding matfile. It is designed to facilitate 
% future calculations and GUI visualizations by preprocessing various 
% aspects of the data, such as cell traces, spikes, and boundaries. 
% The function handles data both in-memory and in cases where the movie 
% is too large to fit in memory, reading it in chunks.
%
% INPUT
%   [matfile_path] : A string or char array specifying the path to the .mat file.
%   [movie_path] : A string or char array specifying the path to the movie file.
%   varargin : Variable input arguments including:
%       - 'parallel': Flag to enable parallel processing. True by default.
%       - 'dt': Downsampling factor for traces.
%       - 'fast_features': Flag to enable fast feature calculation (by omitting some features).
%       - 'progressDlg': Handle to the progress dialog in GUI (optional).
%       - 'UIFigure': Handle to the UIFigure in GUI (optional).
%
% OUTPUT
%   The function saves a precomputed file containing all the processed data 
%   structures, which include spatial weights, traces, cell centers, spike 
%   indices, boundaries, snapshots, filters, contrast limits, maximum projection, 
%   and cell labels. This file is used for subsequent analysis and GUI display.
%   

    p = inputParser;
    addRequired(p, 'matfile_path', @(x) (ischar(x) || isstring(x)));
    addRequired(p, 'movie_path', @(x) (ischar(x) || isstring(x)));
    addParameter(p, 'parallel', true, @islogical);
    addParameter(p, 'dt', 1, @isnumeric);
    addParameter(p, 'fast_features', false, @islogical);
    addParameter(p, 'progressDlg', [], @isobject);
    addParameter(p, 'UIFigure', [], @isobject);

    parse(p, matfile_path, h5file_path, varargin{:});
    
    % Parse input arguments
    parallel = p.Results.parallel;
    dt = p.Results.dt;
    progressDlg = p.Results.progressDlg;
    UIFigure = p.Results.UIFigure;
    fast_features = p.Results.fast_features; 

    % Run parallel pool if parallel is on
    if parallel && isempty(gcp('nocreate'))
        parpool;
        % Bring the GUI window forward
        if ~isempty(UIFigure)xmlImportOptions
            figure(UIFigure)
        end
    end

    % Keep the calculation times in a struct
    TIME_SUMMARY = struct;
    PRECOMPUTE_TIME_SUMMARY = struct;
    start_time = posixtime(datetime);

    update_progress("Starting precomputation...", 0, progressDlg); %Update progress

    [dataset_name, m_size] = extract_dataset(h5file_path, UIFigure);
    % Return if user wants to exit
    if isnan(dataset_name)
        disp("Stopping precomputation...")
        return;
    end

    % Load the specified dataset
    try
        movie = single(h5read(h5file_path, dataset_name));
        inMemory = true; %if movie can be fitted into ram, go for it.
        PRECOMPUTE_TIME_SUMMARY.h5read = posixtime(datetime) - start_time;
    catch
        inMemory = false; %if movie is too large for ram, read in chunks
        warning("H5 file is too large for the memory. It will be processed in chunks!")
        PRECOMPUTE_TIME_SUMMARY.h5read = 0;
    end

    % Check if cancelled
    if ~isempty(progressDlg) && progressDlg.CancelRequested
        figure(UIFigure);
        close(progressDlg);
        return;
    end

    update_progress("Loading H5 File... DONE!", 0.1, progressDlg); %Update progress

    % Load the .mat file
    start_load_mat_file = posixtime(datetime);

    try
        extract_output = load(matfile_path);
    catch
        raise_alert("Invalid Files!",'error', progressDlg, UIFigure);
        return
    end

    update_progress("Loading MAT File... DONE!", 0.2, progressDlg); %Update progress
    PRECOMPUTE_TIME_SUMMARY.load_mat_file = posixtime(datetime) - start_load_mat_file;

    % Check if cancelled
    if ~isempty(progressDlg) && progressDlg.CancelRequested
        figure(UIFigure);
        close(progressDlg);
        return;
    end

    % STEP 1: Get Traces and Spatial Weights.
    try
        [spatial_weights, traces, max_im] = parse_extract_output(extract_output);
    catch
        msg = "EXTRACT output doesn't contain necessary components. Please verify" + ...
        " your input!";
        raise_alert(msg, "error",progressDlg,UIFigure);
    end

    % Check if the movie and .mat file match
    [H, W, ~] = size(spatial_weights);
    if H ~= m_size(1) || W ~= m_size(2)
        msg = sprintf("Input files don't match. Movie has size [%dx%dx%d] while the EXTRACT output is [%dx%dx%d]." + ...
            " Please verify your input!",m_size(1),m_size(2),m_size(3),H,W,size(traces,1));
        raise_alert(msg, "error",progressDlg,UIFigure);
        return
    end

    % Downsample traces if the movie was downsampled
    if dt == 1
        traces_dt = traces;
        PRECOMPUTE_TIME_SUMMARY.downsample_time = 0;
    else
        start_downsample_time = posixtime(datetime);
        traces_dt = downsample_time(traces',dt)';
        PRECOMPUTE_TIME_SUMMARY.downsample_time = posixtime(datetime) - start_downsample_time;
    end

    update_progress("Processing MAT File...", [] , progressDlg); %Update progress

    % STEP 2: Find Cell Centers
    start_find_cell_centers = posixtime(datetime);
    
    cellCenters = find_cell_centers(spatial_weights);

    PRECOMPUTE_TIME_SUMMARY.find_cell_centers = posixtime(datetime) - start_find_cell_centers;

    % STEP 3: Find Spike Point Indices 
    start_find_spike_indices = posixtime(datetime);
    
    numSpikes = 5;
    snapshotFrameSize = 10;
    spikeIdxs = find_spike_indices(traces, snapshotFrameSize, numSpikes, parallel);

    PRECOMPUTE_TIME_SUMMARY.find_spike_indices = posixtime(datetime) - start_find_spike_indices;
    
    % STEP 4: Find Cell Boundaries
    start_find_cell_boundaries = posixtime(datetime);
    
    cellBoundaries = find_cell_boundaries(spatial_weights, parallel);

    PRECOMPUTE_TIME_SUMMARY.find_cell_boundaries = posixtime(datetime) - start_find_cell_boundaries;
    % Check if cancelled
    if ~isempty(progressDlg) && progressDlg.CancelRequested
        figure(UIFigure);
        close(progressDlg);
        return;
    end

    % STEP 5: Find Neighbor Indices in Snapshots for each cell
    start_find_neighbor_idxs = posixtime(datetime);
    
    MARGIN = 7; % Could be adjusted, window width to capture snapshot
    neighbor_idxs = find_neighbor_idxs(cellBoundaries, cellCenters, MARGIN, [H W]);

    PRECOMPUTE_TIME_SUMMARY.find_neighbor_idxs = posixtime(datetime) - start_find_neighbor_idxs;
    
    % STEP 6: Saving Neighbor Borders in an Array
    start_find_neighbor_boundaries = posixtime(datetime);

    neighborBoundaries = find_neighbor_boundaries(cellBoundaries, neighbor_idxs);

    PRECOMPUTE_TIME_SUMMARY.find_neighbor_boundaries = posixtime(datetime) - start_find_neighbor_boundaries;

    % STEP 7: Calculating Lower and Upper Viewing Limits
    start_find_viewing_limits = posixtime(datetime);
    
    limits = find_viewing_limits(cellBoundaries, neighborBoundaries, MARGIN, [H W]);
    
    PRECOMPUTE_TIME_SUMMARY.find_viewing_limits = posixtime(datetime) - start_find_viewing_limits;
    
    % STEP 8: Finding Cell Boundaries in Snapshots
    start_find_snapshot_cell_boundaries = posixtime(datetime);

    snapshotCellBoundaries = find_snapshot_cell_boundaries(cellBoundaries, limits);
    
    PRECOMPUTE_TIME_SUMMARY.find_snapshot_cell_boundaries = posixtime(datetime) - start_find_snapshot_cell_boundaries;
    
    % STEP 9: Updating Neighbor Boundaries in Snapshots 
    start_update_neighbor_boundaries = posixtime(datetime);
    
    neighborBoundaries = update_neighbor_boundaries(neighborBoundaries, limits);

    PRECOMPUTE_TIME_SUMMARY.update_neighbor_boundaries = posixtime(datetime) - start_update_neighbor_boundaries;
    
    update_progress("Processing MAT File... DONE!", 0.4, progressDlg); % Update progress
    update_progress("Processing H5 File...", [], progressDlg); % Update progress

    % STEP 10: Capture Snapshots
    start_capture_snapshots = posixtime(datetime);

    if inMemory
        snapshots = capture_snapshots_from_memory(movie, spikeIdxs, limits, snapshotFrameSize, numSpikes, dt);
    else
        snapshots = capture_snapshots_in_chunks(h5file_path, dataset_name, spikeIdxs, limits, snapshotFrameSize, numSpikes, dt);
    end

    PRECOMPUTE_TIME_SUMMARY.capture_snapshots = posixtime(datetime) - start_capture_snapshots;
    % Check if cancelled
    if ~isempty(progressDlg) && progressDlg.CancelRequested
        figure(UIFigure);
        close(progressDlg);
        return;
    end

    % STEP 11: Find Snapshot Traces
    start_find_snapshot_traces = posixtime(datetime);
    
    snapshot_traces = find_snapshot_traces(traces_dt, spikeIdxs, snapshotFrameSize, dt);

    PRECOMPUTE_TIME_SUMMARY.find_snapshot_traces = posixtime(datetime) - start_find_snapshot_traces;

    % STEP 12: Find Snapshot Filters
    start_find_snapshot_filters = posixtime(datetime);
    
    snapshot_filters = find_snapshot_filters(spatial_weights, limits);
    
    PRECOMPUTE_TIME_SUMMARY.find_snapshot_filters = posixtime(datetime) - start_find_snapshot_filters;
    
    
    % STEP 13: Compute Snapshot Contrast Limits (CLims)
    start_compute_snapshot_clims = posixtime(datetime);

    snapshotCLims = compute_snapshot_clims(snapshots);
    
    PRECOMPUTE_TIME_SUMMARY.compute_snapshot_clims = posixtime(datetime) - start_compute_snapshot_clims;

    % Check if cancelled
    if ~isempty(progressDlg) && progressDlg.CancelRequested
        figure(UIFigure);
        close(progressDlg);
        return;
    end

    % STEP 14: Create the Maximum Projection

    if isempty(max_im)
        start_create_max_im = posixtime(datetime);
        if inMemory
            max_im = max(movie,[],3);
        else
            max_im = create_max_im_in_chunks(h5file_path, dataset_name, m_size);
        end
        PRECOMPUTE_TIME_SUMMARY.create_max_im = posixtime(datetime) - start_create_max_im;
    else
        PRECOMPUTE_TIME_SUMMARY.create_max_im = 0;
    end

    update_progress("Processing H5 File... DONE!", 0.6, progressDlg); %Update progress
    update_progress("Extracting Features...", [], progressDlg); %Update progress
    
    % STEP 15: Initiate cellLabels
    cellLabels = zeros(size(spatial_weights,3),1,'int8');

    % STEP 16: Create the output structure
    precomputedOutput = create_precomputed_output();
    PRECOMPUTE_TIME_SUMMARY.TOTAL = posixtime(datetime) - start_time;

    % Check if cancelled
    if ~isempty(progressDlg) && progressDlg.CancelRequested
        figure(UIFigure);
        close(progressDlg);
        return;
    end

    % STEP 17: Extract features
    [features, FEATURE_TIME_SUMMARY] = create_features(precomputedOutput, parallel, fast_features);
    precomputedOutput.features = features;

    % Check if cancelled
    if ~isempty(progressDlg) && progressDlg.CancelRequested
        figure(UIFigure);
        close(progressDlg);
        return;
    end
    
    update_progress("Feature extraction... DONE!", 0.9, progressDlg); %Update progress
    update_progress("Saving the precomputed sorting file...", [], progressDlg);

    % Step 18: Write the INFO structure
    INFO = struct;

    % Add file info
    [~,mat_file_name,mat_file_ext] = fileparts(matfile_path);
    INFO.mat_file_name = strcat(mat_file_name, mat_file_ext);
    [~,h5_file_name,h5_file_ext] = fileparts(h5file_path);
    INFO.h5_file_name = strcat(h5_file_name, h5_file_ext);
    INFO.dataset_name = dataset_name;
    currentDateTime = datetime('now');
    formattedDateTime = datestr(currentDateTime, 'yyyy-mm-dd HH:MM:SS');
    INFO.date_created = formattedDateTime;

    % Add runtime info
    INFO.parallel = parallel;
    INFO.inMemory = inMemory;
    INFO.dt = dt;
    INFO.fast_features = fast_features;

    % Add system info
    [system_model, cpu_info]  = get_system_info();
    INFO.system_model = system_model;
    INFO.cpu_info = cpu_info;
    
    if isempty(UIFigure)
        INFO.platform = 'Command Window';
    else
        INFO.platform = 'GUI';
    end

    % Add time summaries
    TIME_SUMMARY.PRECOMPUTE_TIME_SUMMARY = PRECOMPUTE_TIME_SUMMARY;
    TIME_SUMMARY.FEATURE_TIME_SUMMARY = FEATURE_TIME_SUMMARY;
    TIME_SUMMARY.TOTAL = FEATURE_TIME_SUMMARY.TOTAL + PRECOMPUTE_TIME_SUMMARY.TOTAL;
    INFO.TIME_SUMMARY = TIME_SUMMARY;

    precomputedOutput.INFO = INFO;  

    % STEP 19: Save the output structure as .m file
    newFileName = "precomputed_" + strcat(mat_file_name, mat_file_ext);
    save(newFileName, 'precomputedOutput', '-v7.3');

    update_progress("Sorting file created!", 1, progressDlg)
    raise_alert("-- File saved as " + newFileName, 'success', progressDlg, UIFigure)
    disp("-- Precomputation done in: " + num2str(TIME_SUMMARY.TOTAL) +"s")


    %~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~%


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
        precomputedOutput.cellLabels = cellLabels;
    end
end