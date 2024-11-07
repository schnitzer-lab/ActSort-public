function [dataset_name, idx] = ask_for_dataset(dataset_names, uifigure)
% This function is used to ask for which dataset to use and return 
% its corresponding dataset name and movie size.
% INPUT
%   [dataset_names] : A string or char array containing the file path to the movie.
%   [uifigure] : GUI component to handle GUI interactions.
%
% OUTPUT
%   [dataset_name] : user selected dataset name.
%   [idx] : The index of the dataset
%

num_datasets = numel(dataset_names);

if num_datasets == 1
    % If there's only one dataset, select it directly
    idx = 1;
    dataset_name = char(dataset_names(idx));
    return;
elseif num_datasets == 2
    % If there are two datasets, and one of them is called "/F_per_pixel",
    % choose the other dataset. (F_per_pixel comes from EXTRACT and assured
    % to never contain the movie dataset.)
    if strcmp(dataset_names(1) , "/F_per_pixel")
        idx = 2;
    elseif strcmp(dataset_names(2) , "/F_per_pixel")
        idx = 1;
    end
    dataset_name = char(dataset_names(idx));
    return;
end

% If being called from the GUI, show a figure for dataset selection
if ~isempty(uifigure)
    % Define the button size
    button_height = 50; % Increase button height
    button_width = 200; % Increase button width
    button_spacing = 20; % Adjust spacing if needed
    dialog_height = (button_height + button_spacing) * num_datasets + button_spacing;
    
    % Create a dialog box
    d = dialog('Position',[300 300 button_width+100 dialog_height],...
               'Name','Select which dataset contains the movie',...
               'CloseRequestFcn', @closeDialog);

    % Adjust positions based on the number of datasets
    for i = 1:num_datasets
        btn_pos = dialog_height - (button_spacing + button_height) * i;
        uicontrol('Parent',d,...
               'Units','pixels',...
               'Position',[50, btn_pos, button_width, button_height],...
               'String', dataset_names{i},...
               'Callback', {@button_callback, i, d});
    end

    figure(uifigure);
    figure(d);
    % Wait for user to choose an option
    uiwait(d);
    
    if ishandle(d) % Check if dialog still exists
        idx = guidata(d);
        dataset_name = char(dataset_names(idx));
        delete(d);
    else
        dataset_name = nan;
        idx = nan;
    end
    figure(uifigure);
else
    % Display options to the user
    for i = 1:num_datasets
        disp(i + ") " + dataset_names(i))
    end
    
    % Keep asking for a valid index until one is given
    while true
        input_idx = input("Which dataset contains the movie ('exit' to stop): ", "s");
        try
            if (strcmpi(input_idx, "exit"))
                dataset_name = nan;
                idx = nan;
                return;
            end
            idx = str2double(input_idx);
            dataset_name = char(dataset_names(idx));
            return;
        catch
            warning("Please enter a valid index! (e.g. 1)");
        end
    end
end
end

function button_callback(~, ~, idx, dialog)
    guidata(dialog, idx); % Store the dataset name
    uiresume(dialog); % Resume execution of the UI
end

function closeDialog(src, ~)
    delete(src); % Delete the figure
end