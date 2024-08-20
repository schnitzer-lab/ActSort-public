function m_size = parse_dataset_info(m_path, idx)
    % Obtain information about the h5 file
    dataInfo = h5info(m_path);
    m_size = dataInfo.Datasets(idx).Dataspace.Size;
end