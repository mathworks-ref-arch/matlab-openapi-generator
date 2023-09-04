classdef (SharedTestFixtures={testServerFixture}) staticTests < matlab.unittest.TestCase

    properties (Constant)
        release = matlabRelease
    end

    methods (Test)

        function verifyGeneratedCode(testCase)
            % Run
            % verifyPackage
            [tf, out] = openapi.verifyPackage(fileparts(fileparts(fileparts(which("Test.api.App")))));
            % Verify it tested anything at all
            testCase.verifyNotEmpty(out);
            testCase.verifyTrue(tf);
        end

        function testAppApi(testCase)
            m = ?Test.api.App;
            % Verify that all expected methods exist
            testCase.verifyThat(m,HasMethods([
                "appchooseMessage"
                "appchooseTwoMessages"
                "appechoMessage"
                "appgetHello"
                "appgetMessage"
                "apppathChooseMessage"
                "apppathMessage"
                ]));
        end
        function testNameTestsApi(testCase)
            m = ?Test.api.Api123NameTests;
            % Verify that all expected methods exist
            testCase.verifyThat(m,HasMethods([
                "nameTestsgetNameTestMessage"
                "nameTestspathTest"
                "nameTestspostNameTestMessage"
                "nameTestsqueryTest"
                ]));
        end
        function testIntegersApi(testCase)
            m = ?Test.api.Integers;
            % Verify that all expected methods exist
            testCase.verifyThat(m,HasMethods([
                "intTestgetNameTestMessage"
                ])); %#ok<NBRAK2>
        end

        function testHelloMessageModel(testCase)
            m = ?Test.models.HelloMessage;

            % Verify that class has expected properties of the expected type
            testCase.verifyThat(m,HasPropertyOfType("message",?string));
            testCase.verifyThat(m,HasPropertyOfType("timestamp",?datetime));
            testCase.verifyThat(m,HasPropertyOfType("nestedtest",?Test.models.NameTestMessage));
        end

        function testIntegerMessageModel(testCase)
            m = ?Test.models.IntegerMessage;

            % Verify that class has expected properties of the expected type
            testCase.verifyThat(m,HasPropertyOfType("i64",?int64));
            testCase.verifyThat(m,HasPropertyOfType("u64",?uint64));
            testCase.verifyThat(m,HasPropertyOfType("b",?logical));
        end

        function testModel123EnumModel(testCase)
            % Verify enum to JSON mapping
            testCase.verifyEqual(Test.models.Model123Enum.x789.JSONValue,"789");
            testCase.verifyEqual(Test.models.Model123Enum.ABC.JSONValue,"ABC");
            % Verify JSON to enum mapping
            testCase.verifyEqual(Test.models.Model123Enum.empty.fromJSON("789"),Test.models.Model123Enum.x789);
            testCase.verifyEqual(Test.models.Model123Enum.empty.fromJSON("ABC"),Test.models.Model123Enum.ABC);
        end
    end
end


