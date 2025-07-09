package com.mathworks.codegen;

import org.apache.commons.io.FileUtils;
import org.openapitools.codegen.*;
import org.openapitools.codegen.model.ModelMap;
import org.openapitools.codegen.model.OperationMap;
import org.openapitools.codegen.model.OperationsMap;

import java.io.File;
import java.io.IOException;
import java.util.*;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class MatlabServerCodegen extends MATLABCodegen {

    private final Logger LOGGER = LoggerFactory.getLogger(MatlabServerCodegen.class);

    public CodegenType getTag() {
        return CodegenType.SERVER;
    }

    public String getName() {
        return "matlab-server";
    }

    public String getHelp() {
        return "Generates a MATLAB server.";
    }

    public MatlabServerCodegen() {
        super();
        /*
         * outputFolder = "generated-code" + File.separator + "matlab-server";
         * modelTemplateFiles.put("model.mustache", ".zz");
         * apiTemplateFiles.put("api.mustache", ".zz");
         * embeddedTemplateDir = templateDir = "matlab-server";
         * apiPackage = "Apis";
         * modelPackage = "Models";
         * supportingFiles.add(new SupportingFile("README.mustache", "", "README.md"));
         */

        modelTemplateFiles.put(
                "model.mustache", // the template to use
                ".m"); // the extension for each file to write

        apiTemplateFiles.put(
                "api_server.mustache", // the template to use
                ".m"); // the extension for each file to write
        /**
         * Api Package. Optional, if needed, this can be used in templates
         */
        apiPackage = "impl";

        /**
         * Model Package. Optional, if needed, this can be used in templates
         */
        modelPackage = "models";

        // // default HIDE_GENERATION_TIMESTAMP to true
        // hideGenerationTimestamp = Boolean.TRUE;

        /**
         * Additional Properties. These values can be passed to the templates and
         * are available in models, apis, and supporting files
         */
        additionalProperties.put("apiVersion", packageVersion);

        cliOptions.clear();
        cliOptions.add(new CliOption(CodegenConstants.PACKAGE_NAME, "MATLAB Class Name Convention (+ not included)")
                .defaultValue("OpenAPIServerPackage"));
        cliOptions.add(new CliOption(CodegenConstants.PACKAGE_VERSION, "MATLAB package version.")
                .defaultValue("3.0.0"));

        cliOptions.add(new CliOption("openapiRoot",
                "Location of Software/MATLAB directory"));
    }

    @Override
    public void processOpts() {
        super.processOpts();
        additionalProperties.put("topLevelPackageName",packageName.split("\\.")[0]);

        // Add server.m which is generated from mustache template
        supportingFiles.add(new SupportingFile("server.mustache",
                fullfile("server.m")));
        // Add routes.json
        supportingFiles.add(new SupportingFile("routes.mustache",
                fullfile("routes.json")));
        // Include the spec itself as json and yaml
        supportingFiles.add(new SupportingFile("openapi.json.mustache",
                fullfile("openapi.json")));
        supportingFiles.add(new SupportingFile("openapi.yaml.mustache",
                fullfile("openapi.yaml")));                

        // Add buildfile.m which is generated from mustache template
        supportingFiles.add(new SupportingFile("server_buildfile.mustache",
            fullfile("buildfile.m")));


        // Add Web Framework files
        String jsonmapperRoot = fullfile(openapiRoot, "..", "Modules", "matlab-web-service", "Software", "MATLAB");
        supportingFiles.add(new SupportingFile(
                fullfile(jsonmapperRoot, "app", "sys", "+mws","Application.m"),
                fullfile(outputPackageRoot, "+mws", "Application.m")));
        supportingFiles.add(new SupportingFile(
            fullfile(jsonmapperRoot, "app", "sys", "+mws","Request.m"),
            fullfile(outputPackageRoot, "+mws", "Request.m")));
        supportingFiles.add(new SupportingFile(
                fullfile(jsonmapperRoot, "app", "sys", "+mws","Response.m"),
                fullfile(outputPackageRoot, "+mws", "Response.m")));
        supportingFiles.add(new SupportingFile(
                fullfile(jsonmapperRoot, "app", "sys", "+mws","Static.m"),
                fullfile(outputPackageRoot, "+mws", "Static.m")));

        modelPackage = packageName + "." + modelPackage;
        apiPackage = packageName + "." + apiPackage;
    }

    @Override
    public Map<String, Object> postProcessSupportingFileData(Map<String, Object> objs) {
        generateJSONSpecFile(objs);
        generateYAMLSpecFile(objs);
        return super.postProcessSupportingFileData(objs);
    }    

    @Override
    public void postProcessFile(File file, String fileType) {
        super.postProcessFile(file, fileType);
        // Inside the Web Framework helper files
        if ("supporting-file".equals(fileType) && file.getName().endsWith("m")) {
            String contents;
            try {
                // Replace mws.Application, etc. with packageName.mws.*
                contents = FileUtils.readFileToString(file, "UTF-8");
                java.util.regex.Pattern p = java.util.regex.Pattern.compile(
                        "mws.");
                java.util.regex.Matcher m = p.matcher(contents);
                contents = m.replaceAll(packageName + ".mws.");
                FileUtils.write(file, contents, "UTF-8");
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public OperationsMap postProcessOperationsWithModels(OperationsMap objs, List<ModelMap> allModels) {
        this.additionalProperties.put("x-error-identifier", packageName.replace(".", ":"));
        // Go through all operations
        OperationMap operations = objs.getOperations();
        List<CodegenOperation> operationList = operations.getOperation();
        for (CodegenOperation op : operationList) {
            // And add a customized x-error-identifier value, used in errors and warnings
            op.vendorExtensions.put("x-error-identifier", (apiPackage + "." + op.operationId).replace(".", ":"));
            if (op.httpMethod.toLowerCase().equals("delete")) {
                op.vendorExtensions.put("x-matlab-method", "del");
            } else {
                op.vendorExtensions.put("x-matlab-method", op.httpMethod.toLowerCase());
            }
        }
        return objs;
    }

}
