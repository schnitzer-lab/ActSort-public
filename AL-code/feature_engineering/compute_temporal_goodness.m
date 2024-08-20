function [metric] = compute_temporal_goodness(M, E, S,event_ratio)

    % Computes correlation btw M & S when E is nonzero
    % M & S are 2d (space flattened)
    E = E ./ max(E,[],2);
    E(isnan(E)) = 0;
    masks = S>0;
    idx_event = find(E>event_ratio);
    if isempty(idx_event)
        metric = nan;
    else
        idx_pixel_nonzero = find(masks>0);
        M_small = M(idx_pixel_nonzero, idx_event);
        s = S(idx_pixel_nonzero);
        s = zscore(s)/sqrt(length(s));
        M_small = bsxfun(@rdivide, M_small, sqrt(sum(M_small.^2,1)));
        c = s'*M_small;
        metric = sum(E(idx_event) .* c) / sum(E(idx_event));
    end
    
end