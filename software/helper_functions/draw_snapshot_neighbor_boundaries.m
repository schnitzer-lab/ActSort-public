function draw_snapshot_neighbor_boundaries(ax, neighborBoundaries, COLOR)
    boundaryX = neighborBoundaries(1,:);
    boundaryY = neighborBoundaries(2,:);
    if COLOR == "noborder" || isempty(boundaryX)
        return;
    end
    patch(ax, boundaryX, boundaryY, 'k', 'LineWidth', 0.1, ...
                'FaceColor', 'none', 'EdgeColor', COLOR);
end