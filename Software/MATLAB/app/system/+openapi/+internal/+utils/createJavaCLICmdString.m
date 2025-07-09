function cmdStr = createJavaCLICmdString()
    % CREATEJAVACLICMDSTRING Return the command to run java
    % A string is returned.

    % (c) MathWorks Inc 2024-2025

    jh = getenv("JAVA_HOME");
    if ~isempty(jh)
        cmdStr = sprintf("""%s"" ",fullfile(jh,"bin","java"));
    else
        cmdStr = "java ";
    end
end
