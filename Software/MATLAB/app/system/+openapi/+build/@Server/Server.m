classdef Server < openapi.build.internal.Builder
    % Server object to assist in building a MATLAB Server based on OpenAPI
    % specs.
    %
    % Server Properties:
    %
    %   packageName - Name of the MATLAB package to generate the Server in.
    %
    %   matlabJarPath - Location of MATLABServerCodegen-openapi-generator-0.0.1.jar.
    %       Does not have to be specified and can be left at its default 
    %       value if it is located in its default location.
    %
    %   inputSpec - Location of the single OpenAPI spec. If the
    %       specification is spread across multiple separate files,
    %       consider using inputSpecRootDirectory instead. Either inputSpec
    %       or inputSpecRootDirectory must be set.
    %
    %   inputSpecRootDirectory - Directory containing a collection of files
    %       which make up the entire specification. Either inputSpec or
    %       inputSpecRootDirectory must be set.
    %
    %   output - Output directory
    %
    %   additionalArguments - Additional arguments to pass to the generator.
    %
    %   templateDir - Location of the mustache templates. Does not have to
    %       be specified and can be left at its default value if these are
    %       located in their default location.
    %
    %   globalProperty - Extra global properties to be passed to the
    %       generated, specified as containers.Map.
    %
    %   copyrightNotice - Copyright notice to include in the generated code.
    %
    %   additionalProperties - Extra additional properties to be passed to
    %       the generated, specified as containers.Map. 
    %
    %   configurationFile - Name and location of the configuration file to
    %       use/generate.
    %
    %   skipValidateSpec - Disable spec validation. This can be useful in
    %       cases where the spec is not 100% compliant but code can still
    %       be generated.
    %
    % Server Methods:
    %
    %   Server - constructor. Can be called with Name-Value pairs where
    %       the name matches property names and the value specifies what value
    %       to set this property to.
    %
    %   build - build the package.

    %  (c) 2021-2025 MathWorks, Inc.

    properties(Access=protected)
        generatorName = "matlab-server"
    end
    methods
        function obj = Server(options)
            %Server constructor
            %
            % Can be called with Name-Value pairs where the name matches
            % property names and the value specifies what value to set this
            % property to.
            %
            % Example:
            %   builder = openapi.build.Server(inputSpec="mySpec.yaml");
            arguments
                options.inputSpec string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.inputSpecRootDirectory string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.matlabJarPath string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.templateDir string {mustBeTextScalar} = openapiRoot(-1, 'Mustache')
                options.packageName string {mustBeTextScalar, mustBeNonzeroLengthText} = 'OpenAPIServer'
                options.output string {mustBeTextScalar} = fullfile(pwd, 'OpenAPIServer')
                options.additionalArguments string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.globalProperty containers.Map = containers.Map.empty
                options.copyrightNotice string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.additionalProperties containers.Map = containers.Map.empty
                options.inputConfigurationFile string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.outputConfigurationFile string {mustBeTextScalar, mustBeNonzeroLengthText} = 'openapitools.json'
                options.skipValidateSpec (1,1) logical = true
                options.generatorJarPath string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.generatorVersion string {mustBeTextScalar, mustBeNonzeroLengthText}
                options.logPath string {mustBeTextScalar, mustBeNonzeroLengthText}
                
            end
            options.objectParameters = containers.Map.empty;
            opts = namedargs2cell(options);
            obj@openapi.build.internal.Builder(opts{:});
        end
    end
end %class