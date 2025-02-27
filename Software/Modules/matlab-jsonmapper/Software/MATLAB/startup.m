function startup(options)
    % STARTUP Script to add paths to the MATLAB path
    % This script will add the paths below the root directory into the MATLAB
    % path.

    % Copyright 2021-2024 The MathWorks

    arguments
        options.verbose (1,1) logical = true
    end

    if options.verbose
        displayBanner('Adding JSONMapper paths');
    end

    if verLessThan('matlab','9.9')
        error('jsonmapper:version','MATLAB Release R2020b or newer is required');
    end

    here = fileparts(mfilename('fullpath'));
    rootDirs={...
        ...fullfile(here,'app', 'functions'),false;...
        ...fullfile(here,'app', 'mex'),false;...
        fullfile(here,'app', 'system'),false;...
        ...fullfile(here,'lib'),false;...
        ...fullfile(here,'config'),false;...
        ...fullfile(here,'script'),false;...
        ...fullfile(here,'sys','modules'),false;...
        };
    iAddFilteredFolders(rootDirs, verbose=options.verbose);
    if options.verbose
        fprintf("\n");
    end
end

%% iAddFilteredFolders Helper function to add all folders to the path
function iAddFilteredFolders(rootDirs, options)
    % Loop through the paths and add the necessary subfolders to the MATLAB path
    arguments
        rootDirs string
        options.verbose (1,1) logical = true
    end

    for pCount = 1:size(rootDirs,1)

        rootDir=rootDirs{pCount,1};
        if rootDirs{pCount,2}
            % recursively add all paths
            rawPath=genpath(rootDir);

            if ~isempty(rawPath)
                rawPathCell=textscan(rawPath,'%s','delimiter',pathsep);
                rawPathCell=rawPathCell{1};
            else
                rawPathCell = {rootDir};
            end

        else
            % Add only that particular directory
            rawPath = rootDir;
            rawPathCell = {rawPath};
        end

        % Remove undesired paths
        svnFilteredPath=strfind(rawPathCell,'.svn');
        gitFilteredPath=strfind(rawPathCell,'.git');
        slprjFilteredPath=strfind(rawPathCell,'slprj');
        sfprjFilteredPath=strfind(rawPathCell,'sfprj');
        rtwFilteredPath=strfind(rawPathCell,'_ert_rtw');

        % Loop through path and remove all the .svn entries
        if ~isempty(svnFilteredPath)
            for pCount=1:length(svnFilteredPath) %#ok<FXSET>
                filterCheck=[svnFilteredPath{pCount},...
                    gitFilteredPath{pCount},...
                    slprjFilteredPath{pCount},...
                    sfprjFilteredPath{pCount},...
                    rtwFilteredPath{pCount}];
                if isempty(filterCheck)
                    iSafeAddToPath(rawPathCell{pCount}, verbose=options.verbose);
                else
                    % ignore
                end
            end
        else
            iSafeAddToPath(rawPathCell{pCount}, verbose=options.verbose);
        end
    end
end

function iSafeAddToPath(pathStr, options)
    % Helper function to add to MATLAB path.
    arguments
        pathStr string {mustBeTextScalar}
        options.verbose (1,1) logical = true
    end

    % Add to path if the file exists
    if exist(pathStr,'dir')
        if options.verbose
            fprintf('Adding: %s\n',pathStr);
        end
        addpath(pathStr);
    else
        if options.verbose
            fprintf('Skipping: %s\n',pathStr);
        end
    end
end

function iSafeAddToJavaPath(pathStr, options) %#ok<DEFNU>
    % Helper function to add to the Dynamic Java classpath
    arguments
        pathStr string {mustBeTextScalar}
        options.verbose (1,1) logical = true
    end

    % Check the current java path
    jPaths = javaclasspath('-dynamic');

    % Add to path if the file exists
    if isfolder(pathStr) || isfile(pathStr)
        jarFound = any(strcmpi(pathStr, jPaths));
        if ~isempty(jarFound)
            if options.verbose
                fprintf('Adding: %s\n',pathStr);
            end
            javaaddpath(pathStr);
        else
            if options.verbose
                fprintf('Skipping: %s\n',pathStr);
            end
        end
    else
        if options.verbose
            fprintf('Skipping: %s\n',pathStr);
        end
    end
end

function displayBanner(appStr) %#ok<DEFNU>
    % Helper function to create a banner
    disp(appStr);
    disp(repmat('-',1,numel(appStr)));
end