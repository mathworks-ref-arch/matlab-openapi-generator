function jarPath = getGeneratorJarPath(version)
    % GETGENERATORJARPATH Returns the 
    % Returns a string.
    % If the files does not exist an empty string is returned.

    %  (c) 2024 MathWorks, Inc.

    arguments
        version string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    jarDir = openapiRoot("lib", "jar");
    expectedPath = fullfile(openapiRoot("lib", "jar"), "openapi-generator-cli-" + version + ".jar");
    if isfile(expectedPath)
        jarPath = expectedPath;
    else
        dirResult = dir(jarDir + string(filesep) + "openapi-generator-cli-*.jar");
        if numel(dirResult) == 0
            fprintf(2, "No generator jar file not found in:\n  %s", jarDir);
        elseif numel(dirResult) == 1 %#ok<ISCL>
            dirJarPath = fullfile(dirResult.folder, dirResult.name);
            fprintf(2, "Found generator jar file:\n  %s\nbut expected: %s\n", dirJarPath, expectedPath);
        else
            fprintf(2, "More than one generator jar file found:\n");
            for n = 1:numel(dirResult)
                fprintf(2, "  %s\n", fullfile(dirResult(n).folder, dirResult(n).name));
            end
            fprintf(2, "Expected generator jar file not found:\n  %s\n", expectedPath);
        end
        jarPath = string.empty;
    end
end