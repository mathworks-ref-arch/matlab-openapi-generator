function jarPath = downloadGeneratorJar(version, options)
    % DOWNLOADGENERATORJAR Downloads the org.openapitools:openapi-generator jar file
    % The local path to the download is returned as a string.
    % If the file is not found an empty string is returned.
    % The version to download should be provided as a scalar text value.
    %
    % Example:
    %   jarPath = openapi.internal.Jars.downloadGeneratorJar("6.6.0")

    %  (c) 2024 MathWorks, Inc.

    arguments
        version string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.destinationDir = openapiRoot("lib", "jar");
        options.weboptions (1,1) weboptions = weboptions('Timeout', 10)
        options.verbose (1,1) logical = true
    end

    manifest = openapi.internal.Maven.getMvnManifest("org.openapitools", "openapi-generator-cli", weboptions=options.weboptions, verbose=options.verbose);

    jarURL = string.empty;
    for n = 1:numel(manifest)
        if strcmp(version, manifest(n).version)
            jarURL = manifest(n).jarURL;
            % TODO check the download's md5
            % md5URL = manifest(n).md5URL;
            break;
        end
    end

    if isempty(jarURL)
        jarPath = string.empty;
    else
        uri = matlab.net.URI(jarURL);
        queryFields = split(uri.Query(end).Value, "/");
        jarPath = fullfile(options.destinationDir, queryFields(end));
        if options.verbose
            fprintf("Downloading: %s\n", jarURL)
        end
        websave(jarPath, jarURL, options.weboptions);
    end
end