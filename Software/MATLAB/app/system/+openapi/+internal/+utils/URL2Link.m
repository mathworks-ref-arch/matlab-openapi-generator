function link = URL2Link(URL, options)
    % URL2LINK Returns a URL value as a href'd link
    % Non HTTP links should be absolute paths.
    % UNC paths are not currently supported.

    %  (c) 2024 MathWorks, Inc.

    arguments
        URL
        options.label string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    if isa(URL, "matlab.net.URI")
        urlVal = URL;
    elseif (ischar(URL) || isStringScalar(URL)) && strlength(URL) > 0
        if startsWith(URL, "http", 'IgnoreCase', true)
            urlVal = matlab.net.URI(URL);
        else
            checkPath(URL);
            if ispc
                urlVal = "file:///" + replace(URL, "\", "/");
            else
                urlVal = "file://" + URL;
            end
        end
    else
        error("URL2LINK:URLTYPE", "URL must be of type scalar text or matlab.net.URI");
    end

    if isfield(options, "label")
        if isa(urlVal, "matlab.net.URI")
            link = sprintf('<a href="%s">%s</a>', urlVal.EncodedURI, options.label);
        else
            link = sprintf('<a href="%s">%s</a>', urlVal, options.label);
        end
    else
        if isa(urlVal, "matlab.net.URI")
            link = sprintf('<a href="%s">%s</a>', urlVal.EncodedURI, urlVal.EncodedURI);
        else
            link = sprintf('<a href="%s">%s</a>', urlVal, urlVal);
        end
    end
end

function checkPath(path)
    arguments
        path string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    if ispc
        if ~startsWith(path, lettersPattern(1) + characterListPattern(":") + characterListPattern("\"))
            fprintf(2, "Expected an absolute path: %s\n", path);
        end
    else
        if ~startsWith(path, "/")
            fprintf(2, "Expected an absolute path: %s\n", path);
        end
    end
end