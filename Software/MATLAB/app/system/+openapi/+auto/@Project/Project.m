classdef Project < handle
    % Project Class to represent a project to be created using the OpenAPI
    % generator and populated into a git repository.
    % Currently only GitLab is supported
    % 
    % Required arguments:
    %   projectShortName :  A short name for the project ideally a single
    %                       word. This name is optionally used to create
    %                       paths and a longer project name. MATLAB
    %                       variable naming conventions should ideally be
    %                       respected.
    %
    %   inputSpec : A local path or http(s) URL for an OpenAPI spec in JSON
    %               or YAML format.
    %
    % Optional arguments:
    %   projectNamespace :  Namespace used for the projects namespace, by
    %                       default this value is a lowercase normalized
    %                       version of the projectShortName.
    %
    %   projectFullName :   A longer name for the project, by default 
    %                       "MATLAB interface for [projectShortName]" is used.
    %   outputDirectory: An alternative output directory.
    %
    %   useExistingDirectory :  Logical to reuse an existing project directory,
    %                           default is true.
    %
    %   additionalClientArguments : A cell array of arguments that are passed to the
    %                               openapi.build.Client configuration step.
    %
    %   createGitRepo : Logical to create a local Git repo, default is false.
    %
    %   createGitLabProject :   Logical to create a GitLab project, default is false.
    %                           A local git repo is also created in this case.
    %
    %   settingsFile :  Path to a default settings file, default is
    %                   Software/MATLAB/config/project_settings.json
    %
    %   additionalFiles : Additional filepaths to copy to the projects path.
    %
    %   version :   A version value to write to the top-level VERSION file, the
    %               default is 0.0.1
    %
    %   createRefAPIDoc :   Logical flag to create an API reference document, default
    %                       is true. This is currently an internal MathWorks.
    %                       It must be added to the MATLAB path in advance.
    %
    %   gitIgnore : A string array of paths to add to the top-level .gitignore file.
    %
    %   useGitLabSSH :  Logical to indicate using the GitLab SSH interface, if set
    %                   to false HTTPS is used, the default is true.
    %
    %
    % Example:
    %   projectBaseName = "GitLab"
    %   spec = "https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/api/openapi/openapi.yaml"
    %   p = openapi.auto.Project(projectBaseName, spec)

    %  2024 MathWorks, Inc.

    properties
        projectFullName string    % e.g. MATLAB interface for Birds
        projectShortName string   % e.g. Birds
        projectPathName string    % e.g. matlab-birds
        projectNamespace string   % e.g. birds
        inputSpec string
        localSpec string
        settings struct
        path string
    end

    methods
        function obj = Project(projectShortName, inputSpec, options)
            arguments
                projectShortName string {mustBeTextScalar, mustBeNonzeroLengthText}
                inputSpec string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.projectNamespace string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.projectFullName string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.outputDirectory string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.useExistingDirectory (1,1) logical = true
                options.additionalClientArguments cell
                options.createGitRepo (1,1) logical = false
                options.createGitLabProject (1,1) logical = false
                options.settingsFile string {mustBeTextScalar, mustBeNonzeroLengthText} = openapiRoot("config", "project_settings.json")
                options.additionalFiles string = string.empty
                options.version string {mustBeTextScalar, mustBeNonzeroLengthText} = "0.0.1"
                options.createRefAPIDoc (1,1) logical = true
                options.gitIgnore string
                options.useGitLabSSH (1,1) logical = true
            end

            obj.inputSpec = inputSpec;
            obj.projectShortName = projectShortName;

            if isfield(options, "projectFullName")
                obj.projectFullName = options.projectFullName;
            else
                obj.projectFullName = "MATLAB interface for " + obj.projectShortName;
            end

            if isfield(options, "projectNamespace")
                obj.projectNamespace = options.projectNamespace;
            else
                obj.projectNamespace = lower(matlab.lang.makeValidName(obj.projectShortName));
            end

            if isfield(options, "projectPathName")
                obj.projectPathName = options.projectPathName;
            else
                obj.projectPathName = "matlab-" + lower(matlab.lang.makeValidName(obj.projectShortName));
            end

            obj.readSettings(options.settingsFile);

            % Call after readSettings
            args = openapi.internal.utils.addArgs(options, "outputDirectory");
            obj.createPath(options.useExistingDirectory, args{:});

            % Call after createPath, copies the spec into the project
            obj.getLocalSpec(inputSpec);

            % Call after createPath
            obj.copyBaseLineFiles(options.additionalFiles);

            % Call after createPath
            obj.addVersion(options.version);
            obj.addReleasenotes(options.version);

            % Call after getLocalSpec
            args = openapi.internal.utils.addArgs(options, "additionalClientArguments");
            client = obj.createClient(args{:});

            % Call after createClient
            if ~buildClient(obj, client)
                error("Client generation failed, exiting");
            end

            % Call after buildClient
            obj.addReadme();

            % Create startup.m and projectRoot.m functions
            obj.createStartup();
            obj.createRoot();

            % Call after buildClient
            obj.addDocumentationDir();

            % Call after addDocumentation
            if options.createRefAPIDoc
                disp("Creating API reference documentation");
                obj.createRefAPIDoc();
            end

            if options.createGitLabProject
                gitLabCreateTf = obj.createGitLabRepo(options.useGitLabSSH); %#ok<NASGU>
            elseif options.createGitRepo
                gitCreateTf = obj.createLocalGitRepo(); %#ok<NASGU>
            end
            
            fprintf("Project creation complete\n");
            fprintf("Local path: %s\n", obj.path);
            fprintf("To start run: %s\n\n", fullfile(obj.path, "Software", "MATLAB", "startup.m"));
        end


        function gitLabCreateTf = createGitLabRepo(obj, useGitLabSSH)
            arguments
                obj (1,1) openapi.auto.Project
                useGitLabSSH (1,1) logical = true
            end

            % Assume failure
            gitLabCreateTf = false;
            
            [gitLabCreateProjectTf, gitlabResponse] = obj.createGitLabProjectAPICall();
            if ~gitLabCreateProjectTf
                if isfield(gitlabResponse.Body.Data, "message") && isstruct(gitlabResponse.Body.Data.message) > 0 && ...
                        ((isfield(gitlabResponse.Body.Data.message, "project_namespace_name") && contains(gitlabResponse.Body.Data.message.project_namespace_name, 'has already been taken')) ||...
                        (isfield(gitlabResponse.Body.Data.message, "name") && contains(gitlabResponse.Body.Data.message.name, 'has already been taken')) ||...
                        (isfield(gitlabResponse.Body.Data.message, "path") && contains(gitlabResponse.Body.Data.message.path, 'has already been taken')))
                    fprintf(2, "GitLab repository name, path or project_namespace_name already in use\n");
                else
                    fprintf(2, "GitLab repository creation failed\n");
                end
            else
                if (isfield(gitlabResponse.Body.Data, "web_url") && strlength(gitlabResponse.Body.Data.web_url) > 0) &&...
                        (isfield(gitlabResponse.Body.Data, "ssh_url_to_repo") && strlength(gitlabResponse.Body.Data.ssh_url_to_repo) > 0) &&...
                        (isfield(gitlabResponse.Body.Data, "http_url_to_repo") && strlength(gitlabResponse.Body.Data.http_url_to_repo) > 0)
                    
                    % Create a local repo to push to the project
                    gitCreateTf = obj.createLocalGitRepo();
                    if ~gitCreateTf
                        fprintf(2, "Creation of local Git repository failed\n");
                    else
                        gitlabLink = sprintf('<a href="%s")">%s</a>', gitlabResponse.Body.Data.web_url, gitlabResponse.Body.Data.web_url);
                        fprintf("GitLab repo: %s\n", gitlabLink);
                        pushTf = obj.pushToExistingGitLabProject(webURL=gitlabResponse.Body.Data.web_url, sshURL=gitlabResponse.Body.Data.ssh_url_to_repo, httpURL=gitlabResponse.Body.Data.http_url_to_repo, useSSH=useGitLabSSH);
                        if ~pushTf
                            fprintf(2, "Push of local repository to GitLab failed\n");
                            obj.printPushToExistingGitLabProject(); % Assume broken response so use default URLs
                        else
                            fprintf("Created GitLab project, repository: %s\n", gitlabLink);
                            gitLabCreateTf = true;
                        end
                    end
                else
                    fprintf(2, "GitLab response did not include expected web_url or ssh_url_to_repo or http_url_to_repo fields, check GitLab project");
                    fprintf(2, "Skipping push to GitLab Project");
                    obj.printPushToExistingGitLabProject(); % Assume broken response so use default URLs
                end
            end
        end


        function url = getDefaultGitLabHTTPSURL(obj, options)
            % getDefaultGitLabHTTPSURL Create a GitLab http URL
            % By default the settings file username path is used.
            % A string is returned.

            arguments
                obj (1,1) openapi.auto.Project
                options.path string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            if isfield(obj.settings, "gitLabEndpoint") &&...
                    (ischar(obj.settings.gitLabEndpoint) || isStringScalar(obj.settings.gitLabEndpoint)) &&...
                    strlength(obj.settings.gitLabEndpoint) > 0
                endPoint = matlab.net.URI(obj.settings.gitLabEndpoint);
            else
                error("Valid gitLabEndpoint field not found in settings file");
            end
            if isfield(options, "path")
                pathFields = split(options.path, "/");
                for n = 1:numel(pathFields)
                    endPoint.Path(end+1) = pathFields(n);
                end                
            else
                if isfield(obj.settings, "gitLabUsername") &&...
                        (ischar(obj.settings.gitLabUsername) || isStringScalar(obj.settings.gitLabUsername)) &&...
                        strlength(obj.settings.gitLabUsername) > 0
                    endPoint.Path(end+1) = string(obj.settings.gitLabUsername);
                else
                    error("Valid gitLabUsername field not found in settings file");
                end
            end
            endPoint.Path(end+1) = string(obj.projectPathName + ".git");
            url = endPoint.EncodedURI;
        end


        function url = getDefaultGitLabSSHURL(obj, options)
            % getDefaultGitLabSSHURL Create a GitLab ssh URL
            % By default the settings file username path is used.
            % A string is returned.

            arguments
                obj (1,1) openapi.auto.Project
                options.path string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            if isfield(obj.settings, "gitLabEndpoint") &&...
                (ischar(obj.settings.gitLabEndpoint) || isStringScalar(obj.settings.gitLabEndpoint)) &&...
                strlength(obj.settings.gitLabEndpoint) > 0
            
                endPoint = matlab.net.URI(obj.settings.gitLabEndpoint);
                url = "git@" + string(endPoint.EncodedAuthority) + ":";
            else
                error("Valid gitLabEndpoint field not found in settings file");
            end
            if isfield(options, "path")
                url = url + options.path;
            else
                if isfield(obj.settings, "gitLabUsername") &&...
                        (ischar(obj.settings.gitLabUsername) || isStringScalar(obj.settings.gitLabUsername)) &&...
                        strlength(obj.settings.gitLabUsername) > 0
                    url = url + string(obj.settings.gitLabUsername);
                else
                    error("Valid gitLabUsername field not found in settings file");
                end
            end
            if ~endsWith(url, "/")
                url = url + "/";
            end
            url = url + obj.projectPathName + ".git";
        end


        function printPushToExistingGitLabProject(obj, options)
            % printPushToExistingGitLabProject Display project population instructions
            % Presence of a Git client is assumed.

            arguments
                obj (1,1) openapi.auto.Project
                options.sshURL string {mustBeTextScalar, mustBeNonzeroLengthText} = obj.getDefaultGitLabSSHURL
                options.httpURL string {mustBeTextScalar, mustBeNonzeroLengthText} = obj.getDefaultGitLabHTTPSURL
            end

            fprintf("To manually upload an existing local repo to a GitLab project:\n")
            fprintf("cd %s\n", obj.path);
            fprintf("git init --initial-branch=main\n");
            fprintf("# For ssh:\n");
            fprintf("git remote add origin %s\n", options.sshURL);
            fprintf("# Or for https:\n");
            fprintf("git remote add origin %s\n", options.httpURL);
            fprintf("git add .\n");
            fprintf('git commit -m "Initial commit"\n');
            fprintf("git push --set-upstream origin main\n");
        end


        function tf = createLocalGitRepo(obj)
            arguments
                obj (1,1) openapi.auto.Project
            end

            tf = false;
            obj.createGitIgnores();

            fprintf("Creating local git repository: %s\n", obj.path);
            obj.createGitIgnores();
            % Consider MATLAB's built in git init in >=24a (g3389057)
            cmd = sprintf("cd %s;   git init --initial-branch=main", obj.path);
            [status, cmdout] = system(cmd, "-echo"); %#ok<ASGLU>
            if status ~= 0
                fprintf(2, "git init failed, skipping remain repository creation steps\n");
                return;
            end

            cmd = sprintf("cd %s;  git add .", obj.path);
            [status, cmdout] = system(cmd, "-echo"); %#ok<ASGLU>
            if status ~= 0
                fprintf(2, "git add failed, skipping remain repository creation steps\n");
                return;
            end

            cmd = sprintf('cd %s;  git commit -m "Initial commit"', obj.path);
            [status, cmdout] = system(cmd, "-echo"); %#ok<ASGLU>
            if status ~= 0
                fprintf(2, "git commit failed\n");
                return;
            end
            
            tf = true;
            fprintf("Local Git repository creation complete\n");
        end


        function tf = pushToExistingGitLabProject(obj, options)
            % pushToExistingGitLabProject Push the locally created repo to a GitLab project
            % A logical true is returned if this succeeds otherwise false.

            arguments
                obj (1,1) openapi.auto.Project
                options.sshURL string {mustBeTextScalar, mustBeNonzeroLengthText} = obj.getDefaultGitLabSSHURL
                options.httpURL string {mustBeTextScalar, mustBeNonzeroLengthText} = obj.getDefaultGitLabHTTPSURL
                options.webURL string {mustBeTextScalar, mustBeNonzeroLengthText} = obj.getDefaultGitLabSSHURL
                options.useSSH (1,1) logical = true
            end
            
            tf = false;
            if ~isunix
                fprintf("Automatic upload is currently enabled on Linux and macOS\n");
                fprintf("For manual instructions see:\n");
                printPushToExistingGitLabProject(obj, sshURL=options.sshURL, httpURL=options.httpURL);
                return;
            end

            fprintf("Uploading project directory: %s to:\n    %s\n", obj.path, options.webURL);
            
            % Repo already init'd
            % % Consider MATLAB's built in git init in >=24a (g3389057)
            % cmd = sprintf("cd %s;   git init --initial-branch=main", obj.path);
            % [status, cmdout] = system(cmd, "-echo"); %#ok<ASGLU>
            % if status ~= 0
            %     fprintf(2, "git init failed, skipping upload\n");
            %     return;
            % end
            
            if options.useSSH
                cmd = sprintf("cd %s; git remote add origin %s", obj.path, options.sshURL);
            else
                cmd = sprintf("cd %s; git remote add origin %s", obj.path, options.httpURL);
            end
            [status, cmdout] = system(cmd, "-echo"); %#ok<ASGLU>
            if status ~= 0
                fprintf(2, "remote add failed, skipping upload\n");
                return;
            end

            cmd = sprintf("cd %s;  git add .", obj.path);
            [status, cmdout] = system(cmd, "-echo"); %#ok<ASGLU>
            if status ~= 0
                fprintf(2, "git add failed, skipping upload\n");
                return;
            end

            % Already committed
            % cmd = sprintf('cd %s;  git commit -m "Initial commit"', obj.path);
            % [status, cmdout] = system(cmd, "-echo"); %#ok<ASGLU>
            % if status ~= 0
            %     fprintf(2, "git commit failed, skipping upload\n");
            %     return;
            % end

            cmd = sprintf("cd %s;  git push --progress --set-upstream origin main", obj.path);
            [status, cmdout] = system(cmd);
            if status ~= 0
                fprintf(2, "git push failed\nOutput:\n%s\n", cmdout);
                return;
            end

            tf = true;
            fprintf("Upload to GitLab complete\n");
        end
        

        function addDocumentationDir(obj)
            % addDocumentationDir Creates top-level Documentation directory in the project
            arguments
                obj (1,1) openapi.auto.Project
            end

            docDir = fullfile(obj.path, "Documentation");

            if isfile(docDir)
                error("A file exists called: %s, not creating documentation directory", docDir)
            end

            if isfolder(docDir)
                fprintf("Documentation directory exists: %s, skipping creation", docDir);
            else
                [status, msg] = mkdir(docDir);
                if status ~= 1
                    error("Directory creation failed for: %s\nMessage: %s", docDir, msg);
                else
                    fprintf("Created directory: %s\n", docDir);
                end
            end
        end


        function addVersion(obj, version)
            % addVersion Adds a VERSION file at the top-level of the project

            arguments
                obj (1,1) openapi.auto.Project
                version string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            versionPath = fullfile(obj.path, "VERSION");
            [fid, errmsg] = fopen(versionPath, 'w');
            if fid == -1
                error("Unable to write VERSION file: %s, Message: %s", versionPath, errmsg);
            else
                fprintf("Setting version to: %s\n", version);
                fprintf(fid, "%s\n", version);
                fclose(fid);
            end
        end


        function client = createClient(obj, options)
            % createClient Creates and configures an openapi.build.Client object
            arguments
                obj (1,1) openapi.auto.Project
                options.additionalClientArguments cell
            end

            client = openapi.build.Client();

            client.packageName = obj.projectNamespace;

            client.inputSpec = obj.localSpec;

            client.output = fullfile(obj.path, "Software", "MATLAB", "app", "system");

            if isfield(options, "additionalClientArguments")
                client.additionalArguments = options.additionalClientArguments;
            end

            if isfield(obj.settings, "copyrightNotice")
                client.copyrightNotice = sprintf("%% (c) %d %s", year(datetime("now")), obj.settings.copyrightNotice);
            end
        end


        function tf = buildClient(obj, client)
            % buildClient Invokes build on a openapi.build.Client

            arguments
                obj (1,1) openapi.auto.Project %#ok<INUSA>
                client (1,1) openapi.build.Client
            end

            try
                client.build();
                tf = true;
            catch ME
                fprintf(2,"Error building client, message: %s", ME.message)
                tf = false;
            end
        end


        function copyBaseLineFiles(obj, additionalFiles)
            % copyBaseLineFiles Copies in non-generated fixture/boilerplate files

            arguments
                obj (1,1) openapi.auto.Project
                additionalFiles string
            end

            if ~isempty(additionalFiles)
                for n = 1:numel(additionalFiles)
                    if isfile(additionalFiles(n)) || isfolder(additionalFiles(n))
                        [status, msg] = copyfile(additionalFiles(n), obj.path);
                        if status ~= 1
                            error("copyfile failed for: %s to %s\nMessage: %s", additionalFiles(n), obj.path, msg);
                        else
                            fprintf("Copied: %s to: %s\n", additionalFiles(n), obj.path);
                        end
                    else
                        fprintf(2, "Baseline file not found: %s, skipping\n", additionalFiles(n));
                    end
                end
            end

            if isfield(obj.settings, "baselineFiles")
                if ~isempty(obj.settings.baselineFiles)
                    for n = 1:numel(obj.settings.baselineFiles)
                        if isfile(obj.settings.baselineFiles{n}) || isfolder(obj.settings.baselineFiles{n})
                            [status, msg] = copyfile(obj.settings.baselineFiles{n}, obj.path);
                            if status ~= 1
                                error("copyfile failed for: %s to %s\nMessage: %s", obj.settings.baselineFiles{n}, obj.path, msg);
                            else
                                fprintf("Copied: %s to: %s\n", obj.settings.baselineFiles{n}, obj.path);
                            end
                        else
                            fprintf(2, "Baseline file not found: %s, skipping\n", obj.settings.baselineFiles{n});
                        end
                    end
                end
            end
        end


        function localSpec = getLocalSpec(obj, inputSpec)
            % getLocalSpec Copies the spec into the project

            arguments
                obj (1,1) openapi.auto.Project
                inputSpec string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            % Create OpenAPI directory
            openAPIDir = fullfile(obj.path, "OpenAPI");
            [status, msg] = mkdir(openAPIDir);
            if status ~= 1
                error("Directory creation failed for: %s\nMessage: %s", openAPIDir, msg);
            else
                fprintf("Created directory: %s\n", openAPIDir);
            end

            if startsWith(inputSpec, "http")
                specURL = matlab.net.URI(inputSpec);
                filename = specURL.Path(end);
                if ~(endsWith(lower(filename), ".json") || endsWith(lower(filename), ".yaml"))
                    fprintf(2, "Warning, spec file not of type .json or .yaml: %s", specURL.EncodedURI);
                end
                localSpec = fullfile(openAPIDir, filename);
                websave(localSpec, inputSpec);
            else
                [~, n, e] = fileparts(inputSpec);
                localSpec = fullfile(openAPIDir, n+e);
                [status, msg] = copyfile(inputSpec, openAPIDir);
                if status ~= 1
                    error("copyfile failed for: %s to %s\nMessage: %s", inputSpec, openAPIDir, msg);
                else
                    [dirName, fName, ext] = fileparts(inputSpec); %#ok<ASGLU>
                    obj.localSpec = fullfile(openAPIDir, fName+ext);
                end
            end
            obj.localSpec = localSpec;
        end


        function path = createPath(obj, useExistingDirectory, options)
            % createPath Creates project directory for the local files

            arguments
                obj (1,1) openapi.auto.Project
                useExistingDirectory (1,1) logical
                options.outputDirectory string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            if isfield(options, "outputDirectory")
                path = fullfile(options.outputDirectory, obj.projectPathName);
            else
                if ~isfield(obj.settings, "projectBaseDirectory")
                    error("settings.projectBaseDirectory field is not set");
                end
                path = fullfile(obj.settings.projectBaseDirectory, obj.projectPathName);
            end
            fprintf("Setting path to: %s\n", path);

            if isfolder(path) || isfile(path)
                if useExistingDirectory
                    fprintf(2, "Using existing directory: %s\n", path);
                else
                    error("Directory already exists: %s", path);
                end
            else
                [status,msg] = mkdir(obj.settings.projectBaseDirectory, obj.projectPathName);
                if status ~= 1
                    error("Directory creation failed for: %s\nMessage: %s", path, msg);
                else
                    fprintf("Created directory: %s\n", fullfile(obj.settings.projectBaseDirectory, obj.projectPathName));
                end
            end
            obj.path = path;
        end


        function readSettings(obj, settingsFile)
            % readSettings Reads the settings json file
            arguments
                obj (1,1) openapi.auto.Project
                settingsFile string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            if isfile(settingsFile)
                obj.settings = jsondecode(fileread(settingsFile));
            else
                error("Settings file not found: %s", settingsFile);
            end

            % Content checks
            if ~isfield(obj.settings, "projectBaseDirectory") || ...
                    ~(isStringScalar(obj.settings.projectBaseDirectory) || ischar(obj.settings.projectBaseDirectory)) || ...
                    strlength(obj.settings.projectBaseDirectory) == 0
                error("Missing or invalid projectBaseDirectory field in: %s", settingsFile);
            end
        end


        function addReadme(obj)
            % addReadme Adds a top-level README.md file
            arguments
                obj (1,1) openapi.auto.Project
            end

            readmePath = fullfile(obj.path, "README.md");

            if isfile(readmePath)
                fprintf(2, "README.md found, overwriting: %s\n", readmePath);
            end

            [fid, errmsg] = fopen(readmePath, 'w');
            if fid == -1
                error("Unable to write README.md file: %s, Message: %s", readmePath, errmsg);
            else
                fprintf("Writing top level README.md\n");
                fprintf(fid, "# %s\n\n", obj.projectFullName);
                fprintf(fid, "## Requirements\n\n");
                fprintf(fid, "* MATLAB R2020b or later\n\n");
                fprintf(fid, "## Introduction\n\n");
                fprintf(fid, "## Documentation\n\n");
                fprintf(fid, "Please see the `Documentation` directory for more information\n\n");

                baseClientObjectPath = join(["Software", "MATLAB", "app", "system", "+" + obj.projectNamespace, "BaseClient.m"], "/");
                fprintf(fid, "> The BaseClient object `%s` is likely to require customization to enable authentication support.\n\n", baseClientObjectPath);
                if isfield(obj.settings, "copyrightNotice")
                    fprintf(fid, "\n[//]: #  (Copyright %d %s)\n", year(datetime("now")), obj.settings.copyrightNotice);
                end
                fclose(fid);
            end
        end


        function addReleasenotes(obj, version)
            % addReleasenotes Adds a top-level RELEASENOTES.md file with an initial entry
            
            arguments
                obj (1,1) openapi.auto.Project
                version string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            rnPath = fullfile(obj.path, "RELEASENOTES.md");

            if isfile(rnPath)
                fprintf(2, "RELEASENOTES.md found, overwriting: %s\n", rnPath);
            end

            [fid, errmsg] = fopen(rnPath, 'w');
            if fid == -1
                error("Unable to write RELEASENOTES.md file: %s, Message: %s", rnPath, errmsg);
            else
                fprintf("Writing RELEASENOTES.md\n");
                fprintf(fid, "# %s\n\n", obj.projectFullName);
                fprintf(fid, "## Version %s (%s)\n\n", version, datetime("today"));
                fprintf(fid, "* Initial version created using the MATLAB Generator *for OpenAPI*\n\n");
                if isfield(obj.settings, "copyrightNotice")
                    fprintf(fid, "[//]: #  (Copyright %s %s)\n", year(datetime("now")), obj.settings.copyrightNotice);
                end
                fclose(fid);
            end
        end
    end
end