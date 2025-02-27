function apiDocPath = createRefAPIDoc(obj)
    arguments
        obj (1,1) openapi.auto.Project
    end

    apiDocPath = string.empty;

    if exist("api.Doc", "class") ~= 8
        if isfield(obj.settings, "apiDocGeneratorPath") &&...
            (ischar(obj.settings.apiDocGeneratorPath) || isStringScalar(obj.settings.apiDocGeneratorPath)) &&...
            strlength(obj.settings.apiDocGeneratorPath) > 0
            apiDocGeneratorPath = obj.settings.apiDocGeneratorPath;
            if isfolder(apiDocGeneratorPath)
                addpath(fullfile(apiDocGeneratorPath, "Software", "MATLAB", "app", "system"))
            else
                fprintf(2, "API reference documentation not found, see: %s\n",...
                    "https://insidelabs-git.mathworks.com/EI-DTST/Utilities/api-markdown-doc-generator");
                return;
            end
        else
            fprintf(2, "Valid apiDocGeneratorPath field not found in settings file\n");
            return;
        end
    end

    %try
        addpath(fullfile(obj.path, "Software", "MATLAB", "app", "system"));
        addpath(fullfile(obj.path, "Software", "MATLAB", "app", "functions"));
        d = api.Doc(Title=obj.projectFullName);
        d.Header = "This project was automatically generated based on an OpenAPI spec.";
        d.addNamespace(obj.projectNamespace);
        d.addFunction(obj.projectNamespace + "Root.m");
        if isfield(obj.settings, "copyrightNotice")
            d.CopyrightStart = int32(year(datetime("now")));
            d.CopyrightText = obj.settings.copyrightNotice;
        end
        d.OutputFile = fullfile(obj.path, "Documentation", "APIReference.md");
        str = d.build; %#ok<NASGU>
        d.save;
        apiDocPath =  d.OutputFile;
   % catch ME
    %    fprintf(2, "API reference documentation generation failed\nMessage: %s", ME.message);
   % end
end