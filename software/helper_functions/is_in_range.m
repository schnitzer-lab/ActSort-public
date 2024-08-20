% Checks if a value is within a specified range
function [boolean] = is_in_range(val, interval)
    interval = sort(interval);
    boolean = (val >= interval(1)) && (val <= interval(2));
end