function areas = get_areas(S, threshold)

    if nargin < 2 || isempty(threshold)
        threshold = 0.2;
    end
    [h, w, ~] = size(S);

    vec = reshape(S, h*w, []);
    areas = sum(vec > threshold)';
end