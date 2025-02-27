classdef Jars < openapi.build.Object
    % Jars Class to work with package's jar files
    
    %  (c) 2024 MathWorks, Inc.
    
    methods
        function obj = Jars()
        end
    end
    
    % Static Methods
    methods(Static)
        jarPath =downloadGeneratorJar(version, options);
    end
end