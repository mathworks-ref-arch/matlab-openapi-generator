classdef GlobalProperty < matlab.unittest.TestCase
    % ThirdPartySpecs Test the generator by passing a number of third party specs

    properties (Constant)
        fixturesPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'fixtures')      
    end

    methods (TestClassSetup)
    end

    methods (Test)
        function testModelsOnly(testCase)
            disp('Running testModelsOnly');
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['PetStore-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end
            c = openapi.build.Client;
            gp = containers.Map({'models'},{''});
            c.globalProperty = gp; % Generate only models
            c.packageName = "Petstore";
            c.inputSpec = fullfile(testCase.fixturesPath, "Petstore_v3.yaml");
            c.output = fullfile(tmpFolder,"Petstore");
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            % Rerun using a config file - TODO update property name - no useConfiguration
            % c.useConfigurationFile = false;
            % c.build;
            % testCase.verifyClass(c,'openapi.build.Client');
            % testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

        end

        function testApisOnly(testCase)
            disp('Running testApisOnly');
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['PetStore-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end
            c = openapi.build.Client;
            c.globalProperty = containers.Map({'apis'},{""}); % Generate only apis
            c.packageName = "Petstore";
            c.inputSpec = fullfile(testCase.fixturesPath, "Petstore_v3.yaml");
            c.output = fullfile(tmpFolder,"Petstore");
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));
        end

        function testModelsAndAPIsOnly(testCase)
            disp('Running testModelsAndAPIsOnly');
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['PetStore-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end
            c = openapi.build.Client;
            gp = containers.Map({'models', 'apis'},{'', ''});
            c.globalProperty = gp; % Generate only models
            c.packageName = "Petstore";
            c.inputSpec = fullfile(testCase.fixturesPath, "Petstore_v3.yaml");
            c.output = fullfile(tmpFolder,"Petstore");
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            % Rerun using a config file TODO see previous TODO
            % c.useConfigurationFile = false;
            % c.build;
            % testCase.verifyClass(c,'openapi.build.Client');
            % testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));
        end

        function testModelsSupport(testCase)
            disp('Running testModelsSupport');
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['PetStore-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end
            c = openapi.build.Client;
            c.globalProperty = containers.Map({'models','supportingFiles'},{'', ''}); % Generate models and supporting files
            c.packageName = "Petstore";
            c.inputSpec = fullfile(testCase.fixturesPath, "Petstore_v3.yaml");
            c.output = fullfile(tmpFolder,"Petstore");
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));
        end

        function testUserPet(testCase)
            disp('Running testUserPet');
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['PetStore-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end
            c = openapi.build.Client;
            c.globalProperty = containers.Map({'models'},{"User:Pet"});      % Generate the User and Pet models only
            c.packageName = "Petstore";
            c.inputSpec = fullfile(testCase.fixturesPath, "Petstore_v3.yaml");
            c.output = fullfile(tmpFolder,"Petstore");
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));
        end

        function testskipFormModel(testCase)
            disp('Running testskipFormModel');
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['PetStore-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end
            c = openapi.build.Client;
            c.globalProperty = containers.Map({'skipFormModel'}, {"false"});    % Generate for OAS3 and ver < v5.x using the form parameters in "requestBody"
            c.packageName = "Petstore";
            c.inputSpec = fullfile(testCase.fixturesPath, "Petstore_v3.yaml");
            c.output = fullfile(tmpFolder,"Petstore");
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));
        end
    end
end