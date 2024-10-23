function [output] = find_temporal_features(T, parforFlag)
% This function finds the temporal features
% [T]           : Trace activity and assumed to be [data x num_cells]
% [parforFlag]  : Boolean to activate the parallel computing.
% [output]      : Computed features

[~,numCells] = size(T);

T1 = T ./max(T,[],1);
T2 = normalize(T,'range');

T = shift_traces_to_positive(T); % Enforce nonnegativity

num_spikes = zeros(1,numCells);

avg_width_all = zeros(1,numCells,'single');
avg_width_best = zeros(1,numCells,'single');

trace_width_std_all = zeros(1,numCells,'single');
trace_width_std_best = zeros(1,numCells,'single');

time_elapsed_spikes1 = zeros(1,numCells);
time_elapsed_spikes2 = zeros(1,numCells);
time_elapsed_spikes3 = zeros(1,numCells);

if parforFlag
    parfor i = 1:numCells
        % find_num_bad_spikes
        traceData = T1(:, i);
    
        MPP = max(quantile(traceData,0.9)*0.5,0.1);
        [~,bestSpikeIndices] = findpeaks(traceData,'MinPeakProminence',MPP);
        [~,allSpikeIndices] = findpeaks(traceData);
        num_spikes(i) = numel(allSpikeIndices)-numel(bestSpikeIndices);
    
        % find_avg_peak_width / find_trace_width_std
        traceData = T2(:,i);
    
        MPP = quantile(traceData,0.9)*0.5;
        [~,~,w,~] = findpeaks(traceData,'WidthReference','halfheight');
        avg_width_all(i) = sum(w(:));
        trace_width_std_all(i) = std(w);
        [~,~,w,~] = findpeaks(traceData,'MinPeakProminence',MPP,'WidthReference','halfheight');
        avg_width_best(i) = sum(w(:));
        trace_width_std_best(i) = std(w);
    
        % find_time_elapsed_spikes
        traceData = T(:, i);
        MPP = quantile(traceData,0.9)*0.5;
%         if MPP <= 0
%             MPP = std(traceData);
%         end
        [~,goodSpikeIndices] = findpeaks(traceData,'MinPeakProminence',MPP);
        [~,allSpikeIndices] = findpeaks(traceData);
        badSpikeIndices= setdiff(allSpikeIndices, goodSpikeIndices);
        
        if ~isempty(goodSpikeIndices)
            time_elapsed_spikes1(i) = sum(diff(goodSpikeIndices))/numel(goodSpikeIndices);
        end
        if ~isempty(badSpikeIndices)
            time_elapsed_spikes2(i) = sum(diff(badSpikeIndices))/numel(badSpikeIndices);
        end
        if ~isempty(allSpikeIndices)
            time_elapsed_spikes3(i) = sum(diff(allSpikeIndices))/numel(allSpikeIndices);
        end
    end
else
    for i = 1:numCells
        % find_num_bad_spikes
        traceData = T1(:, i);
    
        MPP = max(quantile(traceData,0.9)*0.5,0.1);
        [~,bestSpikeIndices] = findpeaks(traceData,'MinPeakProminence',MPP);
        [~,allSpikeIndices] = findpeaks(traceData);
        num_spikes(i) = numel(allSpikeIndices)-numel(bestSpikeIndices);
    
        % find_avg_peak_width / find_trace_width_std
        traceData = T2(:,i);
    
        MPP = quantile(traceData,0.9)*0.5;
        [~,~,w,~] = findpeaks(traceData,'WidthReference','halfheight');
        avg_width_all(i) = sum(w(:));
        trace_width_std_all(i) = std(w);
        [~,~,w,~] = findpeaks(traceData,'MinPeakProminence',MPP,'WidthReference','halfheight');
        avg_width_best(i) = sum(w(:));
        trace_width_std_best(i) = std(w);
    
        % find_time_elapsed_spikes
        traceData = T(:, i);
        MPP = quantile(traceData,0.9)*0.5;
%         if MPP <= 0
%             MPP = std(traceData);
%         end
        [~,goodSpikeIndices] = findpeaks(traceData,'MinPeakProminence',MPP);
        [~,allSpikeIndices] = findpeaks(traceData);
        badSpikeIndices= setdiff(allSpikeIndices, goodSpikeIndices);
        
        if ~isempty(goodSpikeIndices)
            time_elapsed_spikes1(i) = sum(diff(goodSpikeIndices))/numel(goodSpikeIndices);
        end
        if ~isempty(badSpikeIndices)
            time_elapsed_spikes2(i) = sum(diff(badSpikeIndices))/numel(badSpikeIndices);
        end
        if ~isempty(allSpikeIndices)
            time_elapsed_spikes3(i) = sum(diff(allSpikeIndices))/numel(allSpikeIndices);
        end
    end
end
output = [time_elapsed_spikes1; time_elapsed_spikes2; time_elapsed_spikes3;num_spikes;...
    avg_width_all; avg_width_best; trace_width_std_all; ...
    trace_width_std_best];

% output.num_spikes = num_spikes;
% 
% output.avg_width_all  = avg_width_all;
% output.avg_width_best = avg_width_best;
% output.trace_width_std_all  = trace_width_std_all;
% output.trace_width_std_best = trace_width_std_best;
% 
% output.t_good = time_elapsed_spikes(1,:);
% output.t_bad  = time_elapsed_spikes(2,:);
% output.t_all  = time_elapsed_spikes(3,:);