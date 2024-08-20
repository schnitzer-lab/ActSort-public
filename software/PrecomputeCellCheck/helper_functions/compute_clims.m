function [min_lim, max_lim, def_min_lim, def_max_lim] = compute_clims(array)
% This function computes contrast limits for snapshots.
% These calculations will be used in GUI sliders for visualization.
% INPUT
%   [array] : An nx1 array containing snapshot pixel values.
%
% OUTPUT
%   [min_lim] : The minimum value the contrast slider can take.
%   [max_lim] : The maximum value the contrast slider can take.
%   [def_min_lim] : The default initial minimum value of the contrast slider.
%   [def_max_lim] : The default initial maximum value of the contrast slider.
%

    min_lim = min(array);
    max_lim = max(array);

    sortedSnap = sort(array);
    len = length(sortedSnap);
    def_min_lim = sortedSnap(max(1, round(0.1 * len)));
    def_max_lim = sortedSnap(min(len, round(0.999 * len)));
end
