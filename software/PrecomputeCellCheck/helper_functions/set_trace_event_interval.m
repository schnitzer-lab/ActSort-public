function new_trace = set_trace_event_interval(trace,n_frame)
% This function is used to create a new trace activity dataset for
% identifying spike events.
% INPUT
%   [trace] : The original trace activity array.
%   [n_frame] : The number of frames to exclude from the start and end of 
%               the original dataset.
%
% OUTPUT
%   [new_trace] : The modified trace activity dataset for event detection.
% 
eventLowLim = 1+fix(n_frame/2+2);
eventUpLim = size(trace,1)-fix(n_frame/2+2)-1;
new_trace = zeros(length(trace),1);
new_trace(eventLowLim:eventUpLim) = trace(eventLowLim:eventUpLim);
end