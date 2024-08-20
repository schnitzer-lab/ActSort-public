function [S,T,M_cell,T_cell,S_cell] = parse_precomputed_output(precomputedOutput)
    S = precomputedOutput.spatial_weights;
    T = precomputedOutput.traces';
    M_cell = precomputedOutput.snapshots;
    T_cell = precomputedOutput.snapshot_traces;
    S_cell = precomputedOutput.snapshot_filters;
    
    for i=1:size(M_cell,2)
        temp = M_cell{i};
        temp = reshape(temp,size(temp,1),size(temp,2),[]);
        M_cell{i} = temp;
        temp = T_cell{i};
        temp = reshape(temp',[],1);
        T_cell{i} = temp';
    end
end
