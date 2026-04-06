function python_cmd = getPythonCommand()
% This function helps users select a Python environment.
% It searches for all valid Python installations that have NumPy installed,
% then prompts the user to choose one for future computations.\
%
% OUTPUT
% [python_cmd]: user selected python path

    python_list = {};

    % try pyenv
    try
        pe = pyenv;
        if isfile(pe.Executable)
            python_list{end+1} = char(pe.Executable);
        end
    catch
    end

    % try system PATH
    if ispc
        cmds = {'where python', 'where python3'};
    else
        cmds = {'which python', 'which python3'};
    end

    for i = 1:length(cmds)
        [status, cmdout] = system(cmds{i});
        if status == 0
            paths = strtrim(splitlines(cmdout));
            paths = paths(~cellfun(@isempty, paths));
            python_list = [python_list; paths];
        end
    end

    python_list = unique(python_list); % Remove duplicates

    if isempty(python_list)
        error('No valid Python installation found.\nPlease install Python or configure MATLAB with pyenv.');
    end

    % check which python has numpy
    valid_idx = find(cellfun(@checkPythonEnv, python_list));

    if length(valid_idx) == 1
        python_cmd = python_list{valid_idx};
        fprintf('Using Python: %s\n', python_cmd);
        return;
    end

    % labeling python with valid env
    labels = cell(size(python_list));
    for i = 1:length(python_list)
        if checkPythonEnv(python_list{i})
            labels{i} = sprintf('%s  [Ready]', python_list{i});
        else
            labels{i} = sprintf('%s  [NO numpy]', python_list{i});
        end
    end

    % print python list
    fprintf('Available Python environments:\n');
    for i = 1:length(python_list)
        fprintf('%d: %s\n', i, labels{i});
    end

    % ask for python environment
    while true
        input_idx = input("Please select a python environment ('exit' to stop): ", "s");
        if strcmpi(input_idx, "exit")
            error('User cancelled selection.');
        end

        idx = str2double(input_idx);
        if ~isnan(idx) && idx >= 1 && idx <= length(python_list)
            python_cmd = python_list{idx};
            fprintf('Using Python: %s\n', python_cmd);
            return;
        else
            warning("Please enter a valid index! (e.g. 1)");
        end
    end

end

function is_ok = checkPythonEnv(python_cmd)
    test_cmd = sprintf('"%s" -c "import numpy"', python_cmd);
    [status, ~] = system(test_cmd);
    is_ok = (status == 0);
end