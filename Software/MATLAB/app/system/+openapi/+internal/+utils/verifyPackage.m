function [tf, reportOut] = verifyPackage(directory, options)
    % VERIFYPACKAGE runs checkcode on a specified directory
    % 
    % This function does not check the functionally of the code, rather it checks
    % that the generated MATLAB code is syntactically valid. It is recommended
    % addition tests are provided to validate the functionality of generated code.
    %
    % Inputs:
    %     directory : Path to a specific directory of files to check.
    %                 Only .m files are checked.
    %                 Required.
    %
    %           mode: Name-value argument for strict checking, if set to
    %                 "nonStrict" (default) then some issues are tolerated
    %                 and an optional list of tolerated issues can be provided.
    %                 Must be "nonStrict" (default) or "strict".
    %                 Optional.
    %
    % ignoredChecks : A string array name-value argument for code check messages that
    %                 should be ignored in the case of non-strict checking.
    %                 Strings are matched using contains.
    %
    %
    % Outputs:
    %   A report is displayed in the Command Window.
    %
    %           tf: A logical value tf is returned as false if any non-tolerated issue
    %               is detected otherwise true is returned.
    %
    %   reportOut : A cell array of issues or lack thereof and the corresponding paths.
    %               Optional.
    %
    %
    % Tolerated/Ignored issues (default):
    %
    %   * In R2023a the linter can report:
    %     "'empty' is referenced but is not a property, method, or event name defined in this class."
    %     This can be safely ignored and is not reported in later releases.
    %
    %   * A Code Analyzer message would previously have applied but not longer does, perhaps
    %     due to the use of a different version of MATLAB.
    %     "A Code Analyzer message was once suppressed here, but the message is no longer generated."
    %     This can generally be safely ignored.
    %
    %   * If checking code using a version of MATLAB later than that which the package
    %     was originally built with the following may be reported:
    %     "No Code Analyzer check is found for this check ID."
    %     This can generally be safely ignored.
    %    
    %   Additional user defined messages can be ignored using the ignoredChecks argument.
    %
    % Examples:
    %
    %   % Displays report in the Command Window returns true if no issues found
    %   tf = openapi.verifyPackage('myClient')
    %
    %   % Displays report in the Command Window and also returns messages
    %   % and filenames as report
    %   [tf, report] = openapi.verifyPackage('myClient')
    %
    %   % Check files strictly with no exceptions
    %   tf = openapi.verifyPackage("myClient", "mode", "strict")
    %
    %   % Check files non-strictly with additional user defined exceptions
    %   tf = openapi.verifyPackage("myClient", "ignoredChecks", ["my tolerable message 1", "my tolerable message 2"])
    %
    % See Also: checkcode openapi.build.Client.verifyPackage

    % Copyright 2022-2023 The MathWorks, Inc.

    arguments
        directory string {mustBeTextScalar}
        options.mode string {mustBeTextScalar, mustBeMember(options.mode,{'nonStrict','strict'})} = 'nonStrict'
        options.ignoredChecks string = ""
    end

    fprintf("Running 'checkcode' on all M-files in: %s\n", directory)
    fprintf('Validation mode: %s\n', options.mode)

    releaseInfo = matlabRelease;

    % Find all M-files below the specified filepath
    files = dir(fullfile(directory,'**','*.m'));
    Nfiles = length(files);
    fprintf('Located %d files\n', Nfiles);

    NfileWithMessage = 0;
    NtotalMessages = 0;
    NignoredMessages = 0;

    tf = true; % Anywhere it is set to false indicates a problem, do not reset to true

    if nargout == 2
        reportOutCell = cell(Nfiles,1);
        pathOutCell= cell(Nfiles,1);
    end

    % Run check code on all files
    for n = 1:Nfiles
        [report, path] = checkcode(fullfile(files(n).folder, files(n).name));

        if nargout == 2
            reportOutCell{n} = report;
            pathOutCell{n} = path;
        end

        if ~isstruct(report)
            error('verifyPackage:checkcode', 'Unexpected checkcode output, expected struct');
        end

        if ~isempty(report)
            NfileWithMessage = NfileWithMessage + 1;
            fprintf('=== %s ===\n',path{1});
            for m = 1:numel(report)
                NtotalMessages = NtotalMessages + 1;
                if isfield(report(m), 'message') && isfield(report(m), 'line')
                    if strcmpi(options.mode, "nonStrict")
                        % Tolerable case for non strict
                        % Don't set tf to true so as to not overwrite a previous problem
                        if strcmp(releaseInfo.Release, 'R2023a') && contains(report(m).message, "'empty' is referenced but is not a property, method, or event name defined in this class.")
                            fprintf('Ignoring known issue in R2023a linting, line: %d\n', report(m).line);
                            NignoredMessages = NignoredMessages + 1;
                        elseif contains(report(m).message, "A Code Analyzer message was once suppressed here, but the message is no longer generated.")
                            fprintf('Ignoring: "Code Analyzer message was once suppressed here, but the message is no longer generated.", line: %d\n', report(m).line);
                            NignoredMessages = NignoredMessages + 1;
                        elseif contains(report(m).message, "No Code Analyzer check is found for this check ID.")
                            fprintf('Ignoring: "No Code Analyzer check is found for this check ID.", line: %d\n', report(m).line);
                            NignoredMessages = NignoredMessages + 1;
                        elseif sum(strlength(options.ignoredChecks)) > 0 % There is at least 1 entry
                            for j = 1:numel(options.ignoredChecks)
                                % Skip zero length messages as this will always be true and be a false positive
                                if strlength(options.ignoredChecks(j)) > 0
                                    if contains(report(m).message, options.ignoredChecks(j))
                                        fprintf('Ignoring: %s Line: %d\n', report(m).message, report(m).line);
                                        NignoredMessages = NignoredMessages + 1;
                                    end
                                end
                            end
                        else
                            fprintf('%s Line: %d\n', report(m).message, report(m).line);
                            tf = false; % A non tolerated error
                        end
                    elseif strcmpi(options.mode, "strict")
                        fprintf('%s Line: %d\n', report(m).message, report(m).line);
                        tf = false; % A non tolerated error
                    else
                        error('verifyPackage:checkcode', 'Unexpected mode value: %s, expected "nonStrict" or "strict"', options.mode);
                    end
                else
                    tf = false; % Should have a message field
                    warning('verifyPackage:checkcode', 'Unexpected checkcode output, message or line field not found');
                end
            end
            fprintf('\n');
        end
    end

    % Print summary
    fprintf('Checked %d files\n', Nfiles);
    fprintf('%d files haves message(s)\n', NfileWithMessage);
    fprintf('In total %d message(s) were reported\n', NtotalMessages)
    fprintf('%d message(s) ignored based on strictness\n\n', NignoredMessages);

    % If output requested output messages and filenames as well
    if nargout == 2
        reportOut = [reportOutCell, pathOutCell];
    end
end
