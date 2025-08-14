function exportNetworkToMat(app)
% =======================================================================
% EXPORT CURRENT NETWORK STRUCTS TO .MAT FILE
% =======================================================================
[L_updated, T_updated] = getUpdatedNetwork(app);
[file,path] = uiputfile('updated_network.mat','Save Updated Network');
if file
    save(fullfile(path,file), 'L_updated', 'T_updated');
end
end