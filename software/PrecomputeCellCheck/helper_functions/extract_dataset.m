function [dataset_name, m_size] = extract_dataset(m_path, uifigure)
    % Parse the movie info from the movie path
    [dataset_names] = parse_dataset_names(m_path);
    % Get the dataset to use from user input
    [dataset_name, dataset_idx] = ask_for_dataset(dataset_names, uifigure);
    % Get the dataset info
    if isnan(dataset_name)
        m_size = nan;
    else
        m_size = parse_dataset_info(m_path, dataset_idx);
    end
end