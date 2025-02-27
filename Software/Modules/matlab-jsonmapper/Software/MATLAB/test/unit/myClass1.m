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
        m containers.Map %#ok<MCHDT>
        mc myClass1
        e myEnum
        j string {JSONMapper.doNotDecode}
    end
    methods
        function obj = myClass1(s,inputs)
            %obj@JSONMapper(varargin{:});
            arguments
                s {JSONMapper.ConstructorArgument} = []
                inputs.?myClass1
            end
            obj = obj.initialize(s,inputs);
        end
    end
end