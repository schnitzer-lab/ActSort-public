function [fp,tp] = calculate_roc(gt,pred_probs)
    thr = linspace(1,0,100);
    tp = zeros(1,100);
    fp = zeros(1,100);
    for i=1:100
        predictions=(pred_probs>thr(i));
        chosen = gt(predictions);
        tp(i)= sum(chosen == 1) / sum(gt == 1);
        fp(i)= sum(chosen == -1) / sum(gt == -1);
    end
end