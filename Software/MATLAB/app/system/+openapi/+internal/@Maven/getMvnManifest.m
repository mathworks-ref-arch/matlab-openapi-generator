function manifest = getMvnManifest(groupId, artifactId, options)
    % GETMVNMANIFEST Get MVN versions, 1st page only
    % Calls the sonatype.com https://search.maven.org API
    %
    % Example:
    %   manifest = openapi.internal.Maven.getMvnManifest("org.openapitools", "openapi-generator")
    %
    % See also: https://central.sonatype.org/search/rest-api-guide
    %
    % Sample download URL: https://search.maven.org/remotecontent?filepath=com/jolira/guice/3.0.0/guice-3.0.0.pom
    % Sample search URL: https://search.maven.org/solrsearch/select?q=g:com.google.inject+AND+a:guice&core=gav&rows=20&wt=json
    
    %  (c) 2024 MathWorks, Inc.

    arguments
        groupId string {mustBeTextScalar, mustBeNonzeroLengthText}
        artifactId string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.weboptions (1,1) weboptions = weboptions('Timeout', 10)
        options.verbose (1,1) logical = true
    end

    manifest = getManifest(groupId, artifactId, options.weboptions, options.verbose);
end

function manifest = getManifest(groupId, artifactId, webopts, verbose, options)
    arguments
        groupId string {mustBeTextScalar, mustBeNonzeroLengthText}
        artifactId string {mustBeTextScalar, mustBeNonzeroLengthText}
        webopts (1,1) weboptions
        verbose (1,1) logical
        options.baseSearchURL string {mustBeTextScalar, mustBeNonzeroLengthText} =  "https://search.maven.org/solrsearch/select"
        options.baseDownloadURL string {mustBeTextScalar, mustBeNonzeroLengthText} = "https://search.maven.org/remotecontent?filepath=";
    end
    
    allPages = getAllPages(options.baseSearchURL, groupId, artifactId, webopts, verbose);

    groupIdFields = split(groupId, '.');
    manifest = struct;
    ctr = 1;
    for n = 1:numel(allPages)
        for m = 1:numel(allPages(n).response.docs)
            manifest(ctr).version = string(allPages(n).response.docs(m).v);
            downloadURL = options.baseDownloadURL + join(groupIdFields, "/");
            downloadURL = downloadURL + "/" + artifactId + "/" + manifest(ctr).version + "/" + artifactId + "-" + manifest(ctr).version;
            manifest(ctr).jarURL = downloadURL + ".jar"; % Assume a jar and md5 file exist for all entries
            manifest(ctr).md5URL = downloadURL + ".md5";
            ctr = ctr + 1;
        end
    end
end

function allPages = getAllPages(baseSearchURL, groupId, artifactId, webopts, verbose)
    arguments
        baseSearchURL string {mustBeTextScalar, mustBeNonzeroLengthText}
        groupId string {mustBeTextScalar, mustBeNonzeroLengthText}
        artifactId string {mustBeTextScalar, mustBeNonzeroLengthText}
        webopts (1,1) weboptions
        verbose (1,1) logical
    end

    start = 0;
    allPages = getPage(baseSearchURL, groupId, artifactId, start, webopts, verbose);
    if ~isstruct(allPages.response.docs)
        return;
    end
    numFound = allPages.response.numFound;
    start = numel(allPages.response.docs); % Implied + 1 because start indexes from 0

    while start < numFound
        nextPage = getPage(baseSearchURL, groupId, artifactId, start, webopts, verbose);
        if ~isstruct(nextPage.response.docs)
            break;
        end
        start = start + numel(nextPage.response.docs);
        allPages = [allPages, nextPage]; %#ok<AGROW>
    end

    if start ~= numFound
        fprintf(2, "Unexpected number of responses returned.");
    end
end


function checkPage(data)
    if ~isfield(data, 'response')
        error("OpenAPI:Jars:getMvnVersions", "Maven query did not return a response value");
    else
        if ~isfield(data.response, 'numFound')
            error("OpenAPI:Jars:getMvnVersions", "Maven query did not return a response.numFound value");
        end
        if ~isfield(data.response, 'docs')
            error("OpenAPI:Jars:getMvnVersions", "Maven query did not return expected response.docs value(s)");
        end
    end
end


function data = getPage(baseSearchURL, groupId, artifactId, start, webopts, verbose)
    arguments
        baseSearchURL string {mustBeTextScalar, mustBeNonzeroLengthText}
        groupId string {mustBeTextScalar, mustBeNonzeroLengthText}
        artifactId string {mustBeTextScalar, mustBeNonzeroLengthText}
        start int32 {mustBeInteger, mustBeNonnegative}
        webopts (1,1) weboptions
        verbose (1,1) logical
    end

    url = matlab.net.URI(baseSearchURL + "?q=g:" + groupId + "+AND+a:" + artifactId);
    url.Query(end+1) = matlab.net.QueryParameter("core", "gav"); % applies sorting
    url.Query(end+1) = matlab.net.QueryParameter("rows", "20"); % always request the max supported
    url.Query(end+1) = matlab.net.QueryParameter("wt", "json"); % xml is an option
    url.Query(end+1) = matlab.net.QueryParameter("start", start);

    try
        data = webread(url, webopts);
    catch ME
        if verbose
            fprintf("Request for: %s:%s Maven details failed.\nRetrying: %s\nIdentifier: %s\n", groupId, artifactId, url, ME.identifier);
        end
        data = webread(url, webopts);
    end

    checkPage(data);
end