classdef session
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % VARIABLES COMING FROM PRECOMPUTATION
        spatial_weights              ndSparse
        traces                       single
        cellCenters                  single
        spikeIdxs                    single
        maxProj                      single
        cellBoundaries               cell
        snapshots                    cell
        snapshot_filters             cell
        snapshotCellBoundaries       cell
        neighborBoundaries           cell
        snapshotCLims                single
        
        % VARIABLES
        H                            single
        W                            single
        numCells                     single  
        cellLabels                   int8

        % Info variables
        NUM_LABELING                 single
        TOTAL_TIME_SORTED            single
        precomputed_file_name
    end
    
    methods
        function obj = session(precomputedOutput)
            %SESSION Construct an instance of this class
            
            % Extract variables from precomputedOutput
            obj.spatial_weights = precomputedOutput.spatial_weights;
            obj.traces = precomputedOutput.traces;
            obj.cellCenters = precomputedOutput.cellCenters;
            obj.spikeIdxs = precomputedOutput.spikeIdxs;
            obj.maxProj = precomputedOutput.max_im;
            obj.cellBoundaries = precomputedOutput.cellBoundaries;
            obj.snapshotCellBoundaries = precomputedOutput.snapshotCellBoundaries;
            obj.neighborBoundaries = precomputedOutput.neighborBoundaries;
            obj.snapshotCLims = precomputedOutput.snapshotCLims;
            obj.snapshots = precomputedOutput.snapshots;
            obj.snapshot_filters = precomputedOutput.snapshot_filters;

            % Generate other variables needed
            [obj.H, obj.W, obj.numCells] = size(obj.spatial_weights);
            obj.cellLabels = zeros(obj.numCells, 1,'int8');

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

        function obj = update_labels(obj, dataset, predict_cells)
            if predict_cells
                obj.cellLabels = predict_rest(dataset);
            else
                obj.cellLabels = dataset.labels_ex;
            end
        end

        % Extracts and updates the display of cell boundaries
        function [boundariesX, boundariesY] = get_boundaries(obj, cellIndices)
            corresponding_cells = obj.cellBoundaries(:, cellIndices);
            boundariesX = corresponding_cells(1, :); 
            boundariesY = corresponding_cells(2, :);
        
            % Convert cell arrays to matrices
            boundariesX = [boundariesX{:}];
            boundariesY = [boundariesY{:}];
        end

        % Counts the number of spikes for the selected cell
        function numSpikes = get_num_spikes(obj, cell_idx)
            spikeIndices = obj.spikeIdxs(:, cell_idx);
            numSpikes = numel(remove_nans(spikeIndices));
        end

    end
end

