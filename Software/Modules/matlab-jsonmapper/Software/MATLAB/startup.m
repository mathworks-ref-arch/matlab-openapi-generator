function startup
    % STARTUP Script to add paths to the MATLAB path
    % This script will add the paths below the root directory into the MATLAB
    % path.

    % Copyright 2021-2023 The MathWorks

    displayBanner('Adding JSONMapper paths');

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
    iAddFilteredFolders(rootDirs);
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

function displayBanner(appStr) %#ok<DEFNU>
    % Helper function to create a banner
    disp(appStr);
    disp(repmat('-',1,numel(appStr)));
end