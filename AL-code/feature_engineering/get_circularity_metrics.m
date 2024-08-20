function [circularities, eccentricities] = ...
        get_circularity_metrics(S, fov_size, parallel, threshold)
    if nargin < 4 || isempty(threshold)
        threshold = 0.3;
    end
    h = fov_size(1);
    w = fov_size(2);
    S = reshape(S, h*w, []);
    k = size(S, 2);
    circularities = nan(1, k, 'single');
    eccentricities = nan(1, k, 'single');
    if parallel
        parfor i = 1:k
            image = reshape(full(S(:,i)),fov_size(1), fov_size(2));
            bw_image = image>threshold;
            stats = regionprops(bw_image, 'Area', 'Perimeter', 'MajorAxisLength', 'MinorAxisLength');
            areas = [stats.Area];
            % Choose the component with max area
            stats = stats(find(areas == max(areas), 1));
            if ~isempty(stats)
                area = stats.Area;
                perimeter = stats.Perimeter;
                eccentricities(i) = stats.MajorAxisLength / stats.MinorAxisLength;
                % Circularity is maximum 1 for circles
                circularities(i) = 4*pi* area / perimeter^2;
            end
        end
    else
        for i = 1:k
            image = reshape(full(S(:,i)),fov_size(1), fov_size(2));
            bw_image = image>threshold;
            stats = regionprops(bw_image, 'Area', 'Perimeter', 'MajorAxisLength', 'MinorAxisLength');
            areas = [stats.Area];
            % Choose the component with max area
            stats = stats(find(areas == max(areas), 1));
            if ~isempty(stats)
                area = stats.Area;
                perimeter = stats.Perimeter;
                eccentricities(i) = stats.MajorAxisLength / stats.MinorAxisLength;
                % Circularity is maximum 1 for circles
                circularities(i) = 4*pi* area / perimeter^2;
            end
        end
    end
    eccentricities(isnan(eccentricities)) = inf;
    circularities(isnan(circularities)) = inf;
end