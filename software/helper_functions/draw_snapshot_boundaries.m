% Draws the boundary of the selected cell in a snapshot
function draw_snapshot_boundaries(ax, cell_boundary)
    BORDER_COLOR = [0.3, 0.5, 1];
    delete(findobj(ax, 'Type', 'patch'));
    patch(ax, cell_boundary(1,:), cell_boundary(2,:), 'k', 'LineWidth', 2, 'FaceColor', 'none', 'EdgeColor', BORDER_COLOR);
end