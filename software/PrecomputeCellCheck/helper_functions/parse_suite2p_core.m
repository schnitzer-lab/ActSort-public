function [spatial_weights, traces, max_im, info] = parse_suite2p_core( ...
    s2p, m_size, trace_source, cell_only, exclude_overlap)

    % Pull required objects
    F = single(s2p.F);

    if isfield(s2p, 'Fneu') && ~isempty(s2p.Fneu)
        Fneu = single(s2p.Fneu);
    else
        Fneu = [];
    end

    if isfield(s2p, 'spks') && ~isempty(s2p.spks)
        spks = single(s2p.spks);
    else
        spks = [];
    end

    stat = s2p.stat;

    if isfield(s2p, 'iscell') && ~isempty(s2p.iscell)
        iscell = s2p.iscell;
        has_iscell = true;
    else
        iscell = [];
        has_iscell = false;
    end

    if isfield(s2p, 'ops')
        ops = s2p.ops;
    else
        ops = struct;
    end

    % Consistency checks
    if numel(stat) ~= size(F,1)
        error('Mismatch: numel(stat) = %d but size(F,1) = %d.', numel(stat), size(F,1));
    end

    if has_iscell && size(iscell,1) ~= size(F,1)
        error('Mismatch: size(iscell,1) = %d but size(F,1) = %d.', size(iscell,1), size(F,1));
    end

    % Keep only ROIs marked as cells if requested
    if cell_only && has_iscell
        keep = logical(iscell(:,1));
    else
        keep = true(size(F,1), 1);
    end

    F = F(keep, :);
    if ~isempty(Fneu); Fneu = Fneu(keep, :); end
    if ~isempty(spks); spks = spks(keep, :); end
    stat = stat(keep);

    % Choose traces
    switch lower(trace_source)
        case 'f'
            traces = F;

        case 'fcorr'
            if isempty(Fneu)
                warning('Fneu not found; falling back to F.');
                traces = F;
            else
                traces = F - 0.7 * Fneu;
            end

        case 'spks'
            if isempty(spks)
                error('trace_source="spks" requested but spks.npy not found.');
            end
            traces = spks;

        otherwise
            error('Unknown trace_source: %s. Use "F", "Fcorr", or "spks".', trace_source);
    end

    % Determine H,W
    if isfield(ops, 'Ly') && isfield(ops, 'Lx')
        H = double(ops.Ly(1));
        W = double(ops.Lx(1));
    else
        H = double(m_size(1));
        W = double(m_size(2));
    end

    % -------- Build ndSparse directly from explicit coordinates --------
    N = numel(stat);

    coords_all = [];
    vals_all   = [];

    for i = 1:N
        roi = stat(i);

        ypix = double(roi.ypix(:)) + 1;
        xpix = double(roi.xpix(:)) + 1;

        if isfield(roi, 'lam') && ~isempty(roi.lam)
            lam = double(roi.lam(:));
        else
            lam = ones(numel(ypix),1);
        end

        if numel(ypix) ~= numel(xpix)
            error('ROI %d has mismatched ypix/xpix lengths.', i);
        end
        if numel(lam) ~= numel(ypix)
            error('ROI %d has mismatched lam and pixel lengths.', i);
        end

        if exclude_overlap && isfield(roi, 'overlap') && ~isempty(roi.overlap)
            overlap = logical(double(roi.overlap(:)));
            keep_pix = ~overlap;
            ypix = ypix(keep_pix);
            xpix = xpix(keep_pix);
            lam  = lam(keep_pix);
        end

        valid = ypix >= 1 & ypix <= H & xpix >= 1 & xpix <= W;
        ypix = ypix(valid);
        xpix = xpix(valid);
        lam  = lam(valid);

        if isempty(ypix)
            continue
        end

        coords_i = [ypix, xpix, repmat(i, numel(ypix), 1)];
        coords_all = [coords_all; coords_i];
        vals_all   = [vals_all; lam];
    end

    spatial_weights = ndSparse.build(coords_all, vals_all, [H W N]);

    % max_im preference: max_proj > meanImg > []
    max_im = [];
    if isfield(ops, 'max_proj') && ~isempty(ops.max_proj)
        max_im = single(ops.max_proj);
    elseif isfield(ops, 'meanImg') && ~isempty(ops.meanImg)
        max_im = single(ops.meanImg);
    end

    if ~isempty(max_im)
        if size(max_im,1) ~= H || size(max_im,2) ~= W
            warning('max_im size does not match H,W. Ignoring max_im.');
            max_im = [];
        end
    end

    info = struct;
    info.has_iscell = has_iscell;
    info.kept_idx = find(keep);
end