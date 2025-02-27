function tf = checkJavacVersion(min)
    % CHECKJAVACVERSION returns true if Javac <min> or greater is detected
    % Returns a logical.
    % Default min value is 11.

    % TODO implement an upper bound

    % (c) MathWorks Inc. 2024

    arguments
        min int32 {mustBeInteger, mustBeNonnegative} = 11
    end

    cmdStr = openapi.internal.utils.createJavacCLICmdString() + " -version";
    [status, cmdOut] = system(cmdStr);
    if status == 0
        pat = digitsPattern + "." + digitsPattern + ".";
        newStr = extract(cmdOut, pat);
        fields = split(newStr, '.');
        if numel(fields) >= 2
            if str2double(fields{1}) >= min % Not clear what upper bound is TBD
                tf = true;
            else
                fprintf(2, 'Javac %d or compatible is required, found: %s\n', min, cmdOut);
                tf = false;
            end
        else
            fprintf(2, 'Javac version could not be determined: %s\n', cmdOut);
            tf = false;
        end
    else
        fprintf(2, 'Javac version could not be determined, error running javac -version: %s\n', cmdOut);
        tf = false;
    end
end