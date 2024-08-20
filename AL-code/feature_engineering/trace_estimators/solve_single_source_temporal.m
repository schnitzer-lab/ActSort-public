function [x,x_nls,epsilon] = solve_single_source_temporal(B,a)

if issparse(a)
    a = full(a);
end

if ndims(B) == 3
    B = reshape(B,size(B,1)*size(B,2),[]);
end

noise_std = estimate_noise_std(B,2);
noise_std = median(noise_std(:));

kappa_func = @(d, k, v, alpha) kappa_of_epsilon(eps_func(d, k, v, alpha));
use_gpu = isa(B, 'gpuArray');

TOL = 1e-4;
k = size(B, 2);
a2 = a.^2;
max_iter = 30;

% Initialize x to the NNLS solution
x = max(0, (a'*B)/ sum(a2));
x_nls = x;

% Initialize kappa
kappa = ones(1, k, 'single');
kappa = maybe_gpu(use_gpu, kappa);


idx_estimate_kappa = round(max_iter*[1/2, 2/3, 3/4]);
% a_mask is computed for computing avg. data statistic for kappa est
a_mask = (1./(1+1*a)) .* (a>0);
a_mask = (a_mask)'/sum(a_mask);
% alpha is a variable needed for kappa est
alpha = 0.05*sum(a)/sum(a>0)*mean(a)/mean(a.^2);


scaled_kappa = kappa * noise_std;


% Newton solve
i = 0;
while i < max_iter
    i = i + 1;
    x_before = x;
    res = B-a * x;

    % Estimate kappa
    if ismember(i, idx_estimate_kappa)
        v = 0;
        % Compute the data statistics
        d_proto = (bsxfun(@minus, res, v*noise_std)>0);
        d = a_mask * d_proto;
        % Update kappa
        kappa = maybe_gpu(use_gpu, kappa_func(d, kappa, v, alpha));
        epsilon = eps_func(d, kappa, v, alpha);
        % Update kappa*noise_std
        scaled_kappa = kappa * noise_std;
    end
    
    mask = bsxfun(@ge, res, scaled_kappa);
    clear res;
    mask_not = ~mask;

    x = a'*(B.*mask_not);
    x = x + scaled_kappa.*(a'*single(mask));
    x = x ./ (a2'* single(mask_not));
    x = max(x, 0);
   
end

end
