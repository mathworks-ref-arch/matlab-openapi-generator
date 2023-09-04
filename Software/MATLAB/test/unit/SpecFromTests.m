classdef (Abstract) SpecFromTests < matlab.unittest.TestCase
    properties
        packageLoc
        keepPackage = false
    end
    properties (Abstract)
        packageName
    end


    methods (TestClassSetup)
        function generate(testCase)
            % Generate an OpenAPI spec based on the types returned by the
            % test methods
            specLoc = [tempname '.yaml'];
            ml = metaclass(testCase);
            f = fopen(specLoc,"w");
            fprintf(f,strjoin([...
                "openapi: 3.0.3"
                "info:"
                "  title: UnitTests"
                "  version: '1'"
                "servers:"
                "  - url: http://localhost:3000/"
                "paths:" 
                "" ...
            ],newline));
            map = containers.Map;
            for m = ml.MethodList'
                if isprop(m,'Test') && m.Test
                    map(m.Name) = testCase.(m.Name);
                    fprintf(f, strjoin([...
                      "  /" + m.Name + ":"
                      "    post:"
                      "      operationId: " + m.Name + ""
                      "      tags: [Test]"
                      "      requestBody:"
                      "        required: true"
                      "        content:"
                      "          application/json:"
                      "            schema:"
                      "              $ref: '#/components/schemas/" + m.Name + "'"
                      "      responses:"
                      "         '200':"
                      "           description: Success"
                      "           content:"
                      "             application/json:"
                      "               schema:"
                      "                 $ref: '#/components/schemas/" + m.Name + "'"
                      "" ...
                  ],newline));
                end
            end
            fprintf(f, strjoin([...
                "components:"
                "  schemas:"
                "" ...
            ],newline));            
            for name = string(map.keys)
                fprintf(f, strjoin([...
                    "    " + name + ":" 
                    "" ...
                ],newline));            
                snippet = compose("      %s",map(name));
                fprintf(f,strjoin(snippet,newline));
                fprintf(f,'\n');
            end
            fclose(f);
            spec = fileread(specLoc);
            disp(spec)
            % Generate MATLAB Client from spec
            if isempty(testCase.packageLoc)
                testCase.packageLoc = tempname;
            end
            b = openapi.build.Client( ...
                "inputSpec",specLoc, ...
                "output",testCase.packageLoc, ...
                "packageName",testCase.packageName);
            b.build();
            delete(specLoc);
            addpath(testCase.packageLoc)
        end
            
    end
    methods (TestClassTeardown)
        function removepackage(testCase)
            if ~testCase.keepPackage
                rmpath(testCase.packageLoc);
                rmdir(testCase.packageLoc,'s');
            end
        end
    end
end