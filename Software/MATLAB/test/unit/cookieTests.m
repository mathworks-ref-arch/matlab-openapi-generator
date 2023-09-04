classdef (SharedTestFixtures={testServerFixture})  cookieTests < matlab.unittest.TestCase
    methods (Test)
        function testCookieJar(testCase)
            client = Test.api.Cookies;
            % Ensure cookie jar is empty
            client.cookies.purge;
            testCase.verifyTrue(~isfile(fullfile(client.cookies.path,'cookies.mat')));
            
            % Call the method which is supposed to fail without cookie
            code = client.cookiecheckCookie;
            testCase.verifyEqual(code,matlab.net.http.StatusCode.BadRequest);

            % Call the method which should set the cookie
            code = client.cookiegetCookie;
            testCase.verifyEqual(code,matlab.net.http.StatusCode.NoContent);

            % Verify cookies.mat was created
            testCase.verifyTrue(isfile(fullfile(client.cookies.path,'cookies.mat')));

            % Repeat the first call and ensure it succeeds now
            code = client.cookiecheckCookie;
            testCase.verifyEqual(code,matlab.net.http.StatusCode.OK);
        end
    end
end
