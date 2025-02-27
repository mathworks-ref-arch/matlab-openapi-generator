function tf = checkJavaVersion(min)
    % CHECKJAVAVERSION returns true if Java version <min> or greater is detected
    % Returns a logical.
    % Default min value is 11.
    
    % TODO implement an upper bound

    % (c) MathWorks Inc. 2024

    arguments
        min int32 {mustBeInteger, mustBeNonnegative} = 11
    end

    cmdStr = openapi.internal.utils.createJavaCLICmdString() + " -version";
    [status, cmdOut] = system(cmdStr);
    if status == 0
        lines = split(cmdOut, newline);
        if numel(lines) > 0
            pat = digitsPattern + "." + digitsPattern + ".";
            newStr = extract(lines{1}, pat);
            fields = split(newStr, '.');
            if numel(fields) >= 2
                if str2double(fields{1}) >= min % Not clear what upper bound is TBD
                    tf = true;
                else
                    fprintf(2, 'Java %d or compatible is required, found: %s\n', min, lines{1});
                    tf = false;
                end
            else
                fprintf(2, 'Java version could not be determined: %s\n', lines{1});
                tf = false;
            end
        else
            fprintf(2, 'Java version could not be determined: %s\n', cmdOut);
            tf = false;
        end
    else
        fprintf(2, 'Java version could not be determined, error running java -version: %s\n',cmdOut);
        tf = false;
    end
end
