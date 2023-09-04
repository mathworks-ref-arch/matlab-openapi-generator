classdef TestJSONMapper < matlab.unittest.TestCase
    methods(Test)
        function testEmpty(testCase)
            obj = myClass1;
            obj.fromJSON("{}");
        end
        function testParseScalar(testCase)
            obj = myClass1;
            obj.fromJSON(fileread('example1.json'));

            testCase.verifyEqual(obj.d, 1.797693134862315e+308)
            testCase.verifyEqual(obj.f, single(3.4028235e+38))
            testCase.verifyEqual(obj.i8, int8(127))
            testCase.verifyEqual(obj.ui8, uint8(255))
            testCase.verifyEqual(obj.i16, int16(32767))
            testCase.verifyEqual(obj.ui16, uint16(65535))
            testCase.verifyEqual(obj.i32, int32(2147483647))
            testCase.verifyEqual(obj.ui32, uint32(4294967295))
            testCase.verifyEqual(obj.i64, sscanf('9223372036854775805','%ld'))
            testCase.verifyEqual(obj.ui64, sscanf('18446744073709551614','%lu'))
            testCase.verifyEqual(obj.l, true)
            testCase.verifyEqual(obj.s, "I am a string")
            testCase.verifyEqual(obj.c, 'I am an array of char')
            testCase.verifyEqual(obj.dtp, datetime(1653993131,'ConvertFrom','posixtime'))
            testCase.verifyEqual(obj.dts, datetime("1984-01-01",'InputFormat','yyyy-MM-dd'))
            testCase.verifyEqual(obj.m, containers.Map({'a.b','e.f'},{'c.d','g.h'}))
            testCase.verifyEqual(obj.e, myEnum.VAL1)

        end

        function testParseArray(testCase)
            obj = myClass1;
            obj = obj.fromJSON(fileread('example2.json'));

            testCase.verifyEqual(obj(1).d, 1.797693134862315e+308)
            testCase.verifyEqual(obj(1).f, single(3.4028235e+38))
            testCase.verifyEqual(obj(1).i8, int8(127))
            testCase.verifyEqual(obj(1).ui8, uint8(255))
            testCase.verifyEqual(obj(1).i16, int16(32767))
            testCase.verifyEqual(obj(1).ui16, uint16(65535))
            testCase.verifyEqual(obj(1).i32, int32(2147483647))
            testCase.verifyEqual(obj(1).ui32, uint32(4294967295))
            testCase.verifyEqual(obj(1).i64, sscanf('9223372036854775807','%ld'))
            testCase.verifyEqual(obj(1).ui64, sscanf('18446744073709551615','%lu'))
            testCase.verifyEqual(obj(1).l, true)
            testCase.verifyEqual(obj(1).s, "I am a string")
            testCase.verifyEqual(obj(1).c, 'I am an array of char')
            testCase.verifyEqual(obj(1).dtp, datetime(1653993131,'ConvertFrom','posixtime'))
            testCase.verifyEqual(obj(1).dts, datetime("1984-01-01",'InputFormat','yyyy-MM-dd'))
            testCase.verifyEqual(obj(1).m, containers.Map({'a.b','e.f'},{'c.d','g.h'}))
            testCase.verifyEqual(obj(1).e, myEnum.VAL1)

            testCase.verifyEqual(obj(2).d, -2.225073858507201e-308)
            testCase.verifyEqual(obj(2).f, single(-1.1754944e-38))
            testCase.verifyEqual(obj(2).i8, int8(-128))
            testCase.verifyEqual(obj(2).ui8, uint8(0))
            testCase.verifyEqual(obj(2).i16, int16(-32768))
            testCase.verifyEqual(obj(2).ui16, uint16(0))
            testCase.verifyEqual(obj(2).i32, int32(-2147483648))
            testCase.verifyEqual(obj(2).ui32, uint32(0))
            testCase.verifyEqual(obj(2).i64, sscanf('-9223372036854775808','%ld'))
            testCase.verifyEqual(obj(2).ui64, sscanf('0','%lu'))
            testCase.verifyEqual(obj(2).l, false)
            testCase.verifyEqual(obj(2).s, "I am a string")
            testCase.verifyEqual(obj(2).c, 'I am an array of char')
            testCase.verifyEqual(obj(2).dtp, datetime(0,'ConvertFrom','posixtime'))
            testCase.verifyEqual(obj(2).dts, datetime("1900-01-01",'InputFormat','yyyy-MM-dd'))
            testCase.verifyEqual(obj(2).m, containers.Map({'a.b','e.f'},{'c.d','g.h'}))
            testCase.verifyEqual(obj(2).e, myEnum.VAL2)

        end

        function testNested(testCase)
            obj = myClass1;
            obj = obj.fromJSON(fileread('example3.json'));
            testCase.verifySize(obj,[1 2]);
            testCase.verifySize(obj(1).mc,[1 2]);
            testCase.verifySize(obj(2).mc,[1 1]);
        end

        function testArrayWithScalar(testCase)
            obj = myClass1;
            obj = obj.fromJSON(fileread('scalararrays.json'));
        end

        function testArrays(testCase)
            obj = myClass1;
            obj = obj.fromJSON(fileread('actualarray.json'));
        end
    end

end