function trace_std = find_trace_std(T)
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
% Calculates the standard deviation within cell traces.
%~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-~-
T = normalize(T,'zscore');
% for i = 1:numCells
%     traceData = T(:,i);
%     traceData = traceData(traceData >= quantile(traceData,0.9));
%     trace_std(i) = std(traceData);
% end
quantiles = quantile(T, 0.9);
filter_mask = T >= quantiles;
T_filtered = T .* filter_mask;
T_filtered(~filter_mask) = NaN;
trace_std = std(T_filtered, 'omitnan');
end