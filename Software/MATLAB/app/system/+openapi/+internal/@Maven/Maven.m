classdef Maven < openapi.build.Object
    % Maven Class to work with Maven.org Sontype searches
    
    %  (c) 2024 MathWorks, Inc.
    
    methods
        function obj = Maven()
        end
    end
    
    % Static Methods
    methods(Static)
        manifest = getMvnManifest(groupId, artifactId, options);
        md5Values = getMd5s(md5Urls);
    end
end