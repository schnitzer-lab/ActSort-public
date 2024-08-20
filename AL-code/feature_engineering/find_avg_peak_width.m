function [avg_width_all,avg_width_best] = find_avg_peak_width(T)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Find average peak width within trace activity.
% avg_width_all takes the average of all the peaks found in trace.
% avg_width_bestspikes takes the average of non-noisy spikes found in trace.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
[~, numCells] = size(T);
avg_width_all = zeros(1,numCells,'single');
avg_width_best = zeros(1,numCells,'single');
T = normalize(T,'range');

for i = 1:numCells
    traceData = T(:,i);

    MPP = quantile(traceData,0.9)*0.5;
    [~,~,w,~] = findpeaks(traceData,'WidthReference','halfheight');
    avg_width_all(i) = sum(w(:));
    [~,~,w,~] = findpeaks(traceData,'MinPeakProminence',MPP,'WidthReference','halfheight');
    avg_width_best(i) = sum(w(:));
end
end