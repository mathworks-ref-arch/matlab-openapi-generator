classdef (Abstract) Builder < openapi.build.Object
    properties (Abstract, Access=protected)
        generatorName string
    end

    properties
        % Name of the MATLAB package to generate the client in.
        packageName string
        % Location of MATLAB-openapi-generator-3.0.0.jar. Does
        % not have to be specified and can be left at its default value if
        % it is located in its default location.
        matlabJarPath string
        % Location of the OpenAPI spec.
        inputSpec string
        % Directory containing a collection of files which make up the
        % specification.
        inputSpecRootDirectory string
        % Output directory
        output string
        % Additional arguments to pass to the generator.
        additionalArguments string
        % Location of the mustache templates. Does not have to be specified
        % and can be left at its default value if these are located in
        % their default location.
        templateDir string
        % Extra global properties to be passed to the generated, specified
        % as containers.Map.
        globalProperty
        % Copyright notice to include in the generated code.
        copyrightNotice string
        % Extra additional properties to be passed to the generated,
        % specified as containers.Map.
        additionalProperties
        % Name and location of the configuration file to use/generate.
        inputConfigurationFile string
        % Default to openapitools.json
        outputConfigurationFile string
        % Disable spec validation. This can be useful in cases where the
        % spec is not 100% compliant but code can still be generated.
        skipValidateSpec (1,1) logical
        % Specify which common parameters are specified as property on the
        % generated classes rather than being inputs to specific
        % operations, specified as containers.Map
        objectParameters  
        % Path to generator Jar file
        % Default Software/MATLAB/lib/jar/openapi-generator-<version>.jar
        generatorJarPath string
        % Generator version e.g. 6.6.0
        generatorVersion string
        % Location of build log file
        logPath string
    end

    properties (Hidden)
        logFid = 0
    end

    methods
        function obj = Builder(options)
            arguments
                options.inputSpec string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.inputSpecRootDirectory string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.matlabJarPath string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.templateDir string {mustBeTextScalar} = openapiRoot(-1, 'Mustache')
                options.packageName string {mustBeTextScalar, mustBeNonzeroLengthText} = 'OpenAPIClient'
                options.output string {mustBeTextScalar} = fullfile(pwd, 'OpenAPIClient')
                options.additionalArguments string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.globalProperty containers.Map = containers.Map.empty
                options.copyrightNotice string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.additionalProperties containers.Map = containers.Map.empty
                options.inputConfigurationFile string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.outputConfigurationFile string {mustBeTextScalar, mustBeNonzeroLengthText} = 'openapitools.json'
                options.skipValidateSpec (1,1) logical = true
                options.objectParameters containers.Map 
                options.generatorJarPath string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.generatorVersion string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.logPath string {mustBeTextScalar, mustBeNonzeroLengthText}
            end            
            % Call all the setters
            for p = string(fieldnames(options))'
                obj.(p) = options.(p);
            end

            if ~isa(obj.additionalProperties, 'containers.Map')
                error('Client:Client', 'Expected additionalProperties property to be a containers.Map, not: %s', class(obj.additionalProperties));
            else
                obj.additionalProperties('packageVersion') = openapi.internal.utils.getPackageVersion();
            end

            if ~isa(obj.globalProperty, 'containers.Map')
                error('Client:Client', 'Expected globalProperty property to be a containers.Map, not: %s', class(obj.globalProperty));
            end

            if ~isa(obj.objectParameters, 'containers.Map')
                error('Client:Client', 'Expected objectParameters property to be a containers.Map, not: %s', class(obj.objectParameters));
            end     

            if isempty(obj.generatorJarPath)
                if isempty(obj.generatorVersion)
                    obj.generatorJarPath = openapi.internal.utils.getGeneratorJarPath(openapi.internal.utils.getGeneratorJarVersion());
                else
                    obj.generatorJarPath = openapi.internal.utils.getGeneratorJarPath(obj.generatorVersion);
                end
            end

            if isempty(obj.matlabJarPath)
                jarName = "MATLAB-openapi-generator-" + openapi.internal.utils.getMATLABJarVersion() + ".jar";
                obj.matlabJarPath = string(fullfile(openapiRoot('lib', 'jar'), jarName));
            end
        end


        function obj = build(obj)
            %build build the MATLAB client
            arguments
                obj (1,1) openapi.build.internal.Builder
            end

            cleanup = onCleanup(@()logClose(obj));

            obj.log(sprintf('OpenAPI Client Generator: %s',datetime('now')));

            % check for MATLAB version, jar file, javac
            if ~obj.checkJavaDeps
                errMsg = sprintf('Dependency check failed, review warnings\nCheck if java and javac (>= v11) paths are configured.');
                obj.log(errMsg);
                error('Client:build', errMsg); %#ok<SPERR>
            end

            if ~isempty(obj.inputSpecRootDirectory)
                if ~isempty(obj.inputSpec)
                    warning('client:InputSpecAndInputSpecRootDirectoryBothSet','Both inputSpec and inputSpecRootDirectory have been set. In this case inputSpec is ignored and only inputSpecRootDirectory is used.')
                end
            elseif isempty(obj.inputSpec)
                error('client:NeitherInputSpecNorInputSpecRootDirectorySet','Either inputSpec or inputSpecRootDirectory must be set.')
            end

            classpath = obj.generatorJarPath + openapi.internal.utils.classpathSep + obj.matlabJarPath;

            if ~isempty(obj.inputConfigurationFile)
                obj.dispLog(sprintf('Using configuration file: %s', obj.inputConfigurationFile));
                obj.buildAdditionalPropertiesFileEntry();
                obj.writeCLIConfigurationFile();
                if ~isfile(obj.inputConfigurationFile)
                    errMsg = sprintf('Configuration file not found: %s', obj.inputConfigurationFile);
                    obj.log(errMsg);
                    error('Client:build:FileNotFound', errMsg); %#ok<SPERR>
                else
                    if strlength(obj.additionalArguments) > 0
                        cmdStr = openapi.internal.utils.createJavaFileCmdString(classpath, obj.inputConfigurationFile, additionalArguments=obj.additionalArguments);
                    else
                        cmdStr = openapi.internal.utils.createJavaFileCmdString(classpath, obj.inputConfigurationFile);
                    end
                end
            else
                cmdStr = openapi.internal.utils.createJavaCLICmdString();
                cmdStr = cmdStr + " -cp " + '"' + classpath + '"';
                cmdStr = cmdStr + " org.openapitools.codegen.OpenAPIGenerator";
                cmdStr = cmdStr + " generate --generator-name " + obj.generatorName;
                if ~isempty(obj.inputSpecRootDirectory)
                    cmdStr = cmdStr + " --input-spec-root-directory " + '"' + obj.inputSpecRootDirectory + '"';
                elseif ~isempty(obj.inputSpec)
                    cmdStr = cmdStr + " --input-spec " + '"' + obj.inputSpec + '"';
                end
                cmdStr = cmdStr + " --output " + '"' + obj.output + '"';
                cmdStr = cmdStr + " --package-name " + '"' + obj.packageName + '"';
                cmdStr = cmdStr + " --template-dir " + '"' + obj.templateDir + '"';
                cmdStr = cmdStr + obj.buildAdditionalPropertiesCLIEntry();

                if obj.skipValidateSpec
                    cmdStr = cmdStr + " --skip-validate-spec";
                end

                cmdStr = cmdStr + obj.buildGlobalPropertiesCLIEntry();

                if strlength(obj.additionalArguments) > 0
                   cmdStr = cmdStr + " " + obj.additionalArguments;
                end
            end

            obj.dispLog(['Building client, executing command:', newline, '  ', char(cmdStr), newline]);

            [cmdStatus, cmdOut, cmdStrExec] = openapi.internal.utils.wrappedSystem(cmdStr);
    
            obj.log(sprintf('Prefixed command: %s\n', cmdStrExec));
            obj.log(sprintf('Command result: %d\n', cmdStatus));
            obj.log(sprintf('Command output:\n%s\n', cmdOut));
    
            if cmdStatus ~= 0
                error('Client:build', 'build failed: \n%s\nLog: %s', cmdOut, fullfile(obj.output, obj.packageName + "_build.log"));
            else
                obj.dispLog(sprintf('build completed, output directory: %s', obj.output));
            end
        end


        function [tf, reportOut] = verifyPackage(obj, options)
            % verifyPackage Simple wrapper to populate the output path automatically
            arguments
                obj (1,1) openapi.build.internal.Builder
                options.mode string {mustBeTextScalar, mustBeMember(options.mode,{'nonStrict','strict'})} = 'nonStrict'
                options.ignoredChecks string = ""
            end

            [tf, reportOut] = openapi.internal.utils.verifyPackage(obj.output, 'mode', options.mode, 'ignoredChecks', options.ignoredChecks);
        end


        function set.packageName(obj, name)
            arguments
                obj (1,1) openapi.build.internal.Builder
                name string {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            % Allow for package names that have "." in them
            nfields = split(name, '.');
            for m = 1:numel(nfields)
                [newName, modified] = matlab.lang.makeValidName(nfields(m));
                if modified
                    fprintf(2, "Invalid packageName field: %s, changing to: %s\n", nfields(m), newName);
                    nfields(m) = newName;
                end
            end
            obj.packageName = join(nfields, '.');
        end


        function set.templateDir(obj, templateDir)
            arguments
                obj (1,1) openapi.build.internal.Builder
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
                obj (1,1) openapi.build.internal.Builder
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
                obj (1,1) openapi.build.internal.Builder
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

        function set.inputSpecRootDirectory(obj, inputSpecRootDirectory)
            arguments
                obj (1,1) openapi.build.internal.Builder
                inputSpecRootDirectory string {mustBeTextScalar}
            end
            if ~isfolder(inputSpecRootDirectory)
                error('Client:set_inputSpecRootDirectory','Specified input spec root directory does not exist: %s', inputSpecRootDirectory);
            else
                obj.inputSpecRootDirectory = inputSpecRootDirectory;
            end
        end        


        function set.matlabJarPath(obj, matlabJarPath)
            arguments
                obj (1,1) openapi.build.internal.Builder
                matlabJarPath string {mustBeTextScalar}
            end

            if ~isfile(matlabJarPath)
                error('Client:set_matlabJarPath','OpenAPI MATLAB generator jar file not found: %s, to build it run "mvn clean package" in a shell from Software/Java.', matlabJarPath);
            else
                obj.matlabJarPath = matlabJarPath;
            end
        end


        function set.generatorJarPath(obj, generatorJarPath)
            arguments
                obj (1,1) openapi.build.internal.Builder
                generatorJarPath string {mustBeTextScalar}
            end

            if ~isfile(generatorJarPath)
                error('Client:set_generatorJarPath','OpenAPI generator jar file not found: %s, to build it run "mvn clean package" in a shell from Software/Java.', generatorJarPath);
            else
                obj.generatorJarPath = generatorJarPath;
            end
        end
        

        function set.additionalArguments(obj, additionalArguments)
            arguments
                obj (1,1) openapi.build.internal.Builder
                additionalArguments string {mustBeTextScalar}
            end

            obj.additionalArguments = additionalArguments;
        end


        function set.copyrightNotice(obj, copyrightNotice)
            arguments
                obj (1,1) openapi.build.internal.Builder
                copyrightNotice string {mustBeTextScalar}
            end

            if ~startsWith(copyrightNotice, whitespacePattern(0,inf) + "%")
                copyrightNotice = "% " + copyrightNotice;
            end
            obj.copyrightNotice = copyrightNotice;
        end


        function set.globalProperty(obj, globalProperty)
            arguments
                obj (1,1) openapi.build.internal.Builder
                globalProperty containers.Map
            end

            obj.globalProperty = globalProperty;
        end


        function set.additionalProperties(obj, additionalProperties)
            arguments
                obj (1,1) openapi.build.internal.Builder
                additionalProperties containers.Map
            end

            obj.additionalProperties = additionalProperties;
        end


        function tf = checkJavaDeps(obj)
            mlTf = obj.checkMATLABVersion();
            jarTf = openapi.internal.utils.checkMATLABJar();
            javaTf = openapi.internal.utils.checkJavaVersion();
            javacTf = openapi.internal.utils.checkJavacVersion();

            tf = all([mlTf, jarTf, javaTf, javacTf]);
        end
    end


    methods (Access = protected, Hidden)
        function obj = log(obj, text)
            arguments
                obj (1,1) openapi.build.internal.Builder
                text (1,:) string {mustBeTextScalar}
            end

            if obj.logFid == 0
                if isempty(obj.logPath)
                    logPathFcn = fullfile(obj.output, obj.packageName + "_build.log");
                else
                    logPathFcn = obj.logPath;
                end
                   
                if ~isfolder(obj.output)
                    if isfile(obj.output)
                        error('Client:log', 'Output directory is a file: %s', obj.output);
                    end
                    mkdir(obj.output);
                    % Assumes subsequent client generation will not delete/overwrite the log file
                end
                [fid, errmsg] = fopen(logPathFcn, 'wt+');
                if fid < 3
                    error('Client:log', 'Error opening log file: %s\n%s', logPathFcn, errmsg);
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
                obj (1,1) openapi.build.internal.Builder
            end

            if obj.logFid > 2
                fclose(obj.logFid);
            end
            obj.logFid = 0;
        end

       
        function dispLog(obj, str)
            % Displays a string and also logs it
            arguments
                obj (1,1) openapi.build.internal.Builder
                str string {mustBeTextScalar}
            end

            disp(str);
            obj.log(str);
        end


        function arg = buildAdditionalPropertiesCLIEntry(obj)
            arguments
                obj (1,1) openapi.build.internal.Builder
            end

            if ~isempty(obj.objectParameters)
                obj.additionalProperties('ObjectParams') = strjoin(vertcat(obj.objectParameters.keys, obj.objectParameters.values), '/');
            end

            crStr = obj.copyrightNotice;

            if strlength(crStr) > 0
                % CLI escaping
                crStr = char(strrep(crStr, "'", ""));
                crStr = char(strrep(crStr, """", ""));
                crStr = char(strrep(crStr, "-", ""));
                obj.additionalProperties('copyrightNotice') = ['"', char(crStr), '"'];
            end

            if strlength(openapiRoot) > 0
                obj.additionalProperties('openapiRoot') = ['"', char(openapiRoot), '"'];
            end

            if obj.additionalProperties.Count > 0
                apKeys = keys(obj.additionalProperties);
                apVals = values(obj.additionalProperties);
                arg = ' --additional-properties ';
                for n = 1:obj.additionalProperties.Count
                    arg = [arg, char(apKeys{n}), '=', char(apVals{n})]; %#ok<AGROW>
                    if n < obj.additionalProperties.Count
                        arg = [arg, ',']; %#ok<AGROW>
                    end
                end
            else
                arg = '';
            end
        end


        function buildAdditionalPropertiesFileEntry(obj)
            arguments
                obj (1,1) openapi.build.internal.Builder
            end

            if ~isempty(obj.objectParameters)
                obj.additionalProperties('ObjectParams') = strjoin(vertcat(obj.objectParameters.keys, obj.objectParameters.values), '/');
            end
            if strlength(obj.copyrightNotice) > 0
                obj.additionalProperties('copyrightNotice') = char(obj.copyrightNotice);
            end
            if strlength(openapiRoot) > 0
                obj.additionalProperties('openapiRoot') = char(openapiRoot);
            end
        end


        function arg = buildGlobalPropertiesCLIEntry(obj)
            arguments
                obj (1,1) openapi.build.internal.Builder
            end

            numProps = size(obj.globalProperty,1);
            if numProps > 0
                gpKeys = keys(obj.globalProperty);
                gpVals = values(obj.globalProperty);
                arg = ' --global-property ';
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
            if verLessThan('MATLAB', '9.10') %#ok<VERLESSMATLAB>
                fprintf(2, 'MATLAB R2021a or later is required.\n');
                tf = false;
            else
                tf = true;
            end
        end


        function tf = writeCLIConfigurationFile(obj)
            if strlength(obj.outputConfigurationFile) < 1
                error('Client:writeCLIConfigurationFile','Configuration file path not set.');
            end
            fid = fopen(obj.outputConfigurationFile, 'w');
            if fid < 3
                error('Client:writeCLIConfigurationFile','Error opening configuration file: %s', obj.outputConfigurationFile);
            end

            l1 = struct;
            l1.schema = "node_modules/@openapitools/openapi-generator-cli/config.schema.json";
            l1.spaces = 2;
            l1.generator_cli.version = obj.cliVersion;
            l1.generator_cli.generators.v30.generatorName = obj.generatorName;
            l1.generator_cli.generators.v30.output = obj.output;
            if ~isempty(obj.inputSpecRootDirectory)
                if ~isempty(obj.inputSpec)
                    warning('client:InputSpecAndInputSpecRootDirectoryBothSet','Both inputSpec and inputSpecRootDirectory have been set. In this case inputSpec is ignored and only inputSpecRootDirectory is used.')
                end
                l1.generator_cli.generators.v30.inputSpecRootDirectory = obj.inputSpecRootDirectory;
            elseif ~isempty(obj.inputSpec)
                l1.generator_cli.generators.v30.inputSpec = obj.inputSpec;
            else
                error('client:NeitherInputSpecNorInputSpecRootDirectorySet','Neither inputSpec nor inputSpecRootDirectory have been set, at least one of these must be configured.')
            end
            l1.generator_cli.generators.v30.packageName = obj.packageName;
            l1.generator_cli.generators.v30.skipValidateSpec = obj.skipValidateSpec;
            l1.generator_cli.generators.v30.templateDir = obj.templateDir;

            numProps = size(obj.additionalProperties,1);
            if numProps > 0
                apKeys = keys(obj.additionalProperties);
                apVals = values(obj.additionalProperties);
                for n = 1:size(obj.additionalProperties,1)
                    if ~isvarname(apKeys{n})
                        error('Client:writeCLIConfigurationFile','Unexpected invalid additionalProperties key: %s, consider adding an exception.', apKeys{n});
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
                        error('Client:writeCLIConfigurationFile','Unexpected invalid global-property key: %s, consider adding an exception.', gpKeys{n});
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

            dispLog(obj, "Writing configuration file: " + obj.outputConfigurationFile);
            dispLog(obj, jsonStr);

            fprintf(fid, "%s", jsonStr);
            fclose(fid);
            tf = true;
        end
    end
end %class