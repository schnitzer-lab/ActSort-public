function result = open_load_datasets_menu()
% OPEN_LOAD_DATASETS_MENU  Shows a GUI for selecting precomputed files 
% and a pretrained model. Returns them upon pressing "Continue."
%
% Usage:
%   result = open_load_datasets_menu();
%
% Returns a struct with fields:
%   - result.precomputedOutputs
%   - result.pretrainedModel
%   - result.precomputedFilePaths
%   - result.balancePretrained

    %% --- Internal State ---
    precomputedFilePaths = {};  % Cell array of .mat file paths
    pretrainedPath       = '';  % Single .mat path (optional)

    %% --- Create the figure (modal) ---
    fig = uifigure( ...
        'Name', 'Sorting Session Configuration', ...
        'Position', [100 100 400 360], ...  % Reduced height
        'WindowStyle', 'modal');

    %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %       UI Controls for Precomputed Files
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    uilabel(fig, ...
        'Text', 'Select precomputed files:', ...
        'Position', [20 320 360 20]);  % Moved higher label down

    addPrecomputedButton = uibutton(fig, ...
        'Position', [30 290 160 30], ...
        'Text', 'Add Precomputed File (.mat)', ...
        'ButtonPushedFcn', @(btn, evt) addPrecomputedFile());

    removePrecomputedButton = uibutton(fig, ...
        'Position', [210 290 160 30], ...
        'Text', 'Remove Selected File(s)', ...
        'ButtonPushedFcn', @(btn, evt) removePrecomputedFile());

    % Use a list box to display precomputed files.
    listPrecomputed = uilistbox(fig, ...
        'Items', {'(No precomputed files)'}, ...
        'Position', [30 240 340 40], ...
        'MultiSelect', 'on');

    %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %       UI for Pretrained Model (Optional)
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    uilabel(fig, ...
        'Text', 'Select a pretrained classifier (optional):', ...
        'Position', [20 200 360 20]);  % Closer to the list

    choosePretrainedDatasetButton = uibutton(fig, ...
        'Position', [30 170 340 30], ...
        'Text', 'Choose Pretrained Classifier', ...
        'ButtonPushedFcn', @(btn, evt) choosePretrainedDataset());

    pretrainedDatasetPathEditField = uieditfield(fig, 'text', ...
        'Value', '', ...
        'Editable', 'off', ...
        'Position', [30 140 340 22], ...
        'HorizontalAlignment', 'center');

    balancePretrainedCheckBox = uicheckbox(fig, ...
        'Text', 'Balance Pretrained', ...
        'Position', [30 110 340 20], ...
        'Enable', 'off'); % Initially disabled

    %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    %              Continue Button
    % ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    continueButton = uibutton(fig, ...
        'Position', [140 60 120 30], ...
        'Text', 'Continue', ...
        'ButtonPushedFcn', @(btn, evt) continueCallback());

    %% --- Define components to disable during file dialogs ---
    COMPONENTS_TO_HANDLE = [addPrecomputedButton, removePrecomputedButton, ...
            listPrecomputed, choosePretrainedDatasetButton, ...
            pretrainedDatasetPathEditField, balancePretrainedCheckBox, ...
            continueButton];

    uiwait(fig);

    %% --- Nested Functions --- 

    function addPrecomputedFile()
        old_states = disableControls(COMPONENTS_TO_HANDLE);
        [files, path] = uigetfile('*.mat', 'Select precomputed files', 'Multiselect', 'on');
        restoreControls(COMPONENTS_TO_HANDLE, old_states);
        if isequal(files, 0)
            return;
        end
    
        if ischar(files)
            files = {files};  % standardize to cell array when selecting only one file
        end
    
        for i = 1:numel(files)
            fullPath = fullfile(path, files{i});
            if ~ismember(fullPath, precomputedFilePaths)
                precomputedFilePaths{end+1} = fullPath;
            end
        end
    
        refreshPrecomputedPathsDisplay();
    end

    function removePrecomputedFile()
        if isempty(precomputedFilePaths)
            return;
        end
        % Get selected items from the list box.
        selItems = listPrecomputed.Value;
        % If the placeholder is showing, nothing is selected.
        if iscell(selItems)
            if any(strcmp(selItems,'(No precomputed files)'))
                return;
            end
        elseif strcmp(selItems,'(No precomputed files)')
            return;
        end

        % Map selected items back to indices in precomputedFilePaths
        allItems = listPrecomputed.Items;
        indices = [];
        for i = 1:length(selItems)
            idx = find(strcmp(allItems, selItems{i}));
            indices = [indices; idx]; %#ok<AGROW>
        end

        precomputedFilePaths(indices) = [];
        refreshPrecomputedPathsDisplay();
    end

    function refreshPrecomputedPathsDisplay()
        if isempty(precomputedFilePaths)
            listPrecomputed.Items = {'(No precomputed files)'};
            listPrecomputed.Value = '(No precomputed files)';
        else
            shortNames = cellfun(@fileShortName, precomputedFilePaths, 'UniformOutput', false);
            listPrecomputed.Items = shortNames;
            listPrecomputed.Value = shortNames{1};
        end
    end

    function fileName = fileShortName(fullpath)
        [~, nm, ext] = fileparts(fullpath);
        fileName = [nm, ext];
    end

    function choosePretrainedDataset()
        oldStates = disableControls(COMPONENTS_TO_HANDLE);
        [file, path] = uigetfile('*.mat', 'Select a pretrained classifier');
        restoreControls(COMPONENTS_TO_HANDLE, oldStates);
        figure(fig); % Bring our figure back to front

        if isequal(file, 0)
            pretrainedPath = '';
            pretrainedDatasetPathEditField.Value = pretrainedPath;
            balancePretrainedCheckBox.Enable = 'off';
        else
            pretrainedPath = fullfile(path, file);
            pretrainedDatasetPathEditField.Value = pretrainedPath;
            balancePretrainedCheckBox.Enable = 'on';
        end
    end

    function oldStates = disableControls(controls)
        oldStates = cell(1, numel(controls));
        for i = 1:numel(controls)
            oldStates{i} = controls(i).Enable;
            controls(i).Enable = 'off';
        end
        drawnow;
    end

    function restoreControls(controls, oldStates)
        for i = 1:numel(controls)
            controls(i).Enable = oldStates{i};
        end
        drawnow;
    end

    function continueCallback()
        oldStates = disableControls(COMPONENTS_TO_HANDLE);

        % 1) Make sure there's at least one precomputed file
        if isempty(precomputedFilePaths)
            uialert(fig, 'Please select at least one precomputed file before continuing.', 'Error');
            restoreControls(COMPONENTS_TO_HANDLE, oldStates);
            return;
        end

        % 2) Attempt to load all precomputed files
        tempOutputs = cell(1, numel(precomputedFilePaths));
        try
            for iFile = 1:numel(precomputedFilePaths)
                loadStruct = load(precomputedFilePaths{iFile});
                tempOutputs{iFile} = loadStruct.precomputedOutput;
            end
        catch
            uialert(fig, 'Invalid or corrupted precomputed file', ...
                'Error', 'Icon', 'error');
            restoreControls(COMPONENTS_TO_HANDLE, oldStates);
            return;
        end

        % 3) Attempt to load pretrained model (if chosen)
        tempPretrained = [];
        if ~isempty(pretrainedPath)
            try
                tempPretrained = load_pretrained_dataset(pretrainedPath);
            catch
                uialert(fig, 'Invalid pretrained classifier file', ...
                    'Error', 'Icon', 'error');
                restoreControls(COMPONENTS_TO_HANDLE, oldStates);
                return;
            end
        end

        % All data loaded OK.
        result.precomputedOutputs    = tempOutputs;
        result.pretrainedModel       = tempPretrained;
        result.precomputedFilePaths  = precomputedFilePaths;
        result.balancePretrained     = balancePretrainedCheckBox.Value;

        uiresume(fig);
        delete(fig);
    end

end
