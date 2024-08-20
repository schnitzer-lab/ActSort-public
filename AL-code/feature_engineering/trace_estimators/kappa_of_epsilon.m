function kappa = kappa_of_epsilon(eps)
    eps = max(eps, 0.001);
    kappa = -0.3775*log(eps) - 0.0597*eps + 0.0544;
end