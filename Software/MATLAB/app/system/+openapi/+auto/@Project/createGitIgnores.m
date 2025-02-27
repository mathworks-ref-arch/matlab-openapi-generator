function createGitIgnores(obj, gitIgnorePath, options)
    % createGitIgnores Writes a .gitignore file
    % Will overwrite an existing file.
    
    %  Copyright 2024 The MathWorks, Inc.

    arguments
        obj (1,1) openapi.auto.Project
        gitIgnorePath string {mustBeTextScalar, mustBeNonzeroLengthText} = fullfile(obj.path, ".gitignore")
        options.gitIgnoreEntries string
    end

    fprintf("Adding a .gitignore file: %s\n", gitIgnorePath);

    ignore = createEmptyFile(gitIgnorePath);
    % Add entries even if the files/directories do not exist at this point
    appendToFile(ignore, join(["Software", "MATLAB", "app", "system", obj.projectNamespace+"_build.log"], filesep));
    appendToFile(ignore, join(["Software", "MATLAB", "app", "system", ".openapi-generator-ignore"], filesep));
    appendToFile(ignore, join(["Software", "MATLAB", "app", "system", ".openapi-generator"], filesep));
    if isfield(options, "gitIgnoreEntries")
        for n = 1:numel(options.gitIgnoreEntries)
            appendToFile(ignore, options.gitIgnoreEntries(n));
        end
    end
end


function path = appendToFile(path, entry, options)
    arguments
        path string {mustBeTextScalar, mustBeNonzeroLengthText}
        entry string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.addNewline (1,1) logical = true
    end

    [fid, errmsg] = fopen(path, 'a');
    if fid == -1
        error("Unable to append to file: %s, Message: %s", path, errmsg);
    else
        if options.addNewline
            fprintf(fid, "%s\n", entry);
        else
            fprintf(fid, "%s", entry);
        end
        fclose(fid);
    end
end


function path = createEmptyFile(path)
    arguments
        path string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    [fid, errmsg] = fopen(path, 'w');
    if fid == -1
        error("Unable to create empty file: %s, Message: %s", path, errmsg);
    else
        fclose(fid);
    end
end