classdef (Abstract) GenerateSpec < matlab.unittest.TestCase
    properties (Abstract)
        packageName
    end
    properties(Access=private)
        packageLoc
    end
    methods
        function generate(testCase,name,snippet)
            arguments
                testCase
            end
            arguments (Repeating)
                name string
                snippet string
            end
            % GENERATE call at the start of a test to generate a spec and
            % client based on the spec
            specLoc = [tempname '.yaml'];
            f = fopen(specLoc,"w");
            fprintf(f,strjoin([...
                "openapi: 3.0.3"
                "info:"
                "  title: UnitTests"
                "  version: '1'"
                "servers:"
                "  - url: http://localhost:3000/"
                "paths:" 
                "  /" + name{1} + ":"
                "    post:"
                "      operationId: " + name{1} + ""
                "      tags: [Test]"
                "      requestBody:"
                "        required: true"
                "        content:"
                "          application/json:"
                "            schema:"
                "              $ref: '#/components/schemas/" + name{1} + "'"
                "      responses:"
                "         '200':"
                "           description: Success"
                "           content:"
                "             application/json:"
                "               schema:"
                "                 $ref: '#/components/schemas/" + name{1} + "'"
                "components:"
                "  schemas:"
            ],newline));
            for i = 1:length(name)
                fprintf(f,"\n    %s:\n",name{i});
                s = compose("      %s",snippet{i});
                fprintf(f,strjoin(s,newline));
            end
            fclose(f);
            spec = fileread(specLoc);
            fprintf('Generated spec for "%s":\n\n%s\n\nGenerating client:\n\n',name{1},spec);
            % Generate MATLAB Client from spec
            testCase.packageLoc = tempname;
            b = openapi.build.Client( ...
                "inputSpec",specLoc, ...
                "output",testCase.packageLoc, ...
                "packageName",testCase.packageName);
            b.build();
            % Delete spec
            delete(specLoc);
            addpath(testCase.packageLoc)
            testCase.addTeardown(@testCase.removepackage);
        end
            
        function removepackage(testCase)
            rmpath(testCase.packageLoc);
            rmdir(testCase.packageLoc,'s');
        end
    end
end