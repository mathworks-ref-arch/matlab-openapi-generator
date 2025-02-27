classdef JSONDiscriminator < handle
    % JSONDISCRIMINATOR helper class used by JSONMapper
    
    % Copyright 2022-2023 The MathWorks, Inc.
    properties
        Value string
        Class string
    end
    methods
        function objs = JSONDiscriminator(Value,Class)
            if nargin==2
                N = length(Value);
                [objs(1:N).Value] = Value{:};
                [objs(1:N).Class] = Class{:};
            end
        end
    end
end