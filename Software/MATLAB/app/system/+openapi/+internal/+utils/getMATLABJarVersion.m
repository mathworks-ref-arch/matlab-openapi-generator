function v = getMATLABJarVersion()
    % GETMATLABJARVERSION Retrieve version from pom-file
    % Returns a string.

    % (c) MathWorks Inc 2024


    pomFile = fullfile(openapiRoot( -1, 'Java'), 'pom.xml');
    if ~isfile(pomFile)
        error('openapi:getMATLABJarVersion','Expected pom file not found: %s', pomFile);
    end
    X = xmlread(pomFile);
    projNode = X.getElementsByTagName('project').item(0);
    versionElement = projNode.getElementsByTagName('version').item(0);
    templateVersion = versionElement.getTextContent();

    v = string(templateVersion);
end