classdef ThirdPartySpecs < matlab.unittest.TestCase
    % ThirdPartySpecs Test the generator by passing a number of third party specs

    properties (Constant)
        fixturesPath = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'fixtures')
        release = matlabRelease
    end

    methods (TestClassSetup)
    end

    methods (Test)

        function testAirflow(testCase)
            disp('Running testAirflow');
            specPath = fullfile(testCase.fixturesPath, "ApacheAirflow_v1.yaml");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['Airflow-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end

            c = openapi.build.Client;
            testCase.verifyClass(c,'openapi.build.Client');
            c.packageName = "Airflow";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"Airflow");
            c.additionalArguments = "--skip-validate-spec";
            c.build;
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage);
        end

        function testDatabricksJobs(testCase)
            disp('Running testDatabricksJobs');
            specPath = fullfile(testCase.fixturesPath, "Databricks", "Jobs_v2_1.yaml");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', 'Databricks', ['Jobs-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end

            c = openapi.build.Client;
            c.packageName = "DatabricksJobs";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"DatabricksJobs");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage);
        end

        function testPetstore(testCase)
            disp('Running testPetstore');
            specPath = fullfile(testCase.fixturesPath, "Petstore_v3.yaml");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', ['PetStore-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end
            c = openapi.build.Client;
            c.packageName = "Petstore";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"Petstore");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage);
        end

        function testMlflowAws(testCase)
            disp('Running testMlflowAws');
            specPath = fullfile(testCase.fixturesPath, "mlflow", "mlflow-2.0-aws.yaml");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', 'mlflow', ['mlflowAws-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end

            c = openapi.build.Client;
            c.packageName = "mlflowAWS";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"mlflowAWS");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage);
        end

        function testMlflowAzure(testCase)
            disp('Running testMlflowAzure');
            specPath = fullfile(testCase.fixturesPath, "mlflow", "mlflow-2.0-azure.yaml");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', 'mlflow', ['mlflowAzure-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end

            c = openapi.build.Client;
            c.packageName = "mlflowAzure";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"mlflowAzure");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage);
        end

        function testMlflowGeneric(testCase)
            disp('Running testMlflowGeneric');
            specPath = fullfile(testCase.fixturesPath, "mlflow", "openapi.yml");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', 'mlflow', ['mlflowgeneric-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end

            c = openapi.build.Client;
            c.packageName = "mlflowGeneric";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"mlflowGeneric");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage);
        end

        function testDatabricksClusterPolicy(testCase)
            disp('Running testDatabricksClusterPolicy');
            specPath = fullfile(testCase.fixturesPath, "mlflow", "openapi.yml");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', 'Databricks', ['ClusterPolicy-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end

            c = openapi.build.Client;
            c.packageName = "databricks.ClusterPolicy";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"ClusterPolicy");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage);
        end

        function testRedis(testCase)
            disp('Running testRedis');
            specPath = fullfile(testCase.fixturesPath, "redis.json");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', 'Redis', ['Redis-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end

            c = openapi.build.Client;
            c.packageName = "RedisProAPI.Redis";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"Redis");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage);
        end

        function testJira(testCase)
            disp('Running testJira');
            specPath = fullfile(testCase.fixturesPath, "Jira-v3.json");
            if ~isfile(specPath)
                fprintf("File not found, skipping test: %s\n", specPath);
                return;
            end
            if strcmpi(getenv('OPENAPI_KEEP_OUTPUT'), 'true')
                tmpFolder = fullfile(tempdir, 'OpenAPITests', 'Redis', ['Redis-', char(datetime('now', 'Format','yyyyMMdd''T''HHmmss'))]);
                fprintf("Saving output to: %s\n", tmpFolder);
            else
                tmpFolder = createTemporaryFolder(testCase);
            end

            c = openapi.build.Client;
            c.packageName = "Jira";
            c.inputSpec = specPath;
            c.output = fullfile(tmpFolder,"Jira");
            c.additionalArguments = "--skip-validate-spec";
            c.build;

            testCase.verifyClass(c,'openapi.build.Client');
            testCase.verifyTrue(isfile(fullfile(c.output, [char(c.packageName),'_build.log'])));

            testCase.verifyTrue(c.verifyPackage('mode', 'nonStrict'));
        end
    end
end
