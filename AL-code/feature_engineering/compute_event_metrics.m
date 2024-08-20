function [power,fraction,num_events] = compute_event_metrics(T,scale,parforFlag)

n_cell = size(T,1);
noise = estimate_noise_std(T);
T = T./ max(T, [], 2);
power = zeros(1,n_cell);
fraction = zeros(1,n_cell);
num_events = zeros(1,n_cell);
if parforFlag % JZ: add parforFlag later
    parfor i = 1:n_cell
        temp = T(i,:);
        temp_noise = noise(i);
        power_full = sum(temp.^2);
        temp(temp<temp_noise*scale) = 0;
        power(i) = sum(temp.^2)/ power_full;
        fraction(i) = mean(temp >0);
        event_frames = extract_events_nonexponential(temp,temp_noise*scale);
        num_events(i) = size(event_frames,2);
    end
else
    for i = 1:n_cell
        temp = T(i,:);
        temp_noise = noise(i);
        power_full = sum(temp.^2);
        temp(temp<temp_noise*scale) = 0;
        power(i) = sum(temp.^2)/ power_full;
        fraction(i) = mean(temp >0);
        event_frames = extract_events_nonexponential(temp,temp_noise*scale);
        num_events(i) = size(event_frames,2);
    end
end

end