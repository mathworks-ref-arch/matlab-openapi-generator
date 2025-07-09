function cmdStr = createJavacCLICmdString()
    % CREATEJAVACCLICMDSTRING Return the command to run javac
    % A string is returned.

    % (c) MathWorks Inc 2024-2025

    jh = getenv("JAVA_HOME");
    if ~isempty(jh)
        cmdStr = sprintf("""%s"" ",fullfile(jh,"bin","javac"));
    else
        cmdStr = "javac ";
    end
end