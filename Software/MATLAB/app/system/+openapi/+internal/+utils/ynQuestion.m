function tf = ynQuestion(prompt, default, options)
    % YNQUESTION Returns true if the answer to a question is Y or y
    % If the default is y/Y 'enter' also returns true.
    % Otherwise false is returned.
    
    % Copyright 2024 The MathWorks, Inc.

    arguments
        prompt string {mustBeTextScalar, mustBeNonzeroLengthText}
        default string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.preamble string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    if isfield(options, "preamble")
        fprintf("%s\n", options.preamble);
    end

    default = upper(default);
    if ~(strcmp(default, "Y") || strcmp(default, "N"))
        fprintf(2, "Unexpected default value: %s, using 'Y'.\n", default);
        default = "Y";
    end
    fullPrompt = sprintf("%s? Y/N [%s]: ", prompt, default);
    reply = strip(input(fullPrompt, 's'));
    if strlength(reply) == 0
        reply = default;
    end
    if strcmpi(reply,'y')
        tf = true;
    else
        tf = false;
    end
end