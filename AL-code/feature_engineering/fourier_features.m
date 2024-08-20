function quality_scores = fourier_features(T, lc, hc, parforFlag)

quality_scores = zeros(1, size(T, 1));
if parforFlag % JZ: add a parforFlag later
    parfor i = 1:size(T, 1)
        time_trace = T(i, :);

        N = length(time_trace);
        x_fft = fft(time_trace);

        power_spectrum = abs(x_fft).^2;
        power_spectrum = power_spectrum(1:round(N/2));
        power_spectrum = power_spectrum / sum(power_spectrum);

        % normalized frequency cutoffs
        nc = length(power_spectrum);
        lower_index = round(lc * nc);
        upper_index = round(hc * nc);

        % Handle edge cases
        if lower_index < 1
            lower_index = 1;
        end
        if upper_index > nc
            upper_index = nc;
        end

        % Neuron based on the normalized power
        freq_mask = lower_index:upper_index;
        score = sum(power_spectrum(freq_mask));

        quality_scores(i) = score;
    end
else
    for i = 1:size(T, 1)
        time_trace = T(i, :);

        N = length(time_trace);
        x_fft = fft(time_trace);

        power_spectrum = abs(x_fft).^2;
        power_spectrum = power_spectrum(1:round(N/2));
        power_spectrum = power_spectrum / sum(power_spectrum);

        % normalized frequency cutoffs
        nc = length(power_spectrum);
        lower_index = round(lc * nc);
        upper_index = round(hc * nc);

        % Handle edge cases
        if lower_index < 1
            lower_index = 1;
        end
        if upper_index > nc
            upper_index = nc;
        end

        % Neuron based on the normalized power
        freq_mask = lower_index:upper_index;
        score = sum(power_spectrum(freq_mask));

        quality_scores(i) = score;
    end
end

% 'quality_scores' contains a score between 0 and 1 for each neuron.
end
