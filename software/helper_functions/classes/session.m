classdef session
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % VARIABLES COMING FROM PRECOMPUTATION
        spatial_weights              cell %ndSparse
        traces                       cell %single
        cellCenters                  cell %single
        spikeIdxs                    cell %single
        maxProj                      cell %single
        cellBoundaries               cell %cell
        snapshots                    cell %cell
        snapshot_filters             cell %cell
        snapshotCellBoundaries       cell %cell
        neighborBoundaries           cell %cell
        snapshotCLims                cell %single
        
        % VARIABLES
        H                            cell %single
        W                            cell %single
        numCells                     cell %single  
        cellLabels                   cell %int8

        % Info variables
        NUM_LABELING                 single
        TOTAL_TIME_SORTED            single
        precomputed_file_name        cell %string
    end
    
    methods
        function obj = session(precomputedOutputs)
            %SESSION Construct an instance of this class
            
            for i = 1:length(precomputedOutputs)
                precomputedOutput = precomputedOutputs(i);
                % Extract variables from precomputedOutput
                obj.spatial_weights{i} = precomputedOutput.spatial_weights;
                obj.traces{i} = precomputedOutput.traces;
                obj.cellCenters{i} = precomputedOutput.cellCenters;
                obj.spikeIdxs{i} = precomputedOutput.spikeIdxs;
                obj.maxProj{i} = precomputedOutput.max_im;
                obj.cellBoundaries{i} = precomputedOutput.cellBoundaries;
                obj.snapshotCellBoundaries{i} = precomputedOutput.snapshotCellBoundaries;
                obj.neighborBoundaries{i} = precomputedOutput.neighborBoundaries;
                obj.snapshotCLims{i} = precomputedOutput.snapshotCLims;
                obj.snapshots{i} = precomputedOutput.snapshots;
                obj.snapshot_filters{i} = precomputedOutput.snapshot_filters;
    
                % Generate other variables needed
                [obj.H{i}, obj.W{i}, obj.numCells{i}] = size(obj.spatial_weights{i});
                obj.cellLabels{i} = zeros(obj.numCells{i}, 1,'int8');
            end

            % INFO
            obj.NUM_LABELING = 0;
            obj.TOTAL_TIME_SORTED = 0;
        end

        function obj = increase_num_labeling(obj, amount)
            obj.NUM_LABELING = obj.NUM_LABELING + amount;
        end

        function obj = update_total_time_sorted(obj, labeling_timer)
            time_elapsed = posixtime(datetime) - labeling_timer;
            obj.TOTAL_TIME_SORTED = obj.TOTAL_TIME_SORTED + time_elapsed;
        end

        function obj = update_labels(obj, datasets, predict_cells)
            for i = 1:len(datasets)
                dataset = datasets{i};
                if predict_cells
                    obj.cellLabels{i} = predict_rest(dataset);
                else
                    obj.cellLabels{i} = dataset.labels_ex;
                end
            end
        end

        % Extracts and updates the display of cell boundaries
        function [boundariesX, boundariesY] = get_boundaries(obj, cellIndices, datasetIdx)
            corresponding_cells = obj.cellBoundaries{datasetIdx}(:, cellIndices);
            boundariesX = corresponding_cells(1, :); 
            boundariesY = corresponding_cells(2, :);
        
            % Convert cell arrays to matrices
            boundariesX = [boundariesX{:}];
            boundariesY = [boundariesY{:}];
        end

        % Counts the number of spikes for the selected cell
        function numSpikes = get_num_spikes(obj, cell_idx, datasetIdx)
            spikeIndices = obj.spikeIdxs{datasetIdx}(:, cell_idx);
            numSpikes = numel(remove_nans(spikeIndices));
        end

    end
end

