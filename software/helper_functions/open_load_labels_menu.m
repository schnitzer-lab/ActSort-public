function matchedLabels = open_load_labels_menu(precomputedFilePaths)
% OPEN_LOAD_LABELS_MENU
% Creates a GUI to match label files to datasets.
% 
% Inputs:
%   precomputedFilePaths - cell array of dataset file paths
%
% Output:
%   matchedLabels        - cell (#datasets x 1). matchedLabels{i} contains
%                          the loaded label data for dataset i (or empty if not matched).

    % -------------------- Prepare Data --------------------
    numDatasets   = numel(precomputedFilePaths);
    matchedLabels = cell(numDatasets,1);

    % Extract nice display names for each dataset
    datasetNames = cell(numDatasets,1);
    for i = 1:numDatasets
        [~, fName, ext] = fileparts(precomputedFilePaths{i});
        datasetNames{i} = [fName, ext];
    end

    % Initially, no labels are loaded
    loadedLabels         = {};  % cell array of actual label data
    loadedLabelFileNames = {};  % cell array of label filenames

    % Keep track of matched pairs, each with:
    %   .datasetIdx, .labelName, .labelData
    matchedPairs = struct('datasetIdx',{},'labelName',{},'labelData',{});

    % -------------------- Create Figure --------------------
    figWidth  = 700;
    figHeight = 500;
    f = figure('Name','Load Labels',...
               'MenuBar','none','ToolBar','none','NumberTitle','off',...
               'Resize','off',...
               'Position',[400,200,figWidth,figHeight]);

    % Title / instructions
    uicontrol('Parent',f,'Style','text',...
              'String','Match label files to datasets:',...
              'FontSize',14,'FontWeight','bold',...
              'HorizontalAlignment','left',...
              'Position',[20, figHeight-45, figWidth-40, 25]);

    % -------------------- Datasets (LEFT) --------------------
    uicontrol('Parent',f,'Style','text',...
              'String','Datasets:',...
              'FontSize',13,...
              'HorizontalAlignment','left',...
              'Position',[20, figHeight-75, 200, 25]);

    listDatasets = uicontrol('Parent',f,'Style','listbox',...
              'FontSize',13,...
              'Position',[20, figHeight-225, 300, 140],...
              'Callback',@onListSelectionChange,...
              'BackgroundColor',[1 1 1]);

    % -------------------- Labels (RIGHT) --------------------
    uicontrol('Parent',f,'Style','text',...
              'String','Labels:',...
              'FontSize',13,...
              'HorizontalAlignment','left',...
              'Position',[380, figHeight-75, 200, 25]);

    listLabels = uicontrol('Parent',f,'Style','listbox',...
              'FontSize',13,...
              'Position',[380, figHeight-225, 300, 140],...
              'Callback',@onListSelectionChange,...
              'BackgroundColor',[1 1 1]);

    % -------------------- Matched pairs (BOTTOM) --------------------
    uicontrol('Parent',f,'Style','text',...
              'String','Matched dataset–label pairs:',...
              'FontSize',13,...
              'HorizontalAlignment','left',...
              'Position',[20, figHeight-280, 300, 25]);

    listMatched = uicontrol('Parent',f,'Style','listbox',...
              'FontSize',13,...
              'Position',[20, figHeight-430, 660, 140],...
              'Callback',@onMatchedSelectionChange,...
              'BackgroundColor',[1 1 1]);

    % -------------------- Bottom row buttons --------------------
    btnLoadLabels = uicontrol('Parent',f,'Style','pushbutton',...
              'String','Load Labels',...
              'FontSize',13,...
              'Position',[20, 20, 100, 40],...
              'Callback',@onLoadLabels);

    btnMatch = uicontrol('Parent',f,'Style','pushbutton',...
              'String','Match',...
              'FontSize',13,...
              'Position',[140, 20, 100, 40],...
              'Enable','off',...
              'Callback',@onMatch);

    btnRemove = uicontrol('Parent',f,'Style','pushbutton',...
              'String','Remove',...
              'FontSize',13,...
              'Position',[260, 20, 100, 40],...
              'Enable','off',...
              'Callback',@onRemove);

    btnDone = uicontrol('Parent',f,'Style','pushbutton',...
              'String','Done',...
              'FontSize',13,...
              'Position',[figWidth-120, 20, 100, 40],...
              'Callback',@onDone);

    % -------------------- Initialize Lists --------------------
    refreshDatasetsList();
    refreshLabelsList();
    refreshMatchedList();

    % Wait until "Done" is pressed
    uiwait(f);

    % Return matched labels in the same order as datasets
    % (We already filled matchedLabels in onMatch.)
    % The figure is closed by now.
    
    % -------------------- Nested Functions --------------------
    function onLoadLabels(~,~)
        % Let user pick multiple .mat files
        [files, path] = uigetfile('*.mat','Select label file(s)','MultiSelect','on');
        if isequal(files,0)
            return; % user canceled
        end
        if ischar(files)
            files = {files};
        end

        for k = 1:numel(files)
            fName = files{k};
            fullPath = fullfile(path, fName);
            data = load(fullPath);

            loadedLabels{end+1}         = data;
            loadedLabelFileNames{end+1} = fName;
        end
        refreshLabelsList();
    end

    function onListSelectionChange(~,~)
        % Enable "Match" if we have a valid dataset & label selected
        dsVal = getValidIndex(listDatasets, numDatasets);
        lbVal = getValidIndex(listLabels, numel(loadedLabelFileNames));
        if (dsVal>0) && (lbVal>0)
            set(btnMatch,'Enable','on');
        else
            set(btnMatch,'Enable','off');
        end
    end

    function onMatchedSelectionChange(~,~)
        % Enable "Remove" if a valid matched pair is selected
        mpVal = getValidIndex(listMatched, numel(matchedPairs));
        if mpVal>0
            set(btnRemove,'Enable','on');
        else
            set(btnRemove,'Enable','off');
        end
    end

    function onMatch(~,~)
        dsVal = getValidIndex(listDatasets, numDatasets);
        lbVal = getValidIndex(listLabels, numel(loadedLabelFileNames));
        if dsVal<1 || lbVal<1
            return; % invalid selection
        end

        % Create a new matched pair
        matchedPairs(end+1).datasetIdx = dsVal;
        matchedPairs(end).labelName   = loadedLabelFileNames{lbVal};
        matchedPairs(end).labelData   = loadedLabels{lbVal};

        % Store in matchedLabels array
        matchedLabels{dsVal} = loadedLabels{lbVal};

        % Remove the label from the "Labels" list so it can't be reused
        loadedLabels(lbVal)         = [];
        loadedLabelFileNames(lbVal) = [];

        refreshLabelsList();
        refreshMatchedList();

        % Disable "Match" again
        set(btnMatch,'Enable','off');
    end

    function onRemove(~,~)
        mpVal = getValidIndex(listMatched, numel(matchedPairs));
        if mpVal<1
            return;
        end

        % Identify which dataset was matched
        dsIdx = matchedPairs(mpVal).datasetIdx;

        % Remove from matchedLabels
        matchedLabels{dsIdx} = [];

        % Return this label to the loadedLabels list
        oldLabelName = matchedPairs(mpVal).labelName;
        oldLabelData = matchedPairs(mpVal).labelData;
        loadedLabelFileNames{end+1} = oldLabelName;
        loadedLabels{end+1}         = oldLabelData;

        % Remove this matched pair
        matchedPairs(mpVal) = [];

        refreshLabelsList();
        refreshMatchedList();

        % Disable "Remove"
        set(btnRemove,'Enable','off');
    end

    function onDone(~,~)
        uiresume(f);
        if isvalid(f)
            close(f);
        end
    end

    % -------------------- Refresh / Utility --------------------
    function refreshDatasetsList()
        % If there are no datasets, use a placeholder
        if numDatasets == 0
            set(listDatasets, 'String',{'(No datasets)'}, ...
                              'Value',1, ...
                              'Enable','inactive'); 
        else
            set(listDatasets, 'String',datasetNames, ...
                              'Enable','on');
            % Validate current Value
            oldVal = get(listDatasets,'Value');
            if isempty(oldVal) || oldVal<1 || oldVal>numDatasets
                set(listDatasets,'Value',1);
            else
                set(listDatasets,'Value',oldVal);
            end
        end
    end

    function refreshLabelsList()
        nLabels = numel(loadedLabelFileNames);
        if nLabels == 0
            % Single‐selection listbox can't have Value=[]
            % So use a placeholder string
            set(listLabels, 'String',{'(No labels loaded)'}, ...
                            'Value',1, ...
                            'Enable','inactive');
        else
            set(listLabels, 'String',loadedLabelFileNames, ...
                            'Enable','on');
            oldVal = get(listLabels,'Value');
            if isempty(oldVal) || oldVal<1 || oldVal>nLabels
                set(listLabels,'Value',1);
            else
                set(listLabels,'Value',oldVal);
            end
        end
    end

    function refreshMatchedList()
        nMatched = numel(matchedPairs);
        if nMatched == 0
            set(listMatched, 'String',{'(No matched pairs)'}, ...
                             'Value',1, ...
                             'Enable','inactive');
        else
            set(listMatched, 'Enable','on');
            % Build display strings for each pair
            pairStrings = cell(nMatched,1);
            for k = 1:nMatched
                dsName   = datasetNames{matchedPairs(k).datasetIdx};
                labelStr = matchedPairs(k).labelName;
                pairStrings{k} = sprintf('%s  <-->  %s', dsName, labelStr);
            end
            set(listMatched, 'String',pairStrings);

            oldVal = get(listMatched,'Value');
            if isempty(oldVal) || oldVal<1 || oldVal>nMatched
                set(listMatched,'Value',1);
            else
                set(listMatched,'Value',oldVal);
            end
        end
    end

    % Safely get the listbox's current Value, returning 0 if invalid
    function idx = getValidIndex(listHandle, maxItems)
        if strcmpi(get(listHandle,'Enable'),'inactive')
            idx = 0;
            return;
        end
        idx = get(listHandle,'Value');
        if isempty(idx) || idx<1 || idx>maxItems
            idx = 0;
        end
    end

end
