function update_progress(msg, val, progressDlg)
% This function updates the progress status in the GUI or MATLAB console.
% It is used to provide feedback on the progress of ongoing operations.
% If a GUI progress dialog is available, it updates the dialog. Otherwise,
% it displays progress in the MATLAB console.
% INPUT
%   [msg] : A message describing the current status or stage of the operation.
%   [val] : A numeric value between 0 and 1 indicating the progress percentage.
%   [progressDlg] : The handle to the GUI progress dialog. If the function is 
%                   operating outside of a GUI context, this should be [].
%

if ~isempty(progressDlg)
    progressDlg.Message = msg;
    if ~isempty(val)
        progressDlg.Value = val;
    end
    if val == 1
        close(progressDlg);
    end
else
    disp(msg);
    %disp("%"+string(val*100)+" DONE: "+msg);
end
end