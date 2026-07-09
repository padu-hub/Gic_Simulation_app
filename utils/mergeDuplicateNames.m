function [dataOut,namesOut] = mergeDuplicateNames(data,names)

% Original physical line names (always 5)
baseList = {'Line1','Line2','Line3','Line4','Line5'};

% Determine orientation
if size(data,1)==numel(names)
    alongRows = true;
elseif size(data,2)==numel(names)
    alongRows = false;
else
    error('Dimension mismatch.');
end

% Allocate output
if alongRows
    dataOut = zeros(5,size(data,2));
else
    dataOut = zeros(size(data,1),5);
end

% Sum every entry into its parent line
for k = 1:numel(names)

    name = names{k};

    idx = strfind(name,'_');
    if ~isempty(idx)
        name = name(1:idx(1)-1);
    end

    parent = find(strcmp(baseList,name),1);

    if isempty(parent)
        warning('Ignoring unknown line "%s".',names{k});
        continue
    end

    if alongRows
        dataOut(parent,:) = dataOut(parent,:) + data(k,:);
    else
        dataOut(:,parent) = dataOut(:,parent) + data(:,k);
    end

end

namesOut = baseList;

end