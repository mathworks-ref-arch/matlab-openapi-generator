classdef Client < openapi.build.Object
    % Client object to assist in building a MATLAB Client

    %  (c) 2021-2023 MathWorks, Inc.

    properties
        packageName string
        jarPath string
        inputSpec string
        output string
        additionalArguments string
        templateDir string
        globalProperty % containers.Map
        openapiRoot string
        copyrightNotice string
        additionalProperties % containers.Map
        useConfigurationFile (1,1) logical
        configurationFile string
        nodePath string
        npxPath string
        skipValidateSpec (1,1) logical
    end

    properties (Hidden)
        logFid = 0
        cliVersion = "6.6.0"
    end

    methods
        function obj = Client(options)
            arguments
                options.inputSpec string {mustBeTextScalar}
                options.jarPath string {mustBeTextScalar} = openapiRoot(-1, 'MATLAB', 'lib', 'jar', 'MATLABClientCodegen-openapi-generator-0.0.1.jar')
                options.templateDir string {mustBeTextScalar} = openapiRoot(-1, 'Mustache')
                options.packageName string {mustBeTextScalar} = 'OpenAPIClient'
                options.output string {mustBeTextScalar} = fullfile(pwd, 'OpenAPIClient')
                options.additionalArguments string {mustBeTextScalar}
                options.globalProperty containers.Map
                options.openapiRoot = openapiRoot
                options.copyrightNotice string {mustBeTextScalar}
                options.additionalProperties containers.Map
                options.useConfigurationFile (1,1) logical = true
                options.configurationFile string {mustBeTextScalar} = 'openapitools.json'
                options.nodePath string {mustBeTextScalar}
                options.npxPath string {mustBeTextScalar}
                options.skipValidateSpec (1,1) logical = true
            end

            for p = string(fieldnames(options))'
                obj.(p) = options.(p);
            end

            if isempty(obj.additionalProperties) && isa(obj.additionalProperties, 'double')
                obj.additionalProperties = containers.Map();
            end
            if ~isa(obj.additionalProperties, 'containers.Map')
                error('Client:Client', 'Expected additionalProperties property to be a containers.Map, not: %s', class(obj.additionalProperties));
            end

            if isempty(obj.globalProperty) && isa(obj.globalProperty, 'double')
                obj.globalProperty = containers.Map();
            end
            if ~isa(obj.globalProperty, 'containers.Map')
                error('Client:Client', 'Expected globalProperty property to be a containers.Map, not: %s', class(obj.globalProperty));
            end
        end


        function obj = build(obj)
            arguments
                obj (1,1) openapi.build.Client
            end

            cleanup = onCleanup(@()logClose(obj));

            obj.log(sprintf('OpenAPI Client Generator: %s',datetime('now')));

            % check for MATLAB version, jar file, npx, node
            if ~obj.checkDeps
                errMsg = sprintf('Dependency check failed review warnings\nCheck if java and javac (>= v11) paths are configured and if npxPath or nodePath client properties need to be set explicitly.');
                obj.log(errMsg);
                error('Client:build', errMsg); %#ok<SPERR>
            end

            % Must be called before any calls to the CLI
            configCLI(obj);

            if ~strlength(obj.inputSpec) > 0
                obj.log('inputSpec property is required but not set');
                error('Client:build:specNotSet','inputSpec property is required but not set');
            end

            if obj.useConfigurationFile
                obj.dispLog(sprintf('Using configuration file: %s', obj.configurationFile));
                obj.buildAdditionalPropertiesFileEntry();
                obj.writeConfigurationFile();
                if ~isfile(obj.configurationFile)
                    errMsg = sprintf('Configuration file not found: %s', obj.configurationFile);
                    obj.log(errMsg);
                    error('Client:build:FileNotFound', errMsg); %#ok<SPERR>
                else
                    cmdStr = obj.createFileCmdString();
                end
            else
                cmdStr = obj.createCLICmdString();
            end

            obj.dispLog(['Building client, executing command:', newline, char(cmdStr), newline]);

            [cmdStatus, cmdOut, cmdStrExec] = obj.wrappedSystem(cmdStr);

            obj.log(sprintf('Prefixed command: %s\n', cmdStrExec));
            obj.log(sprintf('Command result: %d\n', cmdStatus));
            obj.log(sprintf('Command output:\n%s\n', cmdOut));

            if cmdStatus ~= 0
                error('Client:build', 'Build failed: \n%s\nLog: %s', cmdOut, fullfile(obj.output, obj.packageName + "_build.log"));
            else
                obj.dispLog(sprintf('Build completed, output directory: %s', obj.output));
            end
        end


        function [tf, reportOut] = verifyPackage(obj, options)
            % verifyPackage Simple wrapper to populate the output path automatically
            arguments
                obj (1,1) openapi.build.Client
                options.mode string {mustBeTextScalar, mustBeMember(options.mode,{'nonStrict','strict'})} = 'nonStrict'
                options.ignoredChecks string = ""
            end

            [tf, reportOut] = openapi.verifyPackage(obj.output, 'mode', options.mode, 'ignoredChecks', options.ignoredChecks);
        end

        
        function set.templateDir(obj, templateDir)
            arguments
                obj (1,1) openapi.build.Client
                templateDir string {mustBeTextScalar}
            end

            if ~isfolder(templateDir)
                error('Client:set_templateDir', 'Mustache/template directory not found: %s', templateDir);
            else
                obj.templateDir = templateDir;
            end
        end


        function set.output(obj, output)
            arguments
                obj (1,1) openapi.build.Client
                output string {mustBeTextScalar}
            end

            if isfile(output)
                error('Client:set_output','A file already exists: %s', output);
            elseif isfolder(output)
                % TODO consider warning re default value
                % fprintf('Output directory already exists and will be overwritten: %s\n', output);
                obj.output = output;
            else
                obj.output = output;
            end
        end


        function set.inputSpec(obj, inputSpec)
            arguments
                obj (1,1) openapi.build.Client
                inputSpec string {mustBeTextScalar}
            end

            if ~startsWith(inputSpec, "http", 'IgnoreCase', true)
                if ~isfile(inputSpec)
                    error('Client:set_inputSpec','OpenAPI Spec file not found: %s', inputSpec);
                else
                    obj.inputSpec = inputSpec;
                end
            else
                obj.inputSpec = inputSpec;
            end
        end


        function set.jarPath(obj, jarPath)
            arguments
                obj (1,1) openapi.build.Client
                jarPath string {mustBeTextScalar}
            end

            if ~isfile(jarPath)
                error('Client:set_jarPath','OpenAPI generator Jar file not found: %s, to build it run "mvn clean package" in a shell from Software/Java', jarPath);
            else
                obj.jarPath = jarPath;
            end
        end


        function set.nodePath(obj, nodePath)
            arguments
                obj (1,1) openapi.build.Client
                nodePath string {mustBeTextScalar}
            end
            if ispc()
                warning('Client:set_nodePath','Setting the nodePath value currently has no effect on Windows systems');
            else
                if ~isfolder(nodePath)
                    error('Client:set_npxPath','npxPath directory not found: %s', nodePath);
                end
            end
            obj.nodePath = nodePath;
        end


        function set.npxPath(obj, npxPath)
            arguments
                obj (1,1) openapi.build.Client
                npxPath string {mustBeTextScalar}
            end
            if ispc()
                warning('Client:set_npxPath','Setting the npxPath value currently has no effect on Windows systems');
            else
                if ~isfolder(npxPath)
                    error('Client:set_npxPath','npxPath directory not found: %s', npxPath);
                end
            end
            obj.npxPath = npxPath;
        end


        function set.additionalArguments(obj, additionalArguments)
            arguments
                obj (1,1) openapi.build.Client
                additionalArguments string {mustBeTextScalar}
            end

            obj.additionalArguments = additionalArguments;
        end


        function set.copyrightNotice(obj, copyrightNotice)
            arguments
                obj (1,1) openapi.build.Client
                copyrightNotice string {mustBeTextScalar}
            end

            if ~startsWith(copyrightNotice, whitespacePattern + "%")
                copyrightNotice = "% " + copyrightNotice;
            end
            obj.copyrightNotice = copyrightNotice;
        end


        function set.globalProperty(obj, globalProperty)
            arguments
                obj (1,1) openapi.build.Client
                globalProperty containers.Map
            end

            obj.globalProperty = globalProperty;
        end


        function set.additionalProperties(obj, additionalProperties)
            arguments
                obj (1,1) openapi.build.Client
                additionalProperties containers.Map
            end

            obj.additionalProperties = additionalProperties;
        end


        function tf = checkDeps(obj)
            mlTf = obj.checkMATLABVersion();
            jarTf = obj.checkJar();
            nodeTf = obj.checkNode();
            npxTf = obj.checkNpx();
            javaTf = obj.checkJavaVersion();
            javacTf = obj.checkJavacVersion();

            tf = all([mlTf, jarTf, nodeTf, npxTf, javaTf, javacTf]);
        end
    end


    methods (Access = protected, Hidden)
        function obj = log(obj, text)
            arguments
                obj (1,1) openapi.build.Client
                text (1,:) string {mustBeTextScalar}
            end

            if obj.logFid == 0
                logPath = fullfile(obj.output, obj.packageName + "_build.log");
                if ~isfolder(obj.output)
                    if isfile(obj.output)
                        error('Client:log', 'Output directory is a file: %s', obj.output);
                    end
                    mkdir(obj.output);
                    % Assumes subsequent client generation will not delete/overwrite the log file
                end
                [fid, errmsg] = fopen(logPath, 'wt+');
                if fid < 3
                    error('Client:log', 'Error opening log file: %s\n%s', logPath, errmsg);
                else
                    obj.logFid = fid;
                    fprintf(obj.logFid, '%s\n', text);
                end
            elseif obj.logFid < 3
                error('Client:log', 'Error invalid log file id: %d', obj.logFid);
            else
                fprintf(obj.logFid, '%s\n', text);
            end
        end


        function logClose(obj)
            arguments
                obj (1,1) openapi.build.Client
            end

            if obj.logFid > 2
                fclose(obj.logFid);
            end
            obj.logFid = 0;
        end


        function tf = isCLIInstalled(obj)
            npmCmdStr = createNpmCmdString(obj);
            cmdStr = npmCmdStr + " list --depth 1 @openapitools/openapi-generator-cli"; % TODO add version constraints
            [cmdStatus, ~, ~] = openapi.build.Client.wrappedSystem(cmdStr);

            if cmdStatus == 0
                tf = true;
            else
                tf = false;
            end
        end


        function configCLI(obj, options)
            % configCLI Installs
            arguments
                obj (1,1) openapi.build.Client
                options.cliVersion string {mustBeTextScalar} = obj.cliVersion
            end

            if ~isCLIInstalled(obj)
                npmCmdStr = obj.createNpmCmdString;
                cmdStr = npmCmdStr + " install @openapitools/openapi-generator-cli"; % TODO add version constraints
                obj.dispLog(['Installing CLI, executing command:', newline, char(cmdStr), newline]);
                [cmdStatus, cmdOut, cmdStrExec] = openapi.build.Client.wrappedSystem(cmdStr);
                if cmdStatus ~= 0
                    error('Client:configCLI', 'Could not install openapi-generator-cli:\nExecuted: %s\nReturned: %s\n', cmdStrExec, cmdOut);
                end
            end
            cliVer = obj.getGeneratorCliVersion;
            if ~strcmp(cliVer, options.cliVersion)
                npxCmdStr = obj.createNpxCmdString;
                cmdStr = npxCmdStr + " @openapitools/openapi-generator-cli version-manager set " + options.cliVersion; % Current supported version
                obj.dispLog(['Setting CLI version, executing command:', newline, char(cmdStr), newline]);
                [cmdStatus, cmdOut, cmdStrExec] = openapi.build.Client.wrappedSystem(cmdStr);
                if cmdStatus ~= 0
                    error('Client:configCLI', 'Could not set openapi-generator-cli version:\nExecuted: %s\nReturned: %s\n', cmdStrExec, cmdOut);
                end
            end
        end


        function dispLog(obj, str)
            % Displays a string and also logs it
            arguments
                obj (1,1) openapi.build.Client
                str string {mustBeTextScalar}
            end

            disp(str);
            obj.log(str);
        end


        function npmCmdStr = createNpmCmdString(obj)
            if strlength(obj.nodePath) > 0
                pathCmd = "export PATH=" + string(obj.nodePath) + ":$PATH; ";
            else
                pathCmd = "";
            end
            npmCmdStr = pathCmd + "npm ";
        end


        function npxCmdStr = createNpxCmdString(obj)
            if strlength(obj.nodePath) > 0
                pathCmd = "export PATH=" + string(obj.nodePath) + ":$PATH; ";
            else
                pathCmd = "";
            end
            if strlength(obj.npxPath) > 0
                npxCmd = string(fullfile(obj.npxPath, 'npx'));
            else
                npxCmd = "npx "; % Note trailing space
            end
            npxCmdStr = pathCmd + npxCmd;
        end


        function cmdStr = createFileCmdString(obj)
            npxCmdStr = obj.createNpxCmdString;
            cmdStr = npxCmdStr + " @openapitools/openapi-generator-cli";
            cmdStr = cmdStr + " generate --generator-key v3.0";
            cmdStr = cmdStr + " --custom-generator " + '"' + obj.jarPath + '"';
            cmdStr = cmdStr + " --config " + '"' + obj.configurationFile + '"';

            if strlength(obj.additionalArguments) > 0
                cmdStr = cmdStr + " " + obj.additionalArguments;
            end
        end


        function cmdStr = createCLICmdString(obj)
            npxCmdStr = obj.createNpxCmdString;
            cmdStr = npxCmdStr + " @openapitools/openapi-generator-cli";
            cmdStr = cmdStr + " --custom-generator " + '"' + obj.jarPath + '"';
            cmdStr = cmdStr + " generate -g MATLAB";
            cmdStr = cmdStr + " -i " + '"' + obj.inputSpec + '"';
            cmdStr = cmdStr + " -o " + '"' + obj.output + '"';
            cmdStr = cmdStr + " --package-name " + obj.packageName;
            cmdStr = cmdStr + " -t " + '"' + obj.templateDir + '"';
            cmdStr = cmdStr + obj.buildAdditionalPropertiesCLIEntry();

            if obj.skipValidateSpec
                cmdStr = cmdStr + " --skip-validate-spec";
            end

            cmdStr = cmdStr + obj.buildGlobalPropertiesCLIEntry();

            if strlength(obj.additionalArguments) > 0
                cmdStr = cmdStr + " " + obj.additionalArguments;
            end
        end


        function arg = buildAdditionalPropertiesCLIEntry(obj)
            arguments
                obj (1,1) openapi.build.Client
            end

            crStr = obj.copyrightNotice;

            if strlength(crStr) > 0
                % CLI escaping
                crStr = strrep(crStr, "'", "");
                crStr = strrep(crStr, '"', '');
                % Some additional escaping required on Unix, where npx argument
                % handling is inconsistent and poorly documented for cross
                % platform use
                if isunix
                    crStr = strrep(crStr, ' ', '\ ');
                    crStr = strrep(crStr, '(', '\(');
                    crStr = strrep(crStr, ')', '\)');
                end

                if ispc
                    obj.additionalProperties('copyrightNotice') = ['\"', char(crStr), '\"'];
                else
                    obj.additionalProperties('copyrightNotice') = ['"', char(crStr), '"'];
                end
            end

            if strlength(obj.openapiRoot) > 0
                obj.additionalProperties('openapiRoot') = ['"', char(obj.openapiRoot), '"'];
            end

            numProps = size(obj.additionalProperties,1);
            if numProps > 0
                apKeys = keys(obj.additionalProperties);
                apVals = values(obj.additionalProperties);
                arg = ' --additional-properties=';
                for n = 1:numProps
                    arg = [arg, char(apKeys{n}), '=', char(apVals{n})]; %#ok<AGROW>
                    if n < numProps
                        arg = [arg, ',']; %#ok<AGROW>
                    end
                end
            else
                arg = '';
            end
        end


        function buildAdditionalPropertiesFileEntry(obj)
            arguments
                obj (1,1) openapi.build.Client
            end

            if strlength(obj.copyrightNotice) > 0
                obj.additionalProperties('copyrightNotice') = char(obj.copyrightNotice);
            end
            if strlength(obj.openapiRoot) > 0
                obj.additionalProperties('openapiRoot') = char(obj.openapiRoot);
            end
        end


        function arg = buildGlobalPropertiesCLIEntry(obj)
            arguments
                obj (1,1) openapi.build.Client
            end

            numProps = size(obj.globalProperty,1);
            if numProps > 0
                gpKeys = keys(obj.globalProperty);
                gpVals = values(obj.globalProperty);
                arg = ' --global-property=';
                for n = 1:numProps
                    if ischar(gpVals{n}) || isStringScalar(gpVals{n})
                        if strlength(gpVals{n}) == 0
                            arg = [arg, char(gpKeys{n})]; %#ok<AGROW>
                        else
                            arg = [arg, char(gpKeys{n}), '=', char(gpVals{n})]; %#ok<AGROW>
                        end
                    else
                        % Cast to char will fail for certain types but allow it for now
                        % in general expecting a string/char
                        arg = [arg, char(gpKeys{n}), '=', char(gpVals{n})]; %#ok<AGROW>
                    end
                    if n < numProps
                        arg = [arg, ',']; %#ok<AGROW>
                    end
                end
            else
                arg = '';
            end
        end


        function tf = checkMATLABVersion(~)
            if verLessThan('MATLAB', '9.9')
                warning('Client:checkMATLABVersion','MATLAB R2020b or later is required');
                tf = false;
            else
                tf = true;
            end
        end


        function tf = checkNpx(obj)
            % Function to check if npx is installed
            % Unset LD_LIBRARY_PATH in the system context to avoid
            % potential glibc issue
            tf = false;

            % Set $PATH so other tools pick up path
            if isunix
                if strlength(obj.npxPath) > 0
                    pathCmd = ['export PATH="', char(obj.npxPath), ':$PATH"; '];
                else
                    pathCmd = '';
                end
            else
                pathCmd = '';
            end

            % Append the executable to the directory
            if strlength(obj.npxPath) > 0
                npxCmd = char(fullfile(obj.npxPath, 'npx'));
                if ~isfile(npxCmd)
                    error('Client:checkNpx','npx command not found: %s', npxCmd)
                end
            else
                npxCmd = 'npx';
            end

            % Build the command to pass to system wrapper
            cmdStr = [pathCmd, npxCmd, ' --version'];

            [cmdStatus, cmdOut, cmdStrExec] = openapi.build.Client.wrappedSystem(cmdStr);

            if cmdStatus ~= 0
                warning('Client:checkNpx','npx is required required\nExecuted: %s\nReturned: %s\nSee: https://github.com/npm/cli\n', cmdStrExec, cmdOut);
            else
                pat = digitsPattern + "." + digitsPattern + "." + digitsPattern;
                if ~matches(strtrim(cmdOut), pat, 'IgnoreCase', true)
                    warning('Client:checkNpx','Unexpected npx version output: %s', cmdOut);
                else
                    fields = split(strtrim(cmdOut), ".");
                    firstVal = str2double(fields{1});
                    secondVal = str2double(fields{2});
                    thirdVal = str2double(fields{3});
                    firstCutOff = 8; % 8.12.1
                    secondCutOff = 12;
                    thirdCutOff = 1;
                    if firstVal < firstCutOff
                        comp = -1;
                    elseif firstVal == firstCutOff
                        comp = 0;
                    else
                        comp = 1;
                    end
                    if comp == 0
                        if secondVal < secondCutOff
                            comp = -1;
                        elseif secondVal == secondCutOff
                            comp = 0;
                        else
                            comp = 1;
                        end
                    end
                    if comp == 0
                        if thirdVal < thirdCutOff
                            comp = -1;
                        elseif thirdVal == thirdCutOff
                            comp = 0;
                        else
                            comp = 1;
                        end
                    end
                    if comp < 0
                        tf = false;
                        warning('Client:checkNode','npx version 8.12.1 or later is required, found:\n%s\nSee: https://github.com/npm/cli\n', cmdOut);
                    else
                        tf = true;
                    end
                end
            end
        end


        function tf = checkNode(obj)
            % Function to check if node version >= v16.x is installed
            tf = false;

            % Set $PATH so other tools pick up path
            if isunix
                if strlength(obj.nodePath) > 0
                    pathCmd = ['export PATH="', char(obj.nodePath), ':$PATH"; '];
                else
                    pathCmd = '';
                end
            else
                pathCmd = '';
            end

            % Append the executable to the directory
            if strlength(obj.nodePath) > 0
                nodeCmd = char(fullfile(obj.nodePath, 'node'));
                if ~isfile(nodeCmd)
                    error('Client:checkNode','npx command not found: %s', nodeCmd)
                end
            else
                nodeCmd = 'node';
            end

            % Build the command to pass to system wrapper
            cmdStr = [pathCmd, nodeCmd, ' --version'];

            [cmdStatus, cmdOut, cmdStrExec] = openapi.build.Client.wrappedSystem(cmdStr);
            if cmdStatus ~= 0
                warning('Client:checkNode','node version 16 or later is required\nExecuted: %s\nReturned: %s\nSee: https://nodejs.org/en\n', cmdStrExec, cmdOut);
            else
                pat = "v" + digitsPattern + "." + digitsPattern + "." + digitsPattern;
                if ~matches(strtrim(cmdOut), pat, 'IgnoreCase', true)
                    warning('Client:checkNode','Unexpected node version output: %s', cmdOut);
                else
                    cmdOutNew = strip(strtrim(cmdOut), 'left', 'v');
                    fields = split(cmdOutNew, ".");
                    majorVal = str2double(fields{1});
                    if majorVal < 16
                        warning('Client:checkNode','node version 16 or later is required:\n%s\nSee: https://nodejs.org/en\n', cmdOut);
                    else
                        tf = true;
                    end
                end
            end
        end


        function tf = writeConfigurationFile(obj)
            if strlength(obj.configurationFile) < 1
                error('Client:writeConfigurationFile','Configuration file path not set');
            end
            fid = fopen(obj.configurationFile, 'w');
            if fid < 3
                error('Client:writeConfigurationFile','Error opening configuration file: %s', obj.configurationFile);
            end

            l1 = struct;
            l1.schema = "./node_modules/@openapitools/openapi-generator-cli/config.schema.json";
            l1.spaces = 2;
            l1.generator_cli.version = obj.cliVersion;
            l1.generator_cli.generators.v30.generatorName = "MATLAB";
            l1.generator_cli.generators.v30.output = obj.output;
            l1.generator_cli.generators.v30.inputSpec = obj.inputSpec;
            l1.generator_cli.generators.v30.packageName = obj.packageName;
            l1.generator_cli.generators.v30.skipValidateSpec = obj.skipValidateSpec;
            l1.generator_cli.generators.v30.templateDir = obj.templateDir;

            numProps = size(obj.additionalProperties,1);
            if numProps > 0
                apKeys = keys(obj.additionalProperties);
                apVals = values(obj.additionalProperties);
                for n = 1:size(obj.additionalProperties,1)
                    if ~isvarname(apKeys{n})
                        error('Client:writeConfigurationFile','Unexpected invalid additionalProperties key: %s, consider adding an exception', apKeys{n});
                    end
                    if ischar(apVals{n}) || isStringScalar(apVals{n})
                        if strcmp(apVals{n}, "''") || strcmp(apVals{n}, '""')
                            % Avoid getting a JSON value of """" or "''"
                            l1.generator_cli.generators.v30.additionalProperties.(apKeys{n}) = "";
                        else
                            l1.generator_cli.generators.v30.additionalProperties.(apKeys{n}) = apVals{n};
                        end
                    else
                        l1.generator_cli.generators.v30.additionalProperties.(apKeys{n}) = apVals{n};
                    end
                end
            end

            numProps = size(obj.globalProperty,1);
            if numProps > 0
                gpKeys = keys(obj.globalProperty);
                gpVals = values(obj.globalProperty);
                for n = 1:size(obj.globalProperty,1)
                    if ~isvarname(gpKeys{n})
                        error('Client:writeConfigurationFile','Unexpected invalid global-property key: %s, consider adding an exception', gpKeys{n});
                    end
                    if ischar(gpVals{n}) || isStringScalar(gpVals{n})
                        if strcmp(gpVals{n}, "''") || strcmp(gpVals{n}, '""')
                            % Avoid getting a JSON value of """" or "''"
                            l1.generator_cli.generators.v30.global_property.(gpKeys{n}) = "";
                        else
                            l1.generator_cli.generators.v30.global_property.(gpKeys{n}) = gpVals{n};
                        end
                    else
                        l1.generator_cli.generators.v30.global_property.(gpKeys{n}) = apVals{n};
                    end
                end
            end

            jsonStr = jsonencode(l1, 'PrettyPrint', true);
            % Tweak the json
            jsonStr = strrep(jsonStr, '"generator_cli"', '"generator-cli"');
            jsonStr = strrep(jsonStr, '"schema"', '"$schema"');
            jsonStr = strrep(jsonStr, '"v30"', '"v3.0"');
            jsonStr = strrep(jsonStr, '"global_property"', '"global-property"');

            dispLog(obj, "Writing configuration file: " + obj.configurationFile);
            dispLog(obj, jsonStr);

            fprintf(fid, "%s", jsonStr);
            fclose(fid);
            tf = true;
        end


        function cliVer = getGeneratorCliVersion(obj)
            npxCmdStr = obj.createNpxCmdString;
            cmdStr = npxCmdStr + " @openapitools/openapi-generator-cli version";
            obj.dispLog(['Getting CLI version, executing command:', newline, char(cmdStr), newline]);
            [cmdStatus, cmdOut, cmdStrExec] = obj.wrappedSystem(cmdStr); %#ok<ASGLU>

            if cmdStatus ~= 0
                error('Client:getGeneratorCliVersion', 'Error getting CLI version: \n%s\n', cmdOut);
            else
                lines = split(cmdOut, newline);
                if numel(lines) == 1
                    cliVer = lines{1};
                elseif numel(lines) > 1
                    cliVer = lines{end-1};
                else
                    error('Client:getGeneratorCliVersion', 'Error getting CLI version: \n%s\n', cmdOut);
                end

                cliVer = strip(cliVer);
                pat = digitsPattern + "." + digitsPattern + "." + digitsPattern;
                if ~matches(cliVer, pat)
                    error('Client:getGeneratorCliVersion', 'Error getting CLI version: \n%s\n', cmdOut);
                end
            end
        end
    end


    methods (Static, Hidden)

        function [status, cmdOut, cmdStr] = wrappedSystem(cmdStr)
            % Wrap a system call in steps to improve reliability of call 3rd party packages
            % Unset LD_LIBRARY_PATH in the system context to avoid potential glibc issue
            % On macOS prepend /usr/local/bin in $PATH

            arguments
                cmdStr string {mustBeTextScalar}
            end

            % Assume char type from here
            cmdStr = char(cmdStr);

            if ispc
                [status, cmdOut] = system(cmdStr);
            elseif ismac
                % prepend default npx location on macOS
                [status, cmdOut] = system(['export PATH="/usr/local/bin:$PATH"; ', cmdStr]);
            else
                [status, cmdOut] = system(['export LD_LIBRARY_PATH=""; ', cmdStr]);
            end
        end


        function tf = checkJar(obj) %#ok<INUSD>
            % checkJar Checks for the presence to the required jar file

            jarName = "MATLABClientCodegen-openapi-generator-" + openapi.build.Client.getJarVersion() + ".jar";
            jarPath = fullfile(openapiRoot('lib', 'jar'), jarName);
            if ~isfile(jarPath)
                docPath = fullfile(openapiRoot( -2, 'Documentation', 'GettingStarted.md'));
                warning('Client:checkJar','Required jar file not found: %s\nFor build instructions see: %s', jarPath, docPath);
                tf = false;
            else
                tf = true;
            end
        end


        function v = getJarVersion()
            % getJarVersion Retrieve version from pom-file

            pomFile = fullfile(openapiRoot( -1, 'Java'), 'pom.xml');
            if ~isfile(pomFile)
                error('Client:getJarVersion','Expected pom file not found: %s',pomFile);
            end
            X = xmlread(pomFile);
            projNode = X.getElementsByTagName('project').item(0);
            versionElement = projNode.getElementsByTagName('version').item(0);
            templateVersion = versionElement.getTextContent();

            v = string(templateVersion);
        end


        function tf = checkJavaVersion()
            % checkJavaVersion returns true if Java 11 or greater is detected
            % TODO implement an upper bound
            cmdStr = "java -version";
            [status, cmdOut] = system(cmdStr);
            if status == 0
                lines = split(cmdOut, newline);
                if numel(lines) > 0
                    pat = digitsPattern + "." + digitsPattern + ".";
                    newStr = extract(lines{1}, pat);
                    fields = split(newStr, '.');
                    if numel(fields) >= 2
                        if str2double(fields{1}) >= 11 % Not clear what upper bound is TBD
                            tf = true;
                        else
                            warning('Client:checkJavaVersion','Java 11 or compatible is required, found: %s', lines{1});
                            tf = false;
                        end
                    else
                        warning('Client:checkJavaVersion','Java version could not be determined: %s', lines{1});
                        tf = false;
                    end
                else
                    warning('Client:checkJavaVersion','Java version could not be determined: %s', cmdOut);
                    tf = false;
                end
            else
                warning('Client:checkJavaVersion','Java version could not be determined, error running java -version: %s',cmdOut);
                tf = false;
            end
        end

        function tf = checkJavacVersion()
            % checkJavacVersion returns true if Javac 11 or greater is detected
            % TODO implement an upper bound
            cmdStr = "javac -version";
            [status, cmdOut] = system(cmdStr);
            if status == 0
                pat = digitsPattern + "." + digitsPattern + ".";
                newStr = extract(cmdOut, pat);
                fields = split(newStr, '.');
                if numel(fields) >= 2
                    if str2double(fields{1}) >= 11 % Not clear what upper bound is TBD
                        tf = true;
                    else
                        warning('Client:checkJavacVersion','Javac 11 or compatible is required, found: %s', cmdout);
                        tf = false;
                    end
                else
                    warning('Client:checkcJavaVersion','Javac version could not be determined: %s', cmdout);
                    tf = false;
                end
            else
                warning('Client:checkJavacVersion','Javac version could not be determined, error running javac -version: %s',cmdOut);
                tf = false;
            end
        end
    end
end %class