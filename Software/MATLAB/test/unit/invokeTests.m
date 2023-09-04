classdef (SharedTestFixtures={testServerFixture}) invokeTests < matlab.unittest.TestCase
    methods (Test)
        function testAppApi(testCase)
            client = Test.api.App;
            %% Verify appgetHello
            % Correct Response
            [c,r] = client.appgetHello;
            testCase.verifyEqual(c,matlab.net.http.StatusCode.OK)
            testCase.verifyClass(r,'Test.models.HelloMessage');

            %% Verify appechoMessage
            % Errors with incorrect inputs
            testCase.verifyError(@()client.appechoMessage(),'MATLAB:minrhs')
            testCase.verifyError(@()client.appechoMessage(Test.models.HelloMessage),'JSONMAPPER:ERROR')
            % Correct Response
            [c,r] = client.appechoMessage(Test.models.HelloMessage("message", "Hi"));
            testCase.verifyEqual(c,matlab.net.http.StatusCode.OK)
            testCase.verifyClass(r,'Test.models.HelloMessage');
        end

        function testNameTestsApi(testCase)
            client = Test.api.Api123NameTests; %#ok<NASGU>
        end

        function testIntegersApi(testCase)
            client = Test.api.Integers;
            [c,r] = client.intTestgetNameTestMessage();
            testCase.verifyEqual(c,matlab.net.http.StatusCode.OK)
            testCase.verifyClass(r,'Test.models.IntegerMessage');

            testCase.verifyEqual(r.i64,int64(9223372036854775805));
            testCase.verifyEqual(r.u64,uint64(18446744073709551614));
            testCase.verifyEqual(r.b,true);
        end
    end
end
