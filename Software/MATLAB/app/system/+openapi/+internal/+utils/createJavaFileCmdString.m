function cmdStr = createJavaFileCmdString(classpath, configurationFile, options)
    % CREATEJAVAFILECMDSTRING 
    % A string is returned.

    % (c) MathWorks Inc 2024

    arguments
        classpath string {mustBeTextScalar, mustBeNonzeroLengthText}
        configurationFile string {mustBeTextScalar, mustBeNonzeroLengthText}
        options.additionalArguments string {mustBeTextScalar, mustBeNonzeroLengthText}
    end

    javaCmdStr = openapi.internal.utils.createJavaCmdString;
    cmdStr = javaCmdStr + " -cp " + '"' + classpath + '"';
    cmdStr = cmdStr + " --config " + '"' + configurationFile + '"';

    if isfield(options, "additionalArguments")
        cmdStr = cmdStr + " " + options.additionalArguments;
    end
end