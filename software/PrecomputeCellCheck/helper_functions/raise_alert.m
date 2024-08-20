function raise_alert(msg, type, progressDlg, UIFigure)
% This function is used for raising alerts, both within the GUI and in 
% the MATLAB environment. 
% INPUT
%   [msg] : The message to be displayed.
%   [type] : The type of the alert. Options include:
%       - "error"
%       - "success"
%   [progressDlg] : The progressdlg component for GUI handling. Use [] if 
%                   not working within the GUI.
%   [UIFigure] : The UIFigure component for GUI handling. Use [] if 
%                not working within the GUI.
% 
    switch type
        case 'error'
            if ~isempty(progressDlg) && ~isempty(UIFigure)
                uialert(UIFigure, msg, 'Error', 'Icon', 'error');
                figure(UIFigure);
                close(progressDlg);
            else
                error(msg);
            end
        case 'success'
            if ~isempty(UIFigure)
                uialert(UIFigure , msg, 'Success', 'Icon', 'success');
                figure(UIFigure);
            else
                disp(msg);
            end
    end
end