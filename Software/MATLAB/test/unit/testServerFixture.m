classdef testServerFixture < matlab.unittest.fixtures.Fixture
    properties
        clientDir
    end
    methods
        function setup(testCase)
            % Start the test server

            % CD to the server location
            org = cd(openapiRoot(-2,'Internal','example-server'));
            % CD back on error or when needed
            cc = onCleanup(@()cd(org));

            if ismac
                % npm likely to be in /usr/local/bin not standard PATH
                npmCmd = 'export PATH=$PATH:/usr/local/bin; npm';              
            else
                npmCmd = 'npm';
            end

            % First ensure node packages are installed
            cmdStr = [npmCmd, ' install'];
            [status, cmdOut] = system(cmdStr);
            if status ~= 0
                error('testServerFixture:npmCmd','npm install failed: %s', cmdOut);
            end

            % Then start in the background
            cmdStr = [npmCmd, ' run start&'];
            [status, cmdOut] = system(cmdStr);
            if status ~= 0
                error('testServerFixture:npmCmd','npm run start& failed: %s', cmdOut);
            end

            fprintf('Waiting for server to start...')
            % Verify that server has started before continuing
            for attempts=1:10
                % First wait a second
                pause(1);
                try
                    % Then attempt to call one of the end points
                    webread('http://localhost:3000/app');
                    % If this succeeds end the loop
                    break
                catch
                    % On error, do nothing, simply try again on the next
                    % iteration
                end
                fprintf('.');
            end
            % If the loop ran to full completion throw an error
            if attempts == 10
                error('Server failed to start');
            end
            fprintf('started\n');

            % Go back to original directory
            clear cc

            % Generate the client for the server
            testCase.clientDir = tempname;

            c = openapi.build.Client;
            c.packageName = "Test";
            c.inputSpec = "http://localhost:3000/api-yaml";
            c.output = fullfile(testCase.clientDir);
            c.copyrightNotice = "(c) 2023 The MathWorks Inc.";
            c.build;

            % Add generated client to MATLAB path
            addpath(testCase.clientDir)

        end


        function teardown(testCase)
            if ~isempty(testCase.clientDir)
                % Remove client from MATLAB path
                rmpath(testCase.clientDir);
                % Delete client from disk
                rmdir(testCase.clientDir,'s');
            end
            % Stop the test server
            try
                webread('http://localhost:3000/app/quit');
            catch
            end
        end
    end
end
