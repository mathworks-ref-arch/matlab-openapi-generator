function link = editLink(path, options)
    % EDITLINK Returns a URL as a href'd MATLAB editor link
    %
    % Example:
    %   fprintf("%s\n", openapi.internal.utils.editLink(databricksRoot(-2, "Documentation", "README.md")));

    %  (c) 2024-2025 MathWorks, Inc.

    arguments
        path string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.label string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    if ~isdeployed
        if isfield(options, "label")
            link = sprintf('<a href="matlab: edit(''%s'')">%s</a>', path, options.label);
        else
            link = sprintf('<a href="matlab: edit(''%s'')">%s</a>', path, path);
        end
    else
        % Best effort return a string
        if isfield(options, "label")
            link = sprintf('%s: %s', options.label, path);
        else
            link = sprintf('%s', path);
        end
    end
end
