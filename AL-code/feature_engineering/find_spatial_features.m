function [epsilon, corr_score, scores_1, scores_2, scores_3] = find_spatial_features(S_cell,M_cell,T_cell,parforFlag)
n_cell = size(M_cell,2);
epsilon = cell(1,n_cell);

n_cell = size(S_cell,2);
corr_score = zeros(1,n_cell);
scores_1 = zeros(5,n_cell);
scores_2 = zeros(5,n_cell);
scores_3 = zeros(5,n_cell);
if parforFlag
    parfor i =1:n_cell % JZ: should add parfor flag in the final version.
        M = M_cell{i};
        S = full(S_cell{i});
        T = T_cell{i};
        fov_size = [size(M,1),size(M,2)];
        M = reshape(M,size(M,1)*size(M,2),[]);
        S = reshape(S,size(S,1)*size(S,2),[]);
        [~,~,epsilon{i}] = solve_single_source_temporal(M,S);

        [corr_score(i), scores_1(:,i), scores_2(:,i), scores_3(:,i)] = ...
            find_spurious_cells(S, T, M, [], [], [], fov_size, 6, 0);
    end
else
    for i =1:n_cell
        temp = full(S_cell{i});
        temp = reshape(temp,size(temp,1)*size(temp,2),[]);
        M = M_cell{i};
        M = reshape(M,size(M,1)*size(M,2),[]);
        [~,~,epsilon{i}] = solve_single_source_temporal(M,temp);
    end
end


end