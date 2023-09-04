classdef myClass1 < JSONMapper
    properties
        d double
        f single
        i8 int8
        ui8 uint8
        i16 int16
        ui16 uint16
        i32 int32
        ui32 uint32
        i64 int64
        ui64 uint64
        l logical
        s string
        c char
        dtp datetime {JSONMapper.epochDatetime}
        dts datetime {JSONMapper.stringDatetime(dts,'yyyy-MM-dd')}
        m containers.Map
        mc myClass1
        e myEnum
    end
    methods
        function obj = myClass1(varargin)
            obj@JSONMapper(varargin{:});
        end
    end
end