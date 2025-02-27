function tf = checkJar() %#ok<INUSD>
    % CHECKJAR Checks for the presence to the required jar file
    % Returns a logical.

    % (c) MathWorks Inc 2024

    jarName = "MATLABClientCodegen-openapi-generator-" + openapi.internal.utils.getMATLABJarVersion() + ".jar";
    jarPath = fullfile(openapiRoot('lib', 'jar'), jarName);
    if ~isfile(jarPath)
        docPath = fullfile(openapiRoot( -2, 'Documentation', 'GettingStarted.md'));
        fprintf(2, 'Required jar file not found: %s\nFor build instructions see: %s\n', jarPath, docPath);
        tf = false;
    else
        tf = true;
    end
end