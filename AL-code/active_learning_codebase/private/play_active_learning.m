function [valid, ml_labels] = play_active_learning(metrics,choices,ratio,method)
    
    if nargin<4
        method = 'min_conf';
    end
    
    
    num_cells = size(metrics,2);
    stop_cell = round(ratio*num_cells);
    
    guess_good = find(choices==1);
    guess_good = guess_good(1:3);
    guess_bad = find(choices==-1);
    guess_bad = guess_bad(1:3);
    
    ml_labels = zeros(num_cells, 1, 'single');
    user_labels = zeros(num_cells, 1, 'single');
    ml_labels(guess_good) = 1;
    ml_labels(guess_bad) = -1;
    user_labels(guess_good) = 1;
    user_labels(guess_bad) = -1;
    features = metrics';
    infs = isinf(features);
    features(infs) = 0;
    features = zscore(features, 0, 1);
    features(infs) = 0;
    
    
    
    for i =1:stop_cell+1
        [idx_next_cell, preds] = ask_for_label(features, user_labels, ml_labels,'method',method);
        user_labels(idx_next_cell)=choices(idx_next_cell);
        ml_labels(idx_next_cell)=choices(idx_next_cell);
    end
    
    valid = preds;

end