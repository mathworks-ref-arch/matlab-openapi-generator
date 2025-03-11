classdef testSemVer < matlab.unittest.TestCase
    % TESTSEMVER Unit tests for the Semantic Version Class

    %                 (c) 2022-2025 MathWorks, Inc.

    properties (TestParameter)
        lowA = {'0.0.0', '1.1.0', '1.2.2'}
        middleA = {'1.2.3', '1.2.4', '1.6.2'}
        highA = {'1.6.3', '1.8.9', '2.0.0'}
    end

    properties
        classname = "openapi.internal.SemVer"
    end

    methods (TestMethodSetup)
        function testSetup(testCase)      %#ok<*MANU>
        end
    end

    methods (TestMethodTeardown)
        function testTearDown(testCase)
        end
    end

    methods (Test)
        function testConstructor(testCase)
            disp('Running testConstructor');
            
            v = eval(testCase.classname + "()");
            testCase.verifyClass(v, testCase.classname);
            testCase.verifyEqual(v.major, int32(0));
            testCase.verifyEqual(v.minor, int32(0));
            testCase.verifyEqual(v.patch, int32(0));

            v = eval(testCase.classname + "('1.2.3')");
            testCase.verifyEqual(v.major, int32(1));
            testCase.verifyEqual(v.minor, int32(2));
            testCase.verifyEqual(v.patch, int32(3));

            v = eval(testCase.classname + "('1.2.3')");
            testCase.verifyEqual(v.major, int32(1));
            testCase.verifyEqual(v.minor, int32(2));
            testCase.verifyEqual(v.patch, int32(3));

            v = eval(testCase.classname + "('1.2.3')");
            testCase.verifyEqual(v.major, int32(1));
            testCase.verifyEqual(v.minor, int32(2));
            testCase.verifyEqual(v.patch, int32(3));
        end


        function testInRange(testCase, lowA, middleA, highA) %#ok<INUSD>
            disp('Running testInRange');
             middle = eval(testCase.classname + "(middleA)");
            low = eval(testCase.classname + "(lowA)");
            high = eval(testCase.classname + "(highA)");

            testCase.verifyTrue(middle.inRange(middle, middle));
            testCase.verifyTrue(middle.inRange(low, high));
            testCase.verifyTrue(middle.inRange(low, middle));
            testCase.verifyTrue(middle.inRange(middle, high));

            testCase.verifyFalse(middle.inRange(high, high));
            testCase.verifyFalse(middle.inRange(low, low));
        end


        function testEqLtLeGtGe(testCase, lowA, middleA, highA) %#ok<INUSD>
            disp('Running testEqLtLeGtGe');
            middle = eval(testCase.classname + "(middleA)");
            low = eval(testCase.classname + "(lowA)");
            high = eval(testCase.classname + "(highA)");

            testCase.verifyTrue(middle.eq(middle));
            testCase.verifyFalse(middle.eq(low));
            testCase.verifyFalse(middle.eq(high));

            testCase.verifyTrue(middle.lt(high));
            testCase.verifyFalse(middle.lt(middle));
            testCase.verifyFalse(middle.lt(low));

            testCase.verifyTrue(middle.le(high));
            testCase.verifyTrue(middle.le(middle));
            testCase.verifyFalse(middle.le(low));

            testCase.verifyFalse(middle.gt(high));
            testCase.verifyFalse(middle.gt(middle));
            testCase.verifyTrue(middle.gt(low));

            testCase.verifyFalse(middle.ge(high));
            testCase.verifyTrue(middle.ge(middle));
            testCase.verifyTrue(middle.ge(low));
        end


        function testToString(testCase)
            disp('Running testToString');
            v = eval(testCase.classname + "('1.2.3')");
            testCase.verifyEqual(v.toString, "1.2.3")
        end


        function testCompare(testCase, lowA, middleA, highA) %#ok<INUSD>
            disp('Running testCompare');
            middle = eval(testCase.classname + "(middleA)"); %#ok<NASGU>
            low = eval(testCase.classname + "(lowA)"); %#ok<NASGU>
            high = eval(testCase.classname + "(highA)"); %#ok<NASGU>

            testCase.verifyEqual(eval(testCase.classname + ".compareVersions(low, low)"), 0);
            testCase.verifyEqual(eval(testCase.classname + ".compareVersions(middle, low)"), 1);
            testCase.verifyEqual(eval(testCase.classname + ".compareVersions(low, middle)"), -1);

            testCase.verifyEqual(eval(testCase.classname + ".compareAlpha(low, low)"), 'eq');
            testCase.verifyEqual(eval(testCase.classname + ".compareAlpha(middle, low)"), 'gt');
            testCase.verifyEqual(eval(testCase.classname + ".compareAlpha(low, middle)"), 'lt');
        end

        function testSort(testCase)
            disp('Running testSort');
            rawData = ["3.4.6", "1.1.1", "5.6.7", "1.1.1", "0.0.0", "1.1.0", "1.2.2"]; %#ok<NASGU>
            dscData = ["5.6.7", "3.4.6", "1.2.2", "1.1.1", "1.1.1", "1.1.0", "0.0.0"]; %#ok<NASGU>
            ascData = ["0.0.0", "1.1.0", "1.1.1", "1.1.1", "1.2.2", "3.4.6", "5.6.7"]; %#ok<NASGU>
            rawSv = eval(testCase.classname + "(rawData)");
            dscSv = eval(testCase.classname + "(dscData)");
            ascSv = eval(testCase.classname + "(ascData)");

            dscResult = eval(testCase.classname +".sort(rawSv, 'descending')");
            for n = 1:numel(rawSv)
                testCase.verifyTrue(dscResult(n).eq(dscSv(n)));
            end

            ascResult = eval(testCase.classname +".sort(rawSv, 'ascending')");
            for n = 1:numel(rawSv)
                testCase.verifyTrue(ascResult(n).eq(ascSv(n)));
            end

            ascResult = eval(testCase.classname +".sort(rawSv)");
            for n = 1:numel(rawSv)
                testCase.verifyTrue(ascResult(n).eq(ascSv(n)));
            end
        end

        function testSemverorgVals1(testCase)
            strs = ["1.0.0-alpha", "1.0.0-alpha.1", "1.0.0-0.3.7", "1.0.0-x.7.z.92", "1.0.0-x-y-z.--."];
            for n = 1:numel(strs)
                v = eval(testCase.classname +"(strs(n))");
                testCase.verifyEqual(v.toString, strs(n));
            end
        end

        function testSemverorgVals2(testCase)
            strs = ["1.0.0-alpha+001", "1.0.0+20130313144700", "1.0.0-beta+exp.sha.5114f85", "1.0.0+21AF26D3----117B344092BD"];
            for n = 1:numel(strs)
                v = eval(testCase.classname +"(strs(n))");
                testCase.verifyEqual(v.toString, strs(n));
            end
        end

        function testOrder1(testCase)
            % 1.0.0 < 2.0.0 < 2.1.0 < 2.1.1
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0', '2.0.0')"), -1);
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('2.0.0', '2.1.0')"), -1);
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('2.1.0', '2.1.1')"), -1);
            % 1.0.0-alpha < 1.0.0.
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0-alpha', '1.0.0')"), -1);
            % 1.0.0-alpha < 1.0.0-alpha.1 < 1.0.0-alpha.beta < 1.0.0-beta < 1.0.0-beta.2 < 1.0.0-beta.11 < 1.0.0-rc.1 < 1.0.0.
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0-alpha', '1.0.0-alpha.1')"), -1);
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0-alpha.1', '1.0.0-alpha.beta')"), -1);
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0-alpha.beta', '1.0.0-beta')"), -1);
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0-beta', '1.0.0-beta.2')"), -1);
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0-beta.2', '1.0.0-beta.11')"), -1);
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0-beta.11', '1.0.0-rc.1')"), -1);
            testCase.verifyEqual(eval(testCase.classname +".compareVersions('1.0.0-rc.1', '1.0.0')"), -1);
        end


        function testOrder2(testCase)
            testCase.verifyEqual(eval(testCase.classname +".compareAlpha('1.0.0-alpha+001', '1.0.0-alpha+001')"), 'eq');
            testCase.verifyEqual(eval(testCase.classname +".compareAlpha('1.0.0-alpha+001', '1.0.0+20130313144700')"), 'lt');
            testCase.verifyEqual(eval(testCase.classname +".compareAlpha('1.0.0+20130313144700', '1.0.0-alpha+001')"), 'gt');
            testCase.verifyEqual(eval(testCase.classname +".compareAlpha('1.0.0-alpha+001', '1.0.0-beta+exp.sha.5114f85')"), 'lt');
            testCase.verifyEqual(eval(testCase.classname +".compareAlpha('1.0.0-alpha+001', '1.0.0+21AF26D3----117B344092BD')"), 'lt');
            testCase.verifyEqual(eval(testCase.classname +".compareAlpha('1.0.0+20130313144700', '1.0.0+21AF26D3----117B344092BD')"), 'eq');
        end


         function testOpOver(testCase)
            x = eval(testCase.classname +"('1.2.3')");
            y = eval(testCase.classname +"('1.2.4')");
            
            testCase.verifyEqual(x > y , false);
            testCase.verifyEqual(x == y , false);
            testCase.verifyEqual(x ~= y , true);
            testCase.verifyEqual(x >= y , false);
            testCase.verifyEqual(x <= y , true);
            testCase.verifyEqual(x < y , true);
        end
    end
end
