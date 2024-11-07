function [label_file, file_path] = open_load_labels_menu(ui_figure)
    [fileName, path] = uigetfile('*.mat', 'Choose a .mat file');
    figure(ui_figure);
    if isequal(fileName, 0)
        return;
    end
    
    file_path = fullfile(path, fileName);
    label_file = load(fullfile(file_path));
end