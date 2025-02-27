function sep = classpathSep()
    % CLASSPATHSEP Returns platform specific Java class path separator
    % Returns a string.

    %  (c) 2024 MathWorks, Inc.

    if ispc
        sep = ";";
    else
        sep = ":";
    end
end