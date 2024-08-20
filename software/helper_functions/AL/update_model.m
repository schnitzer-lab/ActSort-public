function [dataset, dataset_pretrained, method] = update_model(dataset, dataset_pretrained, method)
    if isempty(dataset_pretrained)
        dataset_pretrained = [];
        [dataset, method] = train_classifier(dataset, method);
    else
        [dataset, dataset_pretrained, method] = fine_tune(dataset, dataset_pretrained, method);
    end
end