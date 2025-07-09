package com.mathworks.codegen;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.openapitools.codegen.CliOption;
import org.openapitools.codegen.CodegenConstants;
import org.openapitools.codegen.CodegenOperation;
import org.openapitools.codegen.CodegenParameter;
import org.openapitools.codegen.CodegenSecurity;
import org.openapitools.codegen.CodegenType;
import org.openapitools.codegen.SupportingFile;
import org.openapitools.codegen.model.ModelMap;
import org.openapitools.codegen.model.OperationMap;
import org.openapitools.codegen.model.OperationsMap;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.swagger.v3.oas.models.security.OAuthFlow;
import io.swagger.v3.oas.models.security.OAuthFlows;
import io.swagger.v3.oas.models.security.Scopes;
import io.swagger.v3.oas.models.security.SecurityScheme;

// Copyright 2022-2025 The MathWorks, Inc.

public class MATLABClientCodegen extends MATLABCodegen {

  private final Logger LOGGER = LoggerFactory.getLogger(MATLABClientCodegen.class);
  
  String ADD_AUTH = "AddOAuth";
  String OBJECT_PARAMS = "ObjectParams";

  // source folder where to write the files
  protected String sourceFolder = "src";
  protected String apiVersion = "1.0.0";


  // doc folders, don't clash with 'Documentation' as used by Support Package
  // baseline
  protected String apiDocPath = "docs" + File.separatorChar;
  protected String modelDocPath = "docs" + File.separatorChar;

  /**
   * Configures the type of generator.
   *
   * @return the CodegenType for this generator
   * @see io.swagger.codegen.CodegenType
   */
  @Override
  public CodegenType getTag() {
    return CodegenType.CLIENT;
  }

  /**
   * Configures a friendly name for the generator. This will be used by the
   * generator
   * to select the library with the -l flag.
   *
   * @return the friendly name for the generator
   */
  @Override
  public String getName() {
    return "matlab-client";
  }

  /**
   * Returns human-friendly help for the generator. Provide the consumer with help
   * tips, parameters here
   *
   * @return A string value for the help message
   */
  @Override
  public String getHelp() {
    return "Generates a MATLAB client library.";
  }

  List<CodegenParameter> objectParams = new ArrayList<CodegenParameter>();
  @Override
  public void postProcessParameter(CodegenParameter parameter) {
    for (CodegenParameter p : objectParams) {
      if (p.paramName.equals(parameter.paramName)) {
        parameter.vendorExtensions.put("x-is-object-param", true);
      }
    }
  }

  @Override
  public OperationsMap postProcessOperationsWithModels(OperationsMap objs, List<ModelMap> allModels) {
    this.additionalProperties.put("x-error-identifier", packageName.replace(".", ":"));

    // If ADD_AUTH is specified, do add this auth method to all operations
    CodegenSecurity cgs = null;
    if (additionalProperties.containsKey(ADD_AUTH)) {
      cgs = new CodegenSecurity();
      cgs.name = (String) additionalProperties.get(ADD_AUTH);
    }
    // Go through all operations
    OperationMap operations = objs.getOperations();
    List<CodegenOperation> operationList = operations.getOperation();
    for (CodegenOperation op : operationList) {
      // And add a customized x-error-identifier value, used in errors and warnings
      op.vendorExtensions.put("x-error-identifier", (apiPackage + "." + op.operationId).replace(".", ":"));
      // If ADD_AUTH is specified, do add this auth method to all operation
      // Just add it once though, the first time postProcessOperationsWithModels is
      // called.
      if (cgs != null && op.authMethods == null) {
        op.authMethods = new ArrayList<CodegenSecurity>();
        op.authMethods.add(cgs);
      }
    }
    return objs;
  }

  @Override
  public void processOpts() {
    super.processOpts();


    /* Handle Object Params */
    if (additionalProperties.containsKey(OBJECT_PARAMS)) {
      String paramString = (String) additionalProperties.get(OBJECT_PARAMS);
      String[] params = paramString.split("\\/");
      for (int i = 0; i < params.length; i++) {
        CodegenParameter cp = new CodegenParameter();
        cp.paramName = params[i++];
        cp.baseType = params[i];
        objectParams.add(cp);
      }
      if (!objectParams.isEmpty()) {
        additionalProperties.put("objectParams", objectParams);
      }
    }

    /**
     * Supporting Files. You can write single files for the generator with the
     * entire object tree available. If the input file has a suffix of `.mustache
     * it will be processed by the template engine. Otherwise, it will be copied
     */
    // Defined here rather than in MATLABClientCodegenGenerator so that packageName
    // is usable


    // Add BaseClient.m which is generated from mustache template
    supportingFiles.add(new SupportingFile("Client.mustache",
        fullfile(outputPackageRoot, "BaseClient.m")));

    // Add CookieJar.m as is
    supportingFiles.add(new SupportingFile(
        fullfile(openapiRoot, "app", "system", "CookieJar.m"),
        fullfile(outputPackageRoot, "CookieJar.m")));
    // Set cookiejarPackage which can be used in mustache templates to determine in
    // which package it was placed
    additionalProperties.put("cookiejarPackage", packageName);

    modelPackage = packageName + "." + modelPackage;
    apiPackage = packageName + "." + apiPackage;
  }

  @Override
  public List<CodegenSecurity> fromSecurity(Map<String, SecurityScheme> securitySchemeMap) {
    // If ADD_AUTH is specified do add this method to the security scheme map
    // Add it as an OAuth 2.0 method to ensure getOAuthToken is generated as well
    if (additionalProperties.containsKey(ADD_AUTH)) {
      String name = additionalProperties.get(ADD_AUTH).toString();
      SecurityScheme s = new SecurityScheme();
      s.setName(name);
      s.setType(SecurityScheme.Type.OAUTH2);
      OAuthFlows fs = new OAuthFlows();
      OAuthFlow f = new OAuthFlow();
      f.setAuthorizationUrl("http://example.com");
      f.setTokenUrl("https://example.com");
      f.setScopes(new Scopes().addString("example", "example"));
      fs.setAuthorizationCode(f);
      s.setFlows(fs);
      if (securitySchemeMap == null) {
        securitySchemeMap = new HashMap<String, SecurityScheme>();
      }
      securitySchemeMap.put(name, s);
    }
    List<CodegenSecurity> list = super.fromSecurity(securitySchemeMap);
    return list;
  }


  public MATLABClientCodegen() {
    super();

    // set the folder here
    // assumes execution is relative to the Software folder
    // points to an Output folder at the same level as Software
    // i.e. one level up from execution directory

    // String pathPWD = java.lang.System.getProperty("user.dir");
    // File parent = new File(pathPWD);
    // String parentPath = parent.getParent();

    // set the output folder here
    outputFolder = "Output";


    /**
     * Models. You can write model files using the modelTemplateFiles map.
     * if you want to create one template for file, you can do so here.
     * for multiple files for model, just put another entry in the
     * `modelTemplateFiles` with
     * a different extension
     */
    modelTemplateFiles.put(
        "model.mustache", // the template to use
        ".m"); // the extension for each file to write

    /**
     * Api classes. You can write classes for each api file with the
     * apiTemplateFiles map.
     * as with models, add multiple entries with different extensions for multiple
     * files per
     * class
     */
    apiTemplateFiles.put(
        "api.mustache", // the template to use
        ".m"); // the extension for each file to write

    // /**
    // * Template Location. This is the location which templates will be read from.
    // The generator
    // * will use the resource stream to attempt to read the templates.
    // */
    // String pathPWD = java.lang.System.getProperty("user.dir");
    // File parent = new File(pathPWD);
    // templateDir = parent.getAbsolutePath() + File.separatorChar + "Mustache";

    /**
     * Api Package. Optional, if needed, this can be used in templates
     */
    apiPackage = "api";

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
        .defaultValue("OpenAPIClientPackage"));
    cliOptions.add(new CliOption(CodegenConstants.PACKAGE_VERSION, "MATLAB package version.")
        .defaultValue("3.0.0"));

    cliOptions.add(new CliOption("openapiRoot",
        "Location of Software/MATLAB directory"));

  }


  @Override
  public String apiDocFileFolder() {
    return outputFolder + File.separator + apiDocPath;
  }



  

}
