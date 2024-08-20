% Adjusts the contrast value based on slider movement
function [newVal] = adjust_constrast_value(otherSlider, event)
    start = event.PreviousValue;
    finish = event.Value;
    if ~is_in_range(otherSlider.Value, [start finish])
        newVal = event.Value;
        return
    elseif (finish-start) >= 0
        val = otherSlider.Value - abs(otherSlider.Value)*0.01;
        newVal = max(otherSlider.Limits(1),val);
    else
        val = otherSlider.Value + abs(otherSlider.Value)*0.01;
        newVal = min(otherSlider.Limits(2),val);
    end
end