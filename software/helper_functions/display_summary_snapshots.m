% Displays a weighted snapshot
function display_summary_snapshots(ax, summary_snapshots, display_range)
    snapshot_handle = findobj(ax, 'Type', 'image');
    if isempty(snapshot_handle)
        imagesc(ax, summary_snapshots, display_range);
    else
        set(snapshot_handle, 'CData', summary_snapshots);
        set(ax, 'CLim', display_range);
    end
end