function PrecomputeCellCheckGUI
    % Creates a UI similar to the PrecomputeActSort app,
    % but as a single .m function. Manages a queue of jobs
    % for calling PrecomputeCellCheck.
    %
    % Usage:
    %   PrecomputeCellCheckGUI

    % State storage
    S.jobQueue = struct('h5', {}, 'mat', {}, 'output', {}, ...
                        'parallel', {}, 'fast', {}, 'dt', {}, 'status', {},'algorithm',{});
    S.isRunning = false;
    S.selectedJobIndex = [];
    S.currentChannel = 1;

    % Create main figure
    S.fig = uifigure('Name','PrecomputeCellCheckGUI','Position',[100 100 420 520]);

    % Create tab group
    S.TabGroup = uitabgroup(S.fig,'Position',[1 1 420 520]);

    %------------------------------------------------
    %% Add Files Tab
    %------------------------------------------------
    S.AddFilesTab = uitab(S.TabGroup,'Title','Add Files');
    S.GridLayout = uigridlayout(S.AddFilesTab,...
        'ColumnWidth',{'0.25x','1x','1x','1x','1x','1x','0.25x'}, ...
        'RowHeight',{'1.5x','1.25x','1x','1x','1.25x','1.25x','1x','1.25x','1x',...
                     '0.75x','0.75x','0.75x','1x','1.5x','0.25x'});

    % Instructions label
    S.InstructionsLabel = uilabel(S.GridLayout,'Text',...
        'Add pairs of movie and data files to the queue for precomputation:', ...
        'FontSize',13,'WordWrap','on');
    S.InstructionsLabel.Layout.Row = 1;
    S.InstructionsLabel.Layout.Column = [2 6];

    % Choose .h5
    S.Chooseh5fileButton = uibutton(S.GridLayout,'push','Text','Choose .h5 file',...
        'FontSize',13,'ButtonPushedFcn',@onChooseH5);
    S.Chooseh5fileButton.Layout.Row = 2;
    S.Chooseh5fileButton.Layout.Column = [2 6];

    S.H5FileEditField = uieditfield(S.GridLayout,'text','FontSize',13,...
        'ValueChangedFcn',@onH5ValueChanged);
    S.H5FileEditField.Layout.Row = 3;
    S.H5FileEditField.Layout.Column = [2 6];
    
    % Choose data form [new]
    S.ChannelHint = uilabel(S.GridLayout,'Text','Channel Selection','FontSize',13);  
    S.ChannelHint.Layout.Row = 4;
    S.ChannelHint.Layout.Column = [2 6];

    S.ChannelGroup = uibuttongroup(S.GridLayout,'BorderType','none');  
    S.ChannelGroup.Layout.Row = 5;
    S.ChannelGroup.Layout.Column = [2 6];

    S.Radio1 = uiradiobutton(S.ChannelGroup,'Text','EXTRACT','FontSize',12,'Value',true,'Position',[10 10 100 22]);
    S.Radio2 = uiradiobutton(S.ChannelGroup,'Text','CAIMAN','FontSize',12,'Value',false,'Position',[120 10 100 22]);
    S.Radio3 = uiradiobutton(S.ChannelGroup,'Text','Suite2p','FontSize',12,'Value',false,'Position',[230 10 100 22]);
   
    S.ChannelGroup.SelectionChangedFcn = @onChannelSelectionChanged;
    
    S.ChooseDatafileButton = [];
    S.DataFileEditField = [];

    S.ChooseDatafileButton = uibutton(S.GridLayout,'push','Text','Choose .mat file',...
        'FontSize',13,'ButtonPushedFcn',@onChooseMat);
    S.ChooseDatafileButton.Layout.Row = 6;
    S.ChooseDatafileButton.Layout.Column = [2 6];
    
    S.DataFileEditField = uieditfield(S.GridLayout,'text','FontSize',13,...
        'ValueChangedFcn',@onDataValueChanged);
    S.DataFileEditField.Layout.Row = 7;
    S.DataFileEditField.Layout.Column = [2 6];
    
   
    % Choose output
    S.ChooseOutputButton = uibutton(S.GridLayout,'push','Text','Choose output destination',...
        'FontSize',13,'Enable','off','ButtonPushedFcn',@onChooseOutput);
    S.ChooseOutputButton.Layout.Row = 8;
    S.ChooseOutputButton.Layout.Column = [2 6];

    S.OutputPathEditField = uieditfield(S.GridLayout,'text','FontSize',13,...
        'Enable','off');
    S.OutputPathEditField.Layout.Row = 9;
    S.OutputPathEditField.Layout.Column = [2 6];

    % Checkboxes
    S.UseParallelComputationCheckBox = uicheckbox(S.GridLayout,'Text','Use Parallel Computation',...
        'FontSize',13,'Value',true,'Enable','off');
    S.UseParallelComputationCheckBox.Layout.Row = 10;
    S.UseParallelComputationCheckBox.Layout.Column = [2 6];

    S.FastFeatureCalculationCheckBox = uicheckbox(S.GridLayout,'Text','Fast Feature Calculation',...
        'FontSize',13,'Value',false,'Enable','off');
    S.FastFeatureCalculationCheckBox.Layout.Row = 11;
    S.FastFeatureCalculationCheckBox.Layout.Column = [2 6];

    % Downsampling
    S.DownsamplingAmountofTimeLabel = uilabel(S.GridLayout,'Text','Downsampling Amount of Time:',...
        'FontSize',13,'Enable','off','WordWrap','on');
    S.DownsamplingAmountofTimeLabel.Layout.Row = 12;
    S.DownsamplingAmountofTimeLabel.Layout.Column = [2 6];

    S.DownsamplingAmountEditField = uieditfield(S.GridLayout,'numeric','FontSize',13,...
        'Value',1,'Enable','off','Limits',[1 Inf]);
    S.DownsamplingAmountEditField.Layout.Row = 13;
    S.DownsamplingAmountEditField.Layout.Column = [2 6];

    % Add to queue
    S.AddToQueueButton = uibutton(S.GridLayout,'push','Text','+ Add to the queue',...
        'FontSize',13,'Enable','off','ButtonPushedFcn',@onAddToQueue);
    S.AddToQueueButton.Layout.Row = 14;
    S.AddToQueueButton.Layout.Column = [2 6];

    % Temporary paths for current entry
    S.dataFilePath = "";
    S.h5FilePath = "";

    %------------------------------------------------
    %% Jobs Tab
    %------------------------------------------------
    S.JobsTab = uitab(S.TabGroup,'Title','Jobs');
    S.GridLayout2 = uigridlayout(S.JobsTab,'RowHeight',{22,'7x','1x','1x','1x'},...
        'ColumnSpacing',6.72,'Padding',[6.72 10 6.72 10]);

    S.JobsonthequeueLabel = uilabel(S.GridLayout2,'Text','Jobs on the queue:',...
        'FontSize',13);
    S.JobsonthequeueLabel.Layout.Row = 1;
    S.JobsonthequeueLabel.Layout.Column = 1;

    S.JobsListBox = uilistbox(S.GridLayout2,'FontSize',13,...
        'ValueChangedFcn',@onJobSelected);
    S.JobsListBox.Layout.Row = 2;
    S.JobsListBox.Layout.Column = [1 2];
    S.JobsListBox.Items = {};

    S.MoveUpButton = uibutton(S.GridLayout2,'push','Text','Move Up',...
        'FontSize',13,'Enable','off','ButtonPushedFcn',@onMoveUp);
    S.MoveUpButton.Layout.Row = 3;
    S.MoveUpButton.Layout.Column = 1;

    S.MoveDownButton = uibutton(S.GridLayout2,'push','Text','Move Down',...
        'FontSize',13,'Enable','off','ButtonPushedFcn',@onMoveDown);
    S.MoveDownButton.Layout.Row = 3;
    S.MoveDownButton.Layout.Column = 2;

    S.RemoveButton = uibutton(S.GridLayout2,'push','Text','Remove',...
        'FontSize',13,'Enable','off','ButtonPushedFcn',@onRemove);
    S.RemoveButton.Layout.Row = 4;
    S.RemoveButton.Layout.Column = [1 2];

    S.RunAllButton = uibutton(S.GridLayout2,'push','Text','Run All',...
        'FontSize',13,'Enable','off','ButtonPushedFcn',@onRunAll);
    S.RunAllButton.Layout.Row = 5;
    S.RunAllButton.Layout.Column = [1 2];

    % Initialize display
    resetAddFilesTab();
    updateJobListDisplay();

    %% Nested callback functions
    % -------------------------

    function onChooseH5(~,~)
        [file, path] = uigetfile('*.h5','Select .h5 file');
        if isequal(file,0)
            return;
        end
        S.h5FilePath = fullfile(path,file);
        S.H5FileEditField.Value = S.h5FilePath;
        tryEnableInputs();
    end

    function onChooseMat(~,~)   % [new]
        [file, path] = uigetfile('*.mat','Select .mat file');
        if isequal(file,0)
            return;
        end
        S.dataFilePath = fullfile(path,file);
        S.DataFileEditField.Value = S.dataFilePath;
        tryEnableInputs();
    end

    function onChooseHdf5(~,~)  % [new]
        [file, path] = uigetfile('*.hdf5','Select .hdf5 file');
        if isequal(file,0)
            return;
        end
        S.dataFilePath = fullfile(path,file);
        S.DataFileEditField.Value = S.dataFilePath;
        tryEnableInputs();
    end
    
    function onChooseNpy(~,~)   % [new]
        [file, path] = uigetfile('*.npy','Select .npy file');
        if isequal(file,0)
            return;
        end
        S.dataFilePath = fullfile(path,file);
        S.DataFileEditField.Value = S.dataFilePath;
        tryEnableInputs();
    end
    
    function updateDataFileButton()    % [new]
        switch S.currentChannel
        case 1   % Extract
            S.ChooseDatafileButton.Text = 'Choose .mat file';
            S.ChooseDatafileButton.ButtonPushedFcn = @onChooseMat;
        case 2   % Caiman
            S.ChooseDatafileButton.Text = 'Choose .hdf5 file';
            S.ChooseDatafileButton.ButtonPushedFcn = @onChooseHdf5;
            case 3   % Suite2p
            S.ChooseDatafileButton.Text = 'Choose .npy file';
            S.ChooseDatafileButton.ButtonPushedFcn = @onChooseNpy;
        end
    end

    function onChooseOutput(~,~)
        [file, path] = uiputfile('*.mat','Select output file');
        if isequal(file,0)
            return;
        end
        S.OutputPathEditField.Value = fullfile(path,file);
    end

    function onH5ValueChanged(~,~)
        S.h5FilePath = S.H5FileEditField.Value;
        tryEnableInputs();
    end

    function onChannelSelectionChanged(~,event)   % [new] 
        selectedButton = event.NewValue;
        selectedText = selectedButton.Text;

        switch selectedText
            case 'EXTRACT'
                S.currentChannel = 1;
            case 'CAIMAN'
                S.currentChannel = 2;
            case 'Suite2p'
                S.currentChannel = 3;
        end

        updateDataFileButton();

        S.dataFilePath = "";
        S.DataFileEditField.Value = "";

        tryEnableInputs();

    end

    function onDataValueChanged(~,~)
        S.DataFilePath = S.DataFileEditField.Value;
        tryEnableInputs();
    end

    function onAddToQueue(~,~)
        job.h5       = S.h5FilePath;
        job.mat      = S.dataFilePath;
        job.output   = S.OutputPathEditField.Value;
        job.parallel = S.UseParallelComputationCheckBox.Value;
        job.fast     = S.FastFeatureCalculationCheckBox.Value;
        job.dt       = S.DownsamplingAmountEditField.Value;
        job.status   = "Ready";
        job.algorithm = S.currentChannel;     % [new] save data resource

        S.jobQueue(end+1) = job;
        updateJobListDisplay();
        resetAddFilesTab();
    end

    function onJobSelected(~,~)
        val = S.JobsListBox.Value;
        if isempty(val) || val==0
            % Means placeholder or no selection
            S.selectedJobIndex = [];
        else
            S.selectedJobIndex = val;
        end
        updateButtonEnables();
    end

    function onMoveUp(~,~)
        idx = S.selectedJobIndex;
        if idx>1
            [S.jobQueue(idx-1), S.jobQueue(idx)] = deal(S.jobQueue(idx), S.jobQueue(idx-1));
            S.selectedJobIndex = idx-1;
            updateJobListDisplay();
            S.JobsListBox.Value = idx-1;
        end
    end

    function onMoveDown(~,~)
        idx = S.selectedJobIndex;
        if idx< numel(S.jobQueue)
            [S.jobQueue(idx), S.jobQueue(idx+1)] = deal(S.jobQueue(idx+1), S.jobQueue(idx));
            S.selectedJobIndex = idx+1;
            updateJobListDisplay();
            S.JobsListBox.Value = idx+1;
        end
    end

    function onRemove(~,~)
        if isempty(S.selectedJobIndex) || S.selectedJobIndex==0
            return; % Nothing to remove
        end
        S.jobQueue(S.selectedJobIndex) = [];
        S.selectedJobIndex = [];
        updateJobListDisplay();
    end

    function onRunAll(~,~)
        S.isRunning = true;
        updateButtonEnables();
        
        numJobs = numel(S.jobQueue);
        for i = 1:numJobs
            S.jobQueue(1).status = "Running...";
            updateJobListDisplay();
            drawnow;

            job = S.jobQueue(1);
            try
                % Call your actual function
                PrecomputeCellCheck(job.mat, job.h5, ...
                    'output_path', job.output, ...
                    'parallel', job.parallel, ...
                    'fast_features', job.fast, ...
                    'dt', job.dt, ...
                    'algorithm', job.algorithm);
                
                S.jobQueue(1).status = "Done!";
            catch e
                S.jobQueue(1).status = "Error";
                % Print the error in the command window for debugging
                disp(getReport(e));
            end
            
            % Move completed job to the end of the queue
            doneJob = S.jobQueue(1);
            S.jobQueue(1) = [];
            S.jobQueue(end+1) = doneJob;
        end
        
        S.isRunning = false;
        updateJobListDisplay();
    end

    %% Utility functions
    % ------------------

    function tryEnableInputs()
        if strlength(S.dataFilePath)>0 && strlength(S.h5FilePath)>0
            outPath = fullfile(fileparts(S.dataFilePath),"precomputed_output.mat");
            S.OutputPathEditField.Value = outPath;

            S.ChooseOutputButton.Enable = 'on';
            S.OutputPathEditField.Enable = 'on';
            S.UseParallelComputationCheckBox.Enable = 'on';
            S.FastFeatureCalculationCheckBox.Enable = 'on';
            S.DownsamplingAmountEditField.Enable = 'on';
            S.DownsamplingAmountofTimeLabel.Enable = 'on';
            S.AddToQueueButton.Enable = 'on';
        end
    end

    function resetAddFilesTab()
        S.dataFilePath = "";
        S.h5FilePath = "";
        S.H5FileEditField.Value = "";
        S.DataFileEditField.Value = "";
        S.OutputPathEditField.Value = "";
        
        S.ChooseOutputButton.Enable = 'off';
        S.OutputPathEditField.Enable = 'off';
        S.UseParallelComputationCheckBox.Value = true;
        S.UseParallelComputationCheckBox.Enable = 'off';
        S.FastFeatureCalculationCheckBox.Value = false;
        S.FastFeatureCalculationCheckBox.Enable = 'off';
        S.DownsamplingAmountEditField.Value = 1;
        S.DownsamplingAmountEditField.Enable = 'off';
        S.DownsamplingAmountofTimeLabel.Enable = 'off';
        S.AddToQueueButton.Enable = 'off';
    end

    function updateJobListDisplay()
        if isempty(S.jobQueue)
            % Show placeholder if no jobs
            S.JobsListBox.Items = cellstr("(No jobs in the queue)");
            S.JobsListBox.ItemsData = 0;
            S.JobsListBox.Value = 0;
            S.selectedJobIndex = [];
        else
            items = strings(1, numel(S.jobQueue));
            for k = 1:numel(S.jobQueue)
                j = S.jobQueue(k);
                [~, matName, matExt] = fileparts(j.mat);
                [~, h5Name,  h5Ext]  = fileparts(j.h5);
                [~, outName, outExt] = fileparts(j.output);
                
                switch j.algorithm
                    case 1
                        algo = 'EXTRACT';
                    case 2
                        algo = 'CAIMAN';
                    case 3
                        algo = 'Suite2p';
                    otherwise
                        algo = 'Unknown';
                end

                items(k) = sprintf("%s%s\n%s%s\nSave as: %s%s\nParallel: %s, Downsampling: %d, Fast: %s, Input type: %s\n Status: %s",...
                    matName, matExt, h5Name, h5Ext, outName, outExt,...
                    ternary(j.parallel,"Yes","No"),...
                    j.dt, ternary(j.fast,"Yes","No"), algo, j.status);
            end
            S.JobsListBox.Items = cellstr(items);
            S.JobsListBox.ItemsData = 1:numel(S.jobQueue);

            % If we had a selected index, keep it if possible
            if ~isempty(S.selectedJobIndex) && S.selectedJobIndex <= numel(S.jobQueue)
                S.JobsListBox.Value = S.selectedJobIndex;
            else
                S.JobsListBox.Value = 1; 
                S.selectedJobIndex = 1;
            end
        end
        updateButtonEnables();
    end

    function updateButtonEnables()
        hasJobs = ~isempty(S.jobQueue);
        canEdit = ~S.isRunning && hasJobs;

        S.MoveUpButton.Enable   = ternary(canEdit,'on','off');
        S.MoveDownButton.Enable = ternary(canEdit,'on','off');
        S.RemoveButton.Enable   = ternary(canEdit,'on','off');
        S.RunAllButton.Enable   = ternary(canEdit,'on','off');
    end

    function out = ternary(cond,a,b)
        if cond
            out = a;
        else
            out = b;
        end
    end

end
