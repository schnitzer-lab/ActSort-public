function summary_image = generate_summary_snapshots(snapshots)
    % Maximum Intensity Projection
    max_im = max(snapshots, [], 3); 
    % Median Intensity Projection
    median_im = median(snapshots, 3); 
    % Mean Intensity Projection
    mean_im = mean(snapshots,3);
    % Blending all 
    summary_image = 0.5 * max_im +  0.3 * median_im + 0.2 * mean_im;
end