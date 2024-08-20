function epsilon = compute_cell_epsilon(S_cell,M_cell, parforFlag)
n_cell = size(M_cell,2);
epsilon = cell(1,n_cell);

if parforFlag
    parfor i =1:n_cell % JZ: should add parfor flag in the final version.
        temp = full(S_cell{i});
        temp = reshape(temp,size(temp,1)*size(temp,2),[]);
        M = M_cell{i};
        M = reshape(M,size(M,1)*size(M,2),[]);
        [~,~,epsilon{i}] = solve_single_source_temporal(M,temp);
        % fprintf('Currently at %d.\n',i)
    end
else
    for i =1:n_cell
        temp = full(S_cell{i});
        temp = reshape(temp,size(temp,1)*size(temp,2),[]);
        M = M_cell{i};
        M = reshape(M,size(M,1)*size(M,2),[]);
        [~,~,epsilon{i}] = solve_single_source_temporal(M,temp);
        % fprintf('Currently at %d.\n',i)
    end
end


end