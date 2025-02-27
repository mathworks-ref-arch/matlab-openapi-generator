function [status, cmdOut, cmdStr] = wrappedSystem(cmdStr)
    % Wrap a system call in steps to improve reliability of call 3rd party packages
    % Unset LD_LIBRARY_PATH in the system context to avoid potential glibc issue
    % On macOS prepend /usr/local/bin in $PATH

    % (c) MathWorks Inc 2024

    arguments
        cmdStr string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    % Assume char type from here
    cmdStr = char(cmdStr);

    if ispc
        [status, cmdOut] = system(cmdStr);
    elseif ismac
        % prepend default npx location on macOS
        [status, cmdOut] = system(['export PATH="/usr/local/bin:$PATH"; ', cmdStr]);
    else
        [status, cmdOut] = system(['export LD_LIBRARY_PATH=""; ', cmdStr]);
    end
end