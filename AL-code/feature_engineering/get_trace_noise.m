function sn = get_trace_noise(Y)
    Y = Y';
    range_ff = [.25, .5];
    [psdx, ff] = pwelch(double(Y), [],[],[], 1);
    indf = and(ff>=range_ff(1), ff<=range_ff(2));
    sn = sqrt(exp(mean(log(psdx(indf,:)/2))))'; 
end