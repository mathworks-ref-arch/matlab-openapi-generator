classdef TestServerGen < matlab.unittest.TestCase
    % ThirdPartySpecs Test the generator by passing a number of third party specs

    properties (Constant)
        fixturesPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'fixtures')
        release = matlabRelease
    end

    methods (TestClassSetup)
    end

    methods (Test)

        function testPetstore(testCase)
            disp('Running testPetstore');
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['PetStore-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = tempname;
                mkdir(tmpFolder);
                oc = onCleanup(@()rmdir(tmpFolder,"s"));
            end
            c = openapi.build.Server;
            c.packageName = "Petstore";
            c.inputSpec = "https://raw.githubusercontent.com/swagger-api/swagger-petstore/refs/heads/master/src/main/resources/openapi.yaml";
            c.output = fullfile(tmpFolder,"Petstore");
            % c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Server');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));
            
            % For now just verify this hasn't errored out
            % TODO try to further verify something valid was generated
        end

        function testSnowflake(testCase)
            % This tests generates a server based on API specs for
            % Snowflake.
            % 
            % This is of course not a real use-case, no-one would ever
            % want to reimplement a Snowflake API compatible service in 
            % MATLAB. But it is a good test,  to simply verify that the
            % server gen is able to produce something here without
            % erroring, etc.
            % 
            % The Snowflake spec is spread across multiple
            % different files. This allows testing inputSpecRootDirectory.
            disp('Running testSnowflake');
            % Clone the Snowflake repo, this checkout a specific revision
            % which has been verified to not contain any issues in the spec
            % itself.
            tempSpec = tempname;
            mkdir(tempSpec)
            removeSnowflake = onCleanup(@()rmdir(tempSpec,"s"));            
            cmd = sprintf([ ...
                'cd %s' ...
                ' && git clone --depth=1 https://github.com/snowflakedb/snowflake-rest-api-specs.git' ...
                ' && cd snowflake-rest-api-specs' ...
                ' && git fetch --depth=1 origin dc5da9f0a8423c34e306ed821fa04250a5c15dd0' ...
                ' && git checkout dc5da9f0a8423c34e306ed821fa04250a5c15dd0'], ...
                tempSpec);
            [status,log] = system(cmd);
            testCase.assertEqual(status,0,log);
            specPath = fullfile(tempSpec,'snowflake-rest-api-specs','releases','8.40','specifications');
            
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', 'Snowflake', ['Snowflake-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = tempname;
                mkdir(tmpFolder);
                oc = onCleanup(@()rmdir(tmpFolder,"s"));
            end

            c = openapi.build.Server;
            c.packageName = "Snowflake";
            c.inputSpecRootDirectory = specPath;
            c.output = fullfile(tmpFolder,"Snowflake");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Server');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));
    
        end

    end
end
