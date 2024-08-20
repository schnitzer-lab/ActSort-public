function fieldValue = findField(structure, fieldName)
% This is a custom function that searches for the specified 
% field name within a struct.
% Due to constraints in MATLAB structures, there are no convenient
% built-in methods to directly retrieve a specified field name or 
% check for its existence. 
% INPUT
%   [structure] : The structure in which to search.
%   [fieldName] : The name of the field to look up.
%
% OUTPUT
%   [fieldValue] : The value of the field, if the specified field is found. 
%                If not found, it returns [].
%
fieldValue = []; % Default to empty

% Check if the current level of the structure has the field
if isfield(structure, fieldName)
    fieldValue = structure.(fieldName);
    return;
end

% Recursively search in each field
fieldNames = fieldnames(structure);
for i = 1:length(fieldNames)
    currentField = structure.(fieldNames{i});
    if isstruct(currentField)
        fieldValue = findField(currentField, fieldName);
        if ~isempty(fieldValue)
            break;
        end
    end
end
end