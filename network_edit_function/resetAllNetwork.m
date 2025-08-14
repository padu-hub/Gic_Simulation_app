function resetAllNetwork(app)
% =======================================================================
% RESET ALL NETWORK ELEMENTS
% Restores original transformer and line settings
% =======================================================================
app.L = app.OriginalL;
app.T = app.OriginalT;
populateNetworkEditor(app, app.L, app.T, app.S);
end