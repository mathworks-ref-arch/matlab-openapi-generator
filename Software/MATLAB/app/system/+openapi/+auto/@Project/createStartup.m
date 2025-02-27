function createStartup(obj)
    % createStartup Creates a Software/MATLAB/startup.m file to set paths

    %  Copyright 2024 MathWorks, Inc.

    arguments
        obj (1,1) openapi.auto.Project
    end

    fprintf("Writing startup.m file\n");

    templateFile = openapiRoot("app", "system", "+openapi", "+internal", "fixtures", "startup.m.txt");
    if ~isfile(templateFile)
        error("Project root template file not found: %s", templateFile);
    end

    startupDir =  fullfile(obj.path, "Software", "MATLAB");
    if ~isfolder(startupDir)
        [status, msg] = mkdir(functionsDir);
        if status ~= 1
            error("Directory creation failed for: %s\nMessage: %s", startupDir, msg);
        else
            fprintf("Created directory: %s\n", startupDir);
        end
    end

    outputFile = fullfile(startupDir, "startup.m");
    if isfile(outputFile)
        fprintf(2, "startup file found, overwriting: %s\n", outputFile);
    end

    tokens = struct;
    tokens.PROJECTFULLNAME = obj.projectFullName;
    tokens.PROJECTNAMESPACE = obj.projectNamespace;

    openapi.internal.utils.expandTokens(templateFile, outputFile, tokens);
end