function quality_scores = fourier_spatial_features(S, ls, hs)

    % Initialize a vector to store the quality score of each neuron
    n_neurons = size(S, 3);
    quality_scores = zeros(1, n_neurons);
    
    for i = 1:n_neurons
   
        img = full(S(:,:,i));
        image_fft = fft2(img);
        
        power_spectrum = abs(image_fft).^2;
        power_spectrum_shifted = fftshift(power_spectrum);
        power_spectrum_normalized = power_spectrum_shifted / sum(power_spectrum_shifted(:));
        
        [h, w] = size(img);
        nc_h = floor(h/2);
        nc_w = floor(w/2); 
        lower_index_h = round(ls * nc_h);
        upper_index_h = round(hs * nc_h);
        lower_index_w = round(ls * nc_w);
        upper_index_w = round(hs * nc_w);
        
        lower_index_h = max(lower_index_h, 1);
        upper_index_h = min(upper_index_h, nc_h);
        lower_index_w = max(lower_index_w, 1);
        upper_index_w = min(upper_index_w, nc_w);
        
        % Extract the power spectrum within the cutoff frequencies
        freq_mask = power_spectrum_normalized((nc_h-lower_index_h+1):(nc_h+upper_index_h), ...
                                               (nc_w-lower_index_w+1):(nc_w+upper_index_w));
        
        score = sum(freq_mask(:));
        quality_scores(i) = score;
    end
    
    % 'quality_scores' contains a quality score between 0 and 1 for each neuron.
end