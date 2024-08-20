function [trace_width_std_all, trace_width_std_best] = find_trace_width_std(T)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Calculates the standard deviation of spike width within cell traces.
% trace_width_std_all calculates the std of all spikes.
% trace_width_std_best calculates the std of best spikes.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
[~, numCells] = size(T);
trace_width_std_all = zeros(1,numCells,'single');
trace_width_std_best = zeros(1,numCells,'single');
T = normalize(T,'range');

for i = 1:numCells
    traceData = T(:,i);

    MPP = quantile(traceData,0.9)*0.5;
    [~,~,w,~] = findpeaks(traceData,'WidthReference','halfheight');
    trace_width_std_all(i) = std(w);
    [~,~,w,~] = findpeaks(traceData,'MinPeakProminence',MPP,'WidthReference','halfheight');
    trace_width_std_best(i) = std(w);
end
end