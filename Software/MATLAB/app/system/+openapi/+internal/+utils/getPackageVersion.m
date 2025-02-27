
function V = getPackageVersion()
    % getPackageVersion Return version of the package from the VERSION file
    % A character vector is returned.
    %
    % Example:
    %   v = openapi.internal.utils.getPackageVersion()

    % (c) MathWorks Inc 2024

    verFile = fullfile(openapiRoot(-2), 'VERSION');
    if ~isfile(verFile)
        V = '2.0.0';
        fprintf(2, 'VERSION file not found: %s, using version %s', verFile, V);
    else
        V = char(strip(string(fileread(verFile))));
    end
end