function [spatial_weights, traces, max_im] = parse_extract_output(extract_output)
% This function is used to parse the extract output file to retrieve 
% necessary components.
% INPUT
%   [extract_output] : A MATLAB struct that contains the extract output.
%
% OUTPUT
%   [spatial_weights] : An array containing spatial weights.
%   [traces] : An array containing trace activity.
%

% Candidate values for spatial weights and traces. Feel free to add more.
sw_field = ["spatial_weights","filters","spatialWeights"];
trace_field = ["temporal_weights","traces"];
max_im_field = ["max_image", "summary_image", "max_im"];

% Find spatial weights
for s = sw_field
    spatial_weights = findField(extract_output,s);

    if ~isempty(spatial_weights)
        break;
    end
end

% Convert to sparse if spatial weights is not sparse already
if ~issparse(spatial_weights)
    spatial_weights = ndSparse(spatial_weights);
end

% Find traces
for t = trace_field
    traces = findField(extract_output,t);
    if ~isempty(traces)
        break;
    end
end

% Find maximum image (optional)
for m = max_im_field
    max_im = findField(extract_output,m);
    if ~isempty(max_im)
        break;
    end
end

if isempty(spatial_weights) || isempty(traces)
    error();
end

end