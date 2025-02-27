function result = getGeneratorJarVersion()
    % GETGENERATORJARVERSION Retrieve openapi-generator-version property from pom-file
    % Returns a string.
    % Returns an empty string if a value is not found.

    % (c) MathWorks Inc 2024

    pomFile = fullfile(openapiRoot( -1, 'Java'), 'pom.xml');
    if ~isfile(pomFile)
        error('openapi:getGeneratorJarVersion','Expected pom file not found: %s', pomFile);
    end
    tree = xmlread(pomFile);
    myStruct = parseChildNodes(tree);
    if ~isfield(myStruct, "Children")
        error('openapi:getGeneratorJarVersion','No Children field found.');
    end

    result = string.empty;
    for n = 1:numel(myStruct.Children)
        if strcmp(myStruct.Children(n).Name, "properties")
            for m = 1:numel(myStruct.Children(n).Children)
                if strcmp(myStruct.Children(n).Children(m).Name, "openapi-generator-version")
                    result = string(myStruct.Children(n).Children(m).Children.Data);
                    return;
                end
            end
        end
    end
end


function children = parseChildNodes(theNode)
    % Recurse over node children.
    children = [];
    if theNode.hasChildNodes
        childNodes = theNode.getChildNodes;
        numChildNodes = childNodes.getLength;
        allocCell = cell(1, numChildNodes);

        children = struct(...
            'Name', allocCell, 'Attributes', allocCell,...
            'Data', allocCell, 'Children', allocCell);

        for count = 1:numChildNodes
            theChild = childNodes.item(count-1);
            children(count) = makeStructFromNode(theChild);
        end
    end
end


function nodeStruct = makeStructFromNode(theNode)
    % Create structure of node info.

    nodeStruct = struct(...
        'Name', char(theNode.getNodeName),...
        'Attributes', parseAttributes(theNode),...
        'Data', '',...
        'Children', parseChildNodes(theNode));

    if any(strcmp(methods(theNode), 'getData'))
        nodeStruct.Data = char(theNode.getData);
    else
        nodeStruct.Data = '';
    end
end


function attributes = parseAttributes(theNode)
    % Create attributes structure.

    attributes = [];
    if theNode.hasAttributes
        theAttributes = theNode.getAttributes;
        numAttributes = theAttributes.getLength;
        allocCell = cell(1, numAttributes);
        attributes = struct('Name', allocCell, 'Value',...
            allocCell);

        for count = 1:numAttributes
            attrib = theAttributes.item(count-1);
            attributes(count).Name = char(attrib.getName);
            attributes(count).Value = char(attrib.getValue);
        end
    end
end