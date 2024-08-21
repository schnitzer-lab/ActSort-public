function [features, time_summary] = get_features(S, T, M_cell, S_cell, T_cell, parforFlag, fastFeatureFlag, progressDlg)
% This function create training samples with hard-coded features
% INPUT
%   [S]         : a matrix of size (n_x x n_y x n_cell)
%   [T]         : a matrix of size (n_cell x n_t)
%   [M_cell]    : a cell array of size (1 x n_cell), each cell contains 
%                 snapshots from movies
%   [S_cell]    : a cell array of size 1 x n_cell, each cell contains the cropped
%                 spatial filter for the corresponding cell
%   [T_cell]    : a cell array of size 1 x n_cell, each cell contains the traces
%                 for the corresponding snapshot
%                 For example, if there are 5 snapshots, each cell contains 1x5 cells
%                 where each cell includes one snapshot
%   [parforFlag]: logical flag that denotes whether to use parallel for loop
%
% OUTPUT
%   [features]  : a matrix of size (n_cell x feature_size). Currently
%                 feature_size = 76
%

% Start the Timer
time_summary = struct;
start_time = posixtime(datetime);

% Get the features
num_cell = size(T, 1);
features = zeros(num_cell, 76);
f_id = 1;

% TRACE (T) BASED METRICS
% ~-~-~-~-~-~-~-~-~-~-~-~-

% Feature 1: Get Trace SNR
start_get_trace_snr = posixtime(datetime);
features(:,f_id) = get_trace_snr(T)';             f_id = f_id + 1;
time_summary.get_trace_snr = posixtime(datetime) - start_get_trace_snr;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 2: Calculate Temporal Corruption
start_temporal_corruption = posixtime(datetime);
features(:,f_id) = temporal_corruption(T);        f_id = f_id + 1;
f_id = f_id + 1; % since the original order of find_trace_std is 4th.
time_summary.temporal_corruption = posixtime(datetime) - start_temporal_corruption;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 4: Calculate Trace Standard Deviation
start_find_trace_std = posixtime(datetime);
features(:,f_id) = find_trace_std(T');            f_id = f_id + 1;
time_summary.find_trace_std = posixtime(datetime) - start_find_trace_std;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 5-11: Calculate other temporal features
if ~fastFeatureFlag
    start_find_temporal_features = posixtime(datetime);
    output = find_temporal_features(T', parforFlag);
    features(:,3) = output(4,:)';
    output(4,:) = [];
    features(:,f_id:f_id+6) = output';                f_id = f_id + 7;
    time_summary.find_temporal_features = posixtime(datetime) - start_find_temporal_features;
else
    time_summary.find_temporal_features = 0;
end

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 11-29: Calculate event features
if ~fastFeatureFlag
    start_compute_event_metrics = posixtime(datetime);
    event_ratio_lst = [1,3,10,30,100,300];
    for eventCur = 1:length(event_ratio_lst)
        [power,fraction,num_events] = compute_event_metrics(T,event_ratio_lst(eventCur),parforFlag);
        features(:,f_id) = power;            f_id = f_id + 1;
        features(:,f_id) = fraction;         f_id = f_id + 1;
        features(:,f_id) = num_events;       f_id = f_id + 1;
    end
    time_summary.compute_event_metrics = posixtime(datetime) - start_compute_event_metrics;
else
    time_summary.compute_event_metrics = 0;
end

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% 2nd parameter is normalized (0-1) low freq cut-off, 
% third is normalized (0-1) high freq cut-off

% Feature 29-34: Calculate fourier feautres
start_fourier_features = posixtime(datetime);
fourier_lst = [0, 0.05; 0.05,0.95;0.5,1;0,0.5;0.95,1];
for eventCur = 1:length(fourier_lst)
features(:,f_id) = fourier_features(T, fourier_lst(eventCur,1), fourier_lst(eventCur,2), parforFlag);     f_id = f_id + 1;
end
time_summary.fourier_features = posixtime(datetime) - start_fourier_features;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 35: Calculate trace similarity
start_trace_similarity = posixtime(datetime);
T_smooth = medfilt1(T, 3, [], 2);
T_norm = zscore(T_smooth, 1, 2) / sqrt(size(T_smooth, 2));
features(:,f_id) = trace_similarity(T_norm, 0.7)';    f_id = f_id + 1;
time_summary.trace_similarity = posixtime(datetime) - start_trace_similarity;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 36: Calculate spike fluorescence
start_spike_fluorescence = posixtime(datetime);
features(:,f_id) = spike_fluorescence(T_norm, 0.99)'; f_id = f_id + 1;
time_summary.spike_fluorescence = posixtime(datetime) - start_spike_fluorescence;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

disp("-- Temporal Features... DONE!")

% FILTER (S) BASED METRICS
% ~-~-~-~-~-~-~-~-~-~-~-~-

% Feature 37: Calculate cell areas
start_get_areas = posixtime(datetime);
features(:,f_id) = get_areas(S, 0.1)';          f_id = f_id + 1;
time_summary.get_areas = posixtime(datetime) - start_get_areas;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 38: Calculate number of cell bodies
start_has_multiple_bodies = posixtime(datetime);
features(:,f_id) = has_multiple_bodies(S, parforFlag);          f_id = f_id + 1;
time_summary.has_multiple_bodies = posixtime(datetime) - start_has_multiple_bodies;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 39: Calculate average pixel value
start_find_avg_pix_vals = posixtime(datetime);
features(:,f_id) = find_avg_pix_vals(S);        f_id = f_id + 1;
time_summary.find_avg_pix_vals = posixtime(datetime) - start_find_avg_pix_vals;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 40: Calculate cell circumferences
start_find_cell_circumference = posixtime(datetime);
features(:,f_id) = find_cell_circumference(S, parforFlag);  f_id = f_id + 1;
time_summary.find_cell_circumference = posixtime(datetime) - start_find_cell_circumference;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 41: Calculate distances to edges
start_find_edge_distances = posixtime(datetime);
features(:,f_id) = find_edge_distances(S, parforFlag);      f_id = f_id + 1;
time_summary.find_edge_distances = posixtime(datetime) - start_find_edge_distances;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 42-43: Calculate circularity metrics (from EXTRACT)
start_get_circularity_metrics = posixtime(datetime);
[h, w, nf] = size(S);
S = reshape(S, h*w, nf);
S = sparse(S);
[circularities, eccentricities] = get_circularity_metrics(S, [h,w], parforFlag);
features(:,f_id) = circularities;                 f_id = f_id + 1;
features(:,f_id) = eccentricities;                f_id = f_id + 1;
time_summary.get_circularity_metrics = posixtime(datetime) - start_get_circularity_metrics;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 44: Calculate mean value of spatial weights
start_get_mean_value = posixtime(datetime);
features(:,f_id) = full(mean(S,1));               f_id = f_id + 1;
time_summary.get_mean_value = posixtime(datetime) - start_get_mean_value;

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 45: Calculate spatial corruption
if ~fastFeatureFlag
    start_spat_corruption = posixtime(datetime);
    features(:,f_id) = compute_spat_corruption(S, [h,w],0,1, parforFlag); f_id = f_id + 1;
    time_summary.spat_corruption = posixtime(datetime) - start_spat_corruption;
    
    % Feature 46: Calculate Maximum Positive Correlation
    start_max_positive_correlation = posixtime(datetime);            
    features(:,f_id) = max_positive_correlation(S);       f_id = f_id + 1;
    time_summary.max_positive_correlation = posixtime(datetime) - start_max_positive_correlation;
else
    time_summary.max_positive_correlation = 0;
end

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

disp("-- Spatial Features... DONE!")

% SPATIOTEMPORAL (S, T and M) BASED METRICS
% ~-~-~-~-~-~-~-~-~-~-~-~-

% --JZ: Combined forloops of 67-70 into one.

% Feature 47-50: Calculate cell epsilon features
if ~fastFeatureFlag
    start_compute_cell_epsilon = posixtime(datetime);
    epsilon = compute_cell_epsilon(S_cell,M_cell,parforFlag);
    f_id_temp = f_id; 
    
    for i=1:size(epsilon,2)
        met = epsilon{i};
        features(i,f_id_temp) = nanmean(met);
        features(i,f_id_temp+1) = min(met);
        features(i,f_id_temp+2) = quantile(met,0.1);
        features(i,f_id_temp+3) = quantile(met,0.2);
    end
    f_id = f_id_temp + 4;
    time_summary.compute_cell_epsilon = posixtime(datetime) - start_compute_cell_epsilon;
else
    time_summary.compute_cell_epsilon = 0;
end

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Features 50-66: Find Spurious Cells
if ~fastFeatureFlag
    start_find_spurious_cells = posixtime(datetime);
    [corr_score, scores_1, scores_2, scores_3] = calculate_spurious_cells_metrics(S_cell, T_cell, M_cell, parforFlag);
    
    features(:,f_id) = corr_score;            f_id = f_id + 1;
    features(:,f_id:f_id+4) = scores_1';       f_id = f_id + 5;
    features(:,f_id:f_id+4) = scores_2';       f_id = f_id + 5;
    features(:,f_id:f_id+4) = scores_3';       f_id = f_id + 5;
    time_summary.find_spurious_cells = posixtime(datetime) - start_find_spurious_cells;
else
    time_summary.find_spurious_cells = 0;
end

% Check if cancelled
if ~isempty(progressDlg) && progressDlg.CancelRequested
    return;
end

% Feature 67-76: Get TQM Metric
start_get_tqm_metric = posixtime(datetime);
event_ratio_lst = [0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9];
num_ratio = length(event_ratio_lst);

% JZ: before Yiqi's final updates, use this temp structure.
for ratioCur = 1:num_ratio
    features(:,f_id) = get_tqm_metric(M_cell,S_cell,T_cell,event_ratio_lst(ratioCur));
    f_id = f_id + 1;
end
time_summary.get_tqm_metric = posixtime(datetime) - start_get_tqm_metric;
% FINISHES WITH THE FEATURE 76

time_summary.TOTAL = posixtime(datetime) - start_time;
disp("-- Spatiotemporal Features... DONE!")
end