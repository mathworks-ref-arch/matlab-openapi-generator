function startup(varargin)
    %% STARTUP - Script to add my paths to MATLAB path
    % This script will add the paths below the root directory into the MATLAB
    % path. You may modify undesired path
    % filter to your desire.

    % Copyright 2020-2022 The MathWorks, Inc.

    % If deployed in a .ctf or .exe do not do anything in startup.m & return
    if isdeployed() || ismcc()
        return;
    end

    displayBanner('Adding MATLAB Generator for OpenAPI paths');

    if verLessThan('matlab','9.9')
        error('openapi:version','MATLAB Release R2020b or newer is required');
    end

    %% Set up the paths to add to the MATLAB path
    % This should be the only section of the code that you need to modify
    % The second argument specifies whether the given directory should be
    % scanned recursively
    here = fileparts(mfilename('fullpath'));

    rootDirs={...
        fullfile(here,'app', 'functions'),false;...
        fullfile(here,'app', 'system'),false;...
        ...fullfile(here,'lib'),false;...
        ...fullfile(here,'config'),false;...
        };

    %% Add the framework to the path
    iAddFilteredFolders(rootDirs);

    jsonMapperDir = fullfile(fileparts(here), 'Modules', 'matlab-jsonmapper');
    jsonMapperStartup = fullfile(jsonMapperDir, 'Software', 'MATLAB', 'startup.m');
    if isfile(jsonMapperStartup)
        % We have a module with a startup
        run(jsonMapperStartup);
    else
        warning("openapi:startup", "JSONMapper startup.m not found: %s, check the submodule has been recursively cloned", jsonMapperStartup);
    end


    % Check for generator jar file
    jarName = "MATLABClientCodegen-openapi-generator-" + openapi.build.Client.getJarVersion() + ".jar";
    jarPath = fullfile(openapiRoot('lib', 'jar'), jarName);
    if ~isfile(jarPath)
        docPath = fullfile(openapiRoot( -2, 'Documentation', 'GettingStarted.md'));
        warning('Client:checkJar','Required jar file not found: %s\nFor build instructions see: %s', jarPath, docPath);
    else
        fprintf("Generator jar file found: %s\n", jarPath);
    end

end

%% iAddFilteredFolders Helper function to add all folders to the path
function iAddFilteredFolders(rootDirs)
    % Loop through the paths and add the necessary subfolders to the MATLAB path
    for pCount = 1:size(rootDirs,1)

        rootDir=rootDirs{pCount,1};
        if rootDirs{pCount,2}
            % recursively add all paths
            rawPath=genpath(rootDir);

            if ~isempty(rawPath)
                rawPathCell=textscan(rawPath,'%s','delimiter',pathsep);
                rawPathCell=rawPathCell{1};
            end

        else
            % Add only that particular directory
            rawPath = rootDir;
            rawPathCell = {rawPath};
        end

        % if rawPath is empty then we have an entry in rootDir that does not
        % exist on the path so we should not try to add an entry for them
        if ~isempty(rawPath)
            % remove undesired paths
            svnFilteredPath=strfind(rawPathCell,'.svn');
            gitFilteredPath=strfind(rawPathCell,'.git');
            slprjFilteredPath=strfind(rawPathCell,'slprj');
            sfprjFilteredPath=strfind(rawPathCell,'sfprj');
            rtwFilteredPath=strfind(rawPathCell,'_ert_rtw');

            % loop through path and remove all the .svn entries
            if ~isempty(svnFilteredPath)
                for pCount=1:length(svnFilteredPath) %#ok<FXSET>
                    filterCheck=[svnFilteredPath{pCount},...
                        gitFilteredPath{pCount},...
                        slprjFilteredPath{pCount},...
                        sfprjFilteredPath{pCount},...
                        rtwFilteredPath{pCount}];
                    if isempty(filterCheck)
                        iSafeAddToPath(rawPathCell{pCount});
                    else
                        % ignore
                    end
                end
            else
                iSafeAddToPath(rawPathCell{pCount});
            end
        end
    end

end

function iSafeAddToPath(pathStr)
    % Helper function to add to MATLAB path.
    % Add to path if the file exists
    if exist(pathStr,'dir')
        fprintf('Adding: %s\n',pathStr);
        addpath(pathStr);
    else
        fprintf('Skipping: %s\n',pathStr);
    end
end

function iSafeAddToJavaPath(pathStr) %#ok<DEFNU>
    % Helper function to add to the Dynamic Java classpath
    % Check the current java path
    jPaths = javaclasspath('-dynamic');

    % Add to path if the file exists
    if isfolder(pathStr) || isfile(pathStr)
        jarFound = any(strcmpi(pathStr, jPaths));
        if ~isempty(jarFound)
            fprintf('Adding: %s\n',pathStr);
            javaaddpath(pathStr);
        else
            fprintf('Skipping: %s\n',pathStr);
        end
    else
        fprintf('Skipping: %s\n',pathStr);
    end
end

function displayBanner(appStr)
    % Helper function to create a banner
    disp(appStr);
    disp(repmat('-',1,numel(appStr)));
end

