function [label_file] = open_load_labels_menu(ui_figure)
    [fileName, path] = uigetfile('*.mat', 'Choose a .mat file');
    figure(ui_figure);
    if isequal(fileName, 0)
        return;
    end
    
    label_file = load(fullfile(path, fileName));
end