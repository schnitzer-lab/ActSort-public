function [dataset_pretrained] = load_pretrained_dataset(path)
    if isempty(path)
        dataset_pretrained = [];
    else
        loadFile = load(path);
        dataset_pretrained = loadFile.dataset;
    end
end