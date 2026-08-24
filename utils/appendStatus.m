function appendStatus(app, msg)
app.StatusTextArea.Value = [app.StatusTextArea.Value; msg];
drawnow;
end