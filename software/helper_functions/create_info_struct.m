function [INFO] = create_info_struct(dataset, session)
% Creates an information structure with statistics and session details.
% INPUT:
%   [dataset] : instance of the dataset class, used to calculate stats.
%   [session] : instance of the session class, containing session details.
% OUTPUT:
%   [INFO]    : structure containing average sorting time, total cells sorted,
%               precomputed file name, and the creation date/time.

    stats = dataset.get_expert_stats();
    total_cells_sorted = stats(1) + stats(2);

    if session.NUM_LABELING == 0
        AVG_TIME_SORTED = 0;
    else
        AVG_TIME_SORTED = round(session.TOTAL_TIME_SORTED / session.NUM_LABELING, 2);
    end

    
    currentDateTime = datetime('now');
    formattedDateTime = datestr(currentDateTime, 'yyyy-mm-dd HH:MM:SS');

    INFO = struct();
    INFO.AVG_TIME_SORTED = AVG_TIME_SORTED;
    INFO.total_cells_sorted = total_cells_sorted;
    INFO.precomputed_file_name = session.precomputed_file_name;
    INFO.date_created = formattedDateTime;
end