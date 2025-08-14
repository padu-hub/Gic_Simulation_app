% File: toggleCleanMode.m
function toggleCleanMode(app, mode)
    if strcmp(mode, 'On')
        app.IsCleanMode = true;
        app.StatusTextArea.Value = "🧼 Clean Mode ON — Click to edit.";
    else
        app.IsCleanMode = false;
        app.StatusTextArea.Value = "Clean Mode OFF.";
    end

    if isprop(app, 'redraw') && ismethod(app, 'redraw')
        redraw(app);  % Only if defined
    end
end
