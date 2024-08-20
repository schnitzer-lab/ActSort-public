function [dataset_names] = parse_dataset_names(m_path)
% This function is used to parse movie information without loading the movie.
% INPUT
%   [m_path] : A string or char array containing the file path to the movie.
%
% OUTPUT
%   [dataset_names] : A list of datasets in the h5 file.
%

    % Initialize empty string array for dataset names
    dataset_names = strings(0);

    % Obtain information about the h5 file
    dataInfo = h5info(m_path);

    % Extract dataset names
    for i = 1:length(dataInfo.Datasets)
        dataset_names(end+1) = sprintf('/%s', dataInfo.Datasets(i).Name);
    end
end