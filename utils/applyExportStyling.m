function styleInfo = applyExportStyling(ax, bgColor)
% APPLYEXPORTSTYLING Set adaptive axes, title, labels, and legend styling for export

    % Determine contrasting text color
    switch lower(bgColor)
        case 'black'
            textColor = 'white';
        otherwise
            textColor = 'black';
    end

    % Save original styles
    styleInfo.AxesColor   = ax.Color;
    styleInfo.XColor      = ax.XColor;
    styleInfo.YColor      = ax.YColor;
    styleInfo.ZColor      = ax.ZColor;
    styleInfo.TitleColor  = ax.Title.Color;
    styleInfo.XLabelColor = ax.XLabel.Color;
    styleInfo.YLabelColor = ax.YLabel.Color;

    if isprop(ax, 'Parent') && isprop(ax.Parent, 'Color')
        styleInfo.FigureColor = ax.Parent.Color;
    end

    lg = legend(ax);
    if ~isempty(lg) && isvalid(lg)
        styleInfo.LegendColor     = lg.Color;
        styleInfo.LegendTextColor = lg.TextColor;
        styleInfo.LegendEdgeColor = lg.EdgeColor;
    else
        styleInfo.LegendColor     = [];
        styleInfo.LegendTextColor = [];
        styleInfo.LegendEdgeColor = [];
    end

    % Set parent figure background too
    if isprop(ax, 'Parent') && isprop(ax.Parent, 'Color') && ~strcmpi(bgColor, 'none')
        ax.Parent.Color = bgColor;
    end

    % Set axis and text styling
    ax.Color = bgColor;
    ax.XColor = textColor;
    ax.YColor = textColor;
    ax.ZColor = textColor;
    ax.Title.Color = textColor;
    ax.XLabel.Color = textColor;
    ax.YLabel.Color = textColor;

    % Style legend if it exists
    if ~isempty(lg) && isvalid(lg)
        lg.Color = bgColor;
        lg.TextColor = textColor;
        lg.EdgeColor = textColor;
        lg.Box = 'on';
        lg.Location = 'southwest';
    end

    drawnow;
end