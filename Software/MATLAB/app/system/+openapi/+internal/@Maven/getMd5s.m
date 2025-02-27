function md5Values = getMd5s(md5Urls)
    % GETMD5S Return MD5s for given URLs
    % Values are returns as a string array
    %
    % Example:
    %   md5Values = openapi.internal.Maven.getMd5s(md5Urls)

    %  (c) 2024 MathWorks, Inc.

    arguments
        md5Urls (:,1) string {mustBeNonzeroLengthText}
    end

    len = numel(md5Urls);
    md5Values = strings(len, 1);
    for n = 1:len
        try
            md5Values(n) = string(webread(md5Urls(n)));
        catch
            md5Values(n) = "";
        end
    end
end