function setup(options)
    % SETUP Top-level function to step through the interface's setup process
    % This function takes the role of install.m in previous releases.
    % The function does not support non interactive use.
    %
    % A named argument: generatorVersion can be provided to request a
    % specific version of the OpenAPI Tools generator be used.
    % The default is defined in Software/Java/pom.xml, e.g. "7.13.0".
    % This is the recommended version.
    %
    % If an alternative version is used the MATLAB specific generator
    % should be compiled using that version.
    %
    % Optional named arguments:
    %   generatorVersion  A string representing the version of the OpenAPI Tools
    %                     generator jar package, e.g.:  "7.13.0"
    %
    %            verbose  A logical flag to enable additional output.
    %                     The default is true.

    % Copyright 2024-2025 The MathWorks, Inc.

    arguments
        options.generatorVersion string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.verbose (1,1) logical = true
    end

    startup(setup=true);

    warning("openapi:setup:deprecated","Note that it is no longer necessary to run this setup function.\n" + ...
            "The required JAR-file is now downloaded as part of the Maven build process.\n" + ...
            "This function may be removed in future versions of the package.")

    printBanner("MATLAB Generator for OpenAPI setup");
    fprintf("\n");

    batchModeError(); % Error, this should not fail silently

    fprintf("This package requires a library provided by the OpenAPI Tools project.\n");
    fprintf("Project details and the associated license can be found here:\n");
    fprintf("  %s\n", openapi.internal.utils.URL2Link("https://github.com/OpenAPITools/openapi-generator"));
    fprintf("\n");

    pomGeneratorVersion = openapi.internal.utils.getGeneratorJarVersion();

    fprintf("The version of this library used by default is: %s\n", pomGeneratorVersion);
    fprintf("This is defined in the file: %s\n", openapiRoot(-1, "Java", "pom.xml"));
    fprintf("This is used to build the MATLAB specific generator.\n");
    fprintf("\n");

    if isfield(options, "generatorVersion")
        if ~strcmp(options.generatorVersion, pomGeneratorVersion)
            fprintf(2, "The requested version: %s does not match that defined in the pom.xml file: %s\n", options.generatorVersion, pomGeneratorVersion);
            fprintf(2, "This can result in a version mismatch or incompatibility at runtime and should be avoided.\n");
            fprintf(2, "Non default versions are not tested or supported.\n");
            fprintf("\n");
        end
        generatorVersion = options.generatorVersion;
    else
        generatorVersion = pomGeneratorVersion;
    end
    
    prompt = sprintf("Download required OpenAPI generator jar file, version: %s", generatorVersion);
    jarDownload = openapi.internal.utils.ynQuestion(prompt, "Y");
    if jarDownload
        jarPath = openapi.internal.Jars.downloadGeneratorJar(generatorVersion, verbose=options.verbose); %#ok<NASGU>
    else
        jarPath = string.empty; %#ok<NASGU>
    end

    matlabJarTf = checkMATLABJar(verbose = options.verbose);
    if ~matlabJarTf
        % TODO add this in the future
        fprintf(2, "This file is not automatically built by setup.m.\n");
    end


    if jarDownload && strlength(jarPath) > 0 && matlabJarTf
        setupComplete();
    else
        setupInComplete();
    end
end


function tf = checkMATLABJar(options)
    arguments
        options.verbose (1,1) logical = true
    end

    jarName = "MATLAB-openapi-generator-" + openapi.internal.utils.getMATLABJarVersion() + ".jar";
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


function setupComplete()
    fprintf("\nSetup complete.\n");
    fprintf("To use the package run: startup\n\n");
end


function setupInComplete()
    fprintf(2, "\nSetup incomplete.\n");
    fprintf(2, "The package may not function correctly to proceed rerun setup or run: startup\n\n");
end


function batchModeError()
    if batchStartupOptionUsed
        % Error because this should not fail silently
        error('OPENAPI:SETUP', 'Setup does not support running MATLAB in batch mode.');
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
