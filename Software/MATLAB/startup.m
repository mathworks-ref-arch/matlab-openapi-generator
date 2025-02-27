function startup(options)
    %% STARTUP - Script to add my paths to MATLAB path
    % This script will add the paths below the root directory into the MATLAB
    % path. You may modify undesired path
    % filter to your desire.

    % Copyright 2020-2024 The MathWorks, Inc.

    arguments
        options.setup (1,1) logical = false
        options.generatorJarPath string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.verbose (1,1) logical = true
    end

    % If deployed in a .ctf or .exe do not do anything in startup.m & return
    if isdeployed() || ismcc()
        return;
    end

    printBanner('MATLAB Generator for OpenAPI');

    if verLessThan('matlab','9.9') %#ok<VERLESSMATLAB>
        error('openapi:version','MATLAB Release R2020b or newer is required');
    end

    if options.setup
        % If in setup mode stop here as the package is not configured and continue with installation
        printBanner("Running Startup - Setup mode", leadingNewline=false);
    else
        printBanner("Running Startup", leadingNewline=false);
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
    % Add the framework to the path
    iAddFilteredFolders(rootDirs);

    % Add JSONMapper
    jsonMapperDir = fullfile(fileparts(here), 'Modules', 'matlab-jsonmapper');
    jsonMapperStartup = fullfile(jsonMapperDir, 'Software', 'MATLAB', 'startup.m');
    if isfile(jsonMapperStartup)
        run(jsonMapperStartup); % We have a module with a startup
    else
        warning("openapi:startup", "JSONMapper startup.m not found: %s, check the submodule has been recursively cloned", jsonMapperStartup);
    end

    if options.setup
        return;
    end

    printBanner('Checking for required jar files', leadingNewline=false);
    % Check for matlab jar file
    checkMATLABJar(verbose=options.verbose);

    % Check for generator jar file
    if isfield(options, "generatorJarPath")
        checkGeneratorJar(generatorJarPath=options.generatorJarPath, verbose=options.verbose);
    else
        checkGeneratorJar(verbose=options.verbose);
    end

    fprintf("Ready\n");
end


function tf = checkMATLABJar(options)
    arguments
        options.verbose (1,1) logical = true
    end

    jarName = "MATLABClientCodegen-openapi-generator-" + openapi.internal.utils.getMATLABJarVersion() + ".jar";
    jarPath = fullfile(openapiRoot('lib', 'jar'), jarName);
    if ~isfile(jarPath)
        fprintf(2, 'Required MATLAB generator jar file not found:\n  %s\nFor build instructions see: %s\n',...
            jarPath, openapi.internal.utils.editLink(openapiRoot( -2, 'Documentation', 'GettingStarted.md')));
        tf = false;
    else
        if options.verbose
            fprintf("MATLAB generator jar file found:\n  %s\n", jarPath);
        end
        tf = true;
    end
end


function checkGeneratorJar(options)
    % Assumes names of the form Software/MATLAB/lib/jar/openapi-generator-6.6.0.jar
    % unless specified as an option.
    arguments
        options.generatorJarPath string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.verbose (1,1) logical = true
    end

    if isfield(options, "generatorJarPath")
        if isfile(options.generatorJarPath)
            if options.verbose
                fprintf("Generator jar file found:\n  %s\n", options.generatorJarPath);
            end
        else
            fprintf(2, "Required generator jar file not found:\n  %s\n", options.generatorJarPath);
        end
    else
        jarDir = openapiRoot("lib", "jar");
        pomGenVersion = openapi.internal.utils.getGeneratorJarVersion();
        if ~isempty(pomGenVersion)
            generatorJarPath = fullfile(jarDir, "openapi-generator-cli-" + pomGenVersion + ".jar");
            if isfile(generatorJarPath)
                if options.verbose
                    fprintf("Generator jar file found:\n  %s\n", generatorJarPath);
                end
            else
                fprintf(2, "Required generator jar file not found:\n  %s\n", generatorJarPath);
                fprintf(2, "Run setup.m to download the required file. For instructions see:\n%s\n",...
                    openapi.internal.utils.editLink(openapiRoot( -2, 'Documentation', 'GettingStarted.md')));
            end
        end
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


function printBanner(str, options)
    arguments
        str string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.leadingNewline (1,1) logical = true
    end

    if options.leadingNewline
        fprintf("\n");
    end
    disp([char(str), newline,repmat('-',1,strlength(str))]);
end
