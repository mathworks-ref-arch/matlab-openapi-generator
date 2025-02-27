function createRoot(obj)
    % createStartup Creates a Software/MATLAB/app/functions/projectNamespaceRoot.m file to set paths

    %  Copyright 2024 MathWorks, Inc.

    arguments
        obj (1,1) openapi.auto.Project
    end

    fprintf("Writing projectRoot file\n");

    templateFile = openapiRoot("app", "system", "+openapi", "+internal", "fixtures", "projectRoot.m.txt");
    if ~isfile(templateFile)
        error("Project root template file not found: %s", templateFile);
    end

    functionsDir =  fullfile(obj.path, "Software", "MATLAB", "app", "functions");
    
    if ~isfolder(functionsDir)
        [status, msg] = mkdir(functionsDir);
        if status ~= 1
            error("Directory creation failed for: %s\nMessage: %s", functionsDir, msg);
        else
            fprintf("Created directory: %s\n", functionsDir);
        end
    end

    outputFile = fullfile(functionsDir, obj.projectNamespace + "Root.m");
    
     if isfile(outputFile)
        fprintf(2, "projectRoot file found, overwriting: %s\n", outputFile);
    end

    tokens = struct;
    tokens.PROJECTROOT = obj.projectNamespace + "Root";

    openapi.internal.utils.expandTokens(templateFile, outputFile, tokens);
end