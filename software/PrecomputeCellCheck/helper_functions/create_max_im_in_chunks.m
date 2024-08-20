function max_im = create_max_im_in_chunks(movie_path, dataset_name, m_size)
% This function creates the maximum projection of the movie.
% The maximum projection is used for visualization in the GUI.
% INPUT
%   [movie] : The movie array, or [] if the movie is too large to fit in memory.
%   [movie_path] : The path to the movie file, or [] if the movie can fit in memory.
%
% OUTPUT
%   [max_im] : The maximum projection image.
%

    max_im = -inf(m_size(1), m_size(2));
    chunkSize = 500;
    for i = 1:chunkSize:m_size(3)
        start = [1, 1, i];
        if i+chunkSize <= m_size(3)
            count = [Inf, Inf, chunkSize];
        else
            count = [Inf, Inf, m_size(3)-i];
        end
        
        snap = h5read(movie_path, dataset_name, start, count);
        max_im = max(max_im, max(snap,[],3));
    end
end