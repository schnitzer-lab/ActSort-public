function metric = compute_spat_corruption(F, siz, visualize, sparse_array, parforFlag)

    if nargin < 3 || isempty(visualize)
        visualize = false;
    end

    if nargin < 4 || isempty(sparse_array)
        sparse_array = 0;
    end

    h = siz(1);
    w = siz(2);
    nk = size(F,2);

    mask_in = F>1e-3;
    nnz_each = full(sum(mask_in,1));
    mean_each = full(sum(mask_in.*F,1)./nnz_each);
    if sparse_array
        metric = zeros(1,size(F,2));
        mask_in = sparse(mask_in);
        F = sparse(double(F));
        if parforFlag
            parfor cell = 1:size(F,2)
                mask_in_temp = full(mask_in(:,cell));
                F_temp = full(F(:,cell));
                F_diff = mask_in_temp.*bsxfun(@minus, F_temp, mean_each(cell));
                F_diff = bsxfun(@times, F_diff, sqrt(1./max(mean_each(cell), 1e-2)));
                var_each = sum(F_diff.^2, 1)./nnz_each(cell);
                mask_in_temp = reshape(mask_in_temp,h,w,1);
                F_temp = reshape(F_temp,h,w,1);
                filt = ones(4);%[0, 1, 0; 1, 1, 1; 0, 1, 0];
                filt = filt/sum(filt(:));
                % F_temp = sparse(F_temp);
                % local_mean = imfilter(F_temp,filt, 'replicate');
                % [local_mean]=local_imfilter(F_temp,filt);
                [F_diff] = local_imfilter(F_temp, filt,mask_in_temp,h,w)
                var_local_each = sum(F_diff(:).^2)./nnz_each(cell);
                % local_mean = full(local_mean);

                % F_diff = mask_in_temp.*(F_temp-local_mean);
                % 
                % local_mean = reshape(local_mean, h*w, 1);
                % F_diff = reshape(F_diff,h*w,1);
                % F_diff = F_diff .* (1./sqrt(max(1e-2, local_mean)));
                % 
                % var_local_each = sum(F_diff.^2, 1)./nnz_each(cell);
                metric(cell) = var_local_each ./ var_each;
            end
        else
            for cell = 1:size(F,2)
                mask_in_temp = full(mask_in(:,cell));
                F_temp = full(F(:,cell));
                F_diff = mask_in_temp.*bsxfun(@minus, F_temp, mean_each(cell));
                F_diff = bsxfun(@times, F_diff, sqrt(1./max(mean_each(cell), 1e-2)));
                var_each = sum(F_diff.^2, 1)./nnz_each(cell);
                mask_in_temp = reshape(mask_in_temp,h,w,1);
                F_temp = reshape(F_temp,h,w,1);
                filt = ones(4);%[0, 1, 0; 1, 1, 1; 0, 1, 0];
                filt = filt/sum(filt(:));

                % fprintf('Nonzero values: %d %%\n',length(nonzeros(F_temp))/length(F_temp(:))*100 );
                % F_temp_gpu = gpuArray(F_temp);
% filt_gpu = gpuArray(filt);

% local_mean_gpu = imfilter(F_temp_gpu, filt_gpu, 'replicate');

% local_mean = gather(local_mean_gpu); % Bring the result back to CPU
[F_diff] = local_imfilter(F_temp, filt,mask_in_temp,h,w);
var_local_each = sum(F_diff(:).^2)./nnz_each(cell);
                % local_mean = imfilter(F_temp,filt, 'replicate');
                % F_diff = mask_in_temp.*(F_temp-local_mean);
                % 
                % local_mean = reshape(local_mean, h*w, 1);
                % F_diff = reshape(F_diff,h*w,1);
                % F_diff = F_diff .* (1./sqrt(max(1e-2, local_mean)));
                % var_local_each = sum(F_diff.^2, 1)./nnz_each(cell);
                
                metric(cell) = var_local_each ./ var_each;
            end
        end
        F = reshape(F, h*w, nk);
    else
    F_diff = mask_in.*bsxfun(@minus, F, mean_each);
    F_diff = bsxfun(@times, F_diff, sqrt(1./max(mean_each, 1e-2)));
    var_each = sum(F_diff.^2, 1)./nnz_each;
%     var_each = zeros(nk, 1);
%     for i = 1:nk
%         f = F_diff(:, i);
%         var_each(i) = median(f(f>0));
%     end
    mask_in = reshape(mask_in,h,w,nk);
    F = reshape(F,h,w,nk);
    filt = ones(4);%[0, 1, 0; 1, 1, 1; 0, 1, 0];
    filt = filt/sum(filt(:));
    local_mean = imfilter(F,filt, 'replicate');
    F_diff = mask_in.*(F-local_mean);
    F = reshape(F, h*w, nk);
    local_mean = reshape(local_mean, h*w, nk);
    F_diff = reshape(F_diff,h*w,nk);
    F_diff = F_diff .* (1./sqrt(max(1e-2, local_mean)));
    
    var_local_each = sum(F_diff.^2, 1)./nnz_each;
%     var_local_each = zeros(nk, 1);
%     for i = 1:nk
%         f = F_diff(:, i);
%         var_local_each(i) = median(f(f>0));
%     end
    metric = var_local_each ./ var_each;
    F = reshape(F, h*w, nk);
    end
    
    if visualize
        for i = 24:size(F, 2)
            im = reshape(F(:, i), h, w);
            [x_range, y_range] = get_image_xy_ranges(im, 5);
            im_small = im(y_range(1):y_range(2), x_range(1):x_range(2));
            imagesc(im_small); axis image;colormap jet;
            title(sprintf('Component %d, spat corr: %.2f',  i, metric(i)));
            pause;
        end
    end
end


function [F_diff] = local_imfilter(F_temp, filt,mask_in_temp,h,w)
    % Get the size of the input matrix and filter
    [m, n] = size(F_temp);
    local_mean = zeros(m,n);
    [fm, fn] = size(filt);
    
    % % Ensure the filter is normalized (if not already provided)
    % if nargin < 2
    %     filt = ones(4) / 16; % 4x4 averaging filter
    % end
    
    % Calculate padding for the filter
    pad_m = floor(fm / 2);
    pad_n = floor(fn / 2);
    
    % Pad the input matrix with 'replicate' boundary condition
    % F_temp_full = padarray(full(F_temp), [pad_m, pad_n], 'replicate');
    [rows, cols, ~] = find(F_temp);
    % Compute boundaries for the local region of interest
    min_row = min(rows) - pad_m;
    max_row = max(rows) + pad_m;
    min_col = min(cols) - pad_n;
    max_col = max(cols) + pad_n;
    if min_row<1 ||max_row>m ||min_col<1 ||max_col>n
        %fprintf('one boundary case!\n')
        local_mean = imfilter(F_temp,filt,'replicate');
        F_diff = mask_in_temp.*(F_temp-local_mean);

                local_mean = reshape(local_mean, h*w, 1);
                F_diff = reshape(F_diff,h*w,1);
                F_diff = F_diff .* (1./sqrt(max(1e-2, local_mean)));
    else
        local_F_temp = F_temp(min_row:max_row,min_col:max_col);
        filted_local_F_temp = imfilter(local_F_temp,filt,'replicate');
        local_mean(min_row:max_row,min_col:max_col) = filted_local_F_temp;

        local_mask_in_temp = mask_in_temp(min_row:max_row,min_col:max_col);
        F_diff = local_mask_in_temp.*(local_F_temp-filted_local_F_temp);
        % local_F_diff = local_F_diff ;
                % local_mean = reshape(local_mean, h*w, 1);
                % F_diff = reshape(F_diff,h*w,1);
                F_diff = F_diff(:) .* (1./sqrt(max(1e-2, filted_local_F_temp(:))));

    end
    % 
    % filted_local_F_temp_full = imfilter(local_F_temp_full,filt,'replicate');
    % local_mean = F_temp;
    % local_mean(min(rows):max(rows)+4,min(cols):max(cols)+4)
    % % Initialize the full matrix for the result
    % local_mean = zeros(m, n);
    % 
    % % Get the non-zero elements of the sparse matrix
    % 
    % % A set to track the already updated elements
    % visited = false(m, n);
    % 
    % % Iterate over each non-zero element and apply the filter in its neighborhood
    % for k = 1:length(rows)
    %     r = rows(k);
    %     c = cols(k);
    % 
    %     % Define the region of influence (local neighborhood)
    %     r_start = max(r - pad_m, 1);
    %     r_end = min(r + pad_m, m);
    %     c_start = max(c - pad_n, 1);
    %     c_end = min(c + pad_n, n);
    % 
    %     % Update the local neighborhood (including zero elements around non-zero)
    %     for rr = r_start:r_end
    %         for cc = c_start:c_end
    %             if ~visited(rr, cc)
    %                 % Extract the local neighborhood from the padded full matrix
    %                 local_region = F_temp_full(rr:rr+fm-1, cc:cc+fn-1);
    % 
    %                 % Apply the filter to the local region
    %                 filtered_value = sum(local_region .* filt, 'all');
    % 
    %                 % Update the result at the corresponding position
    %                 local_mean(rr, cc) = filtered_value;
    % 
    %                 % Mark this element as visited
    %                 visited(rr, cc) = true;
    %             end
    %         end
    %     end
    % end
end

% function local_mean = local_imfilter(F_temp, filt)
%     % Get the size of the input matrix and filter
%     [m, n] = size(F_temp);
%     [fm, fn] = size(filt);
% 
%     % Ensure the filter is normalized (if not already provided)
%     if nargin < 2
%         filt = ones(4) / 16; % 4x4 averaging filter
%     end
% 
%     % Calculate padding for the filter
%     pad_m = floor(fm / 2);
%     pad_n = floor(fn / 2);
% 
%     % Pad the input matrix with 'replicate' boundary condition
%     F_temp_full = padarray(full(F_temp), [pad_m, pad_n], 'replicate');
% 
%     % Initialize the full matrix for the result
%     local_mean = zeros(m, n);
% 
%     % Get the non-zero elements of the sparse matrix
%     [rows, cols, ~] = find(F_temp);
% 
%     % A set to track the already updated elements
%     visited = false(m, n);
% 
%     % Iterate over each non-zero element and apply the filter in its neighborhood
%     for k = 1:length(rows)
%         r = rows(k);
%         c = cols(k);
% 
%         % Define the region of influence (local neighborhood)
%         r_start = max(r - pad_m, 1);
%         r_end = min(r + pad_m, m);
%         c_start = max(c - pad_n, 1);
%         c_end = min(c + pad_n, n);
% 
%         % Update the local neighborhood (including zero elements around non-zero)
%         for rr = r_start:r_end
%             for cc = c_start:c_end
%                 if ~visited(rr, cc)
%                     % Extract the local neighborhood from the padded full matrix
%                     local_region = F_temp_full(rr:rr+fm-1, cc:cc+fn-1);
% 
%                     % Apply the filter to the local region
%                     filtered_value = sum(local_region .* filt, 'all');
% 
%                     % Update the result at the corresponding position
%                     local_mean(rr, cc) = filtered_value;
% 
%                     % Mark this element as visited
%                     visited(rr, cc) = true;
%                 end
%             end
%         end
%     end
% end
% 




% other methods
%     h = siz(1);
%     w = siz(2);
%     nk = size(F,2);
%     
%     filt = fspecial('gaussian', [5, 5], 1);
%     F_smooth = imfilter(reshape(F, h, w, nk), filt, 'replicate');
%     F_smooth = reshape(F_smooth, h * w, nk);
%     F_smooth = bsxfun(@rdivide, F_smooth, max(1e-6, max(F_smooth, [], 1)));
%     mask = F_smooth>0.1;
%     X = abs(F - F_smooth) ./ max(F_smooth, F);
%     metric = zeros(1, size(F, 2), 'single');
%     for i = 1:size(F, 2)
%         x = X(mask(:, i), i);
%         metric(i)  = median(x);
%     end
    
    

%     h = siz(1);
%     w = siz(2);
%     mask_in = F>1e-3;
%     nk = size(F,2);
%     nnz_each = sum(mask_in,1);
%     mean_each = sum(mask_in.*F,1)./nnz_each;
%     var_each = sum(mask_in.*F.^2,1)./nnz_each-mean_each.^2;
%     mask_in = reshape(mask_in,h,w,nk);
%     F = reshape(F,h,w,nk);
%     filt = fspecial('gaussian', [5, 5], 2);%ones(5)/25
%     filt = filt/sum(filt(:));
%     F_smooth = imfilter(F,filt);
%     F_diff = mask_in.*(F-F_smooth);
%     F_diff = reshape(F_diff,h*w,nk);
%     var_local_each = sum(F_diff.^2,1)./nnz_each;
%     metric2 = var_local_each./var_each;
%     F = reshape(F, h*w, nk);