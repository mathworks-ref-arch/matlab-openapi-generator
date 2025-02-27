package com.mathworks.codegen;

import static org.openapitools.codegen.utils.StringUtils.camelize;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.openapitools.codegen.CliOption;
import org.openapitools.codegen.CodegenComposedSchemas;
import org.openapitools.codegen.CodegenConfig;
import org.openapitools.codegen.CodegenConstants;
import org.openapitools.codegen.CodegenModel;
import org.openapitools.codegen.CodegenOperation;
import org.openapitools.codegen.CodegenParameter;
import org.openapitools.codegen.CodegenProperty;
import org.openapitools.codegen.CodegenSecurity;
import org.openapitools.codegen.CodegenType;
import org.openapitools.codegen.DefaultCodegen;
import org.openapitools.codegen.SupportingFile;
import org.openapitools.codegen.model.ModelMap;
import org.openapitools.codegen.model.ModelsMap;
import org.openapitools.codegen.model.OperationMap;
import org.openapitools.codegen.model.OperationsMap;
import org.openapitools.codegen.utils.ModelUtils;

import io.swagger.v3.oas.models.media.Schema;
import io.swagger.v3.oas.models.security.OAuthFlow;
import io.swagger.v3.oas.models.security.OAuthFlows;
import io.swagger.v3.oas.models.security.Scopes;
import io.swagger.v3.oas.models.security.SecurityScheme;


// Copyright 2022-2023 The MathWorks, Inc.

public class MATLABClientCodegenGenerator extends DefaultCodegen implements CodegenConfig {
  String ADD_AUTH = "AddOAuth";
  String OBJECT_PARAMS = "ObjectParams";
  
  // source folder where to write the files
  protected String sourceFolder = "src";
  protected String apiVersion = "1.0.0";

  protected String packageName; // e.g. petstore_api
  protected String packageVersion;

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
  public String getName() {
    return "MATLAB";
  }

  private String ensureNotEmpty(String val) {
    if (val.isBlank()) {
      return "EMPTY_STRING";
    }
    return val;
  }


  private String[] supportedEnumNameExtensions = {"x-enumNames"};

  private Map<String, Object> sanitizeEnumValues(Map<String, Object> allowableValues, Map<String, Object> vendorExtensions) {
    // Add enum values as allowableValues
    ArrayList<Object> allEnumValues = new ArrayList<Object>();
    ArrayList<Object> vals = (ArrayList<Object>) allowableValues.get("values");
    ArrayList<String> nameList = null;
    for (String pn: supportedEnumNameExtensions) {
      if (vendorExtensions.containsKey(pn)) {
        nameList = (ArrayList<String>) vendorExtensions.get(pn);
        break;
      }
    }
    for (int i=0; i< vals.size(); i++) {
      HashMap<String, Object> enumVal = new HashMap<String, Object>();
      enumVal.put("baseName", vals.get(i));
      if (nameList!=null) {
        enumVal.put("name", ensureNotEmpty(toVarName(nameList.get(i))));
      } else {
        enumVal.put("name", ensureNotEmpty(toVarName(vals.get(i).toString())));
      }
      
      allEnumValues.add(enumVal);
    }
    return Collections.singletonMap("values", allEnumValues);
  }

  @Override
  public void postProcessModelProperty(CodegenModel model, CodegenProperty property) {
    super.postProcessModelProperty(model, property);
    // Not standard OpenAPI but extensively used in MS Azure specs
    if ("unixtime".equals(property.getDataFormat())) {
      property.vendorExtensions.put("x-isPosixTime",true);
    }
  }

  @Override
  public OperationsMap postProcessOperationsWithModels(OperationsMap objs, List<ModelMap> allModels) {
    this.additionalProperties.put("x-error-identifier", packageName.replace(".",":"));
    
    // If ADD_AUTH is specified, do add this auth method to all operations
    CodegenSecurity cgs = null;
    if (additionalProperties.containsKey(ADD_AUTH)) {
       cgs = new CodegenSecurity();
       cgs.name = (String)additionalProperties.get(ADD_AUTH);
    }
    // Go through all operations
    OperationMap operations = objs.getOperations();
    List<CodegenOperation> operationList = operations.getOperation();
    for (CodegenOperation op : operationList) {
      // And add a customized x-error-identifier value, used in errors and warnings
      op.vendorExtensions.put("x-error-identifier", (apiPackage + "." + op.operationId).replace(".", ":"));
      // If ADD_AUTH is specified, do add this auth method to all operation
      // Just add it once though, the first time postProcessOperationsWithModels is called.
      if (cgs != null && op.authMethods == null) {
        op.authMethods = new ArrayList<CodegenSecurity>();
        op.authMethods.add(cgs);
      }
    }
    return objs;
  }

  @Override
  public Map<String, ModelsMap> postProcessAllModels(Map<String, ModelsMap> objs) {
    // Call super
    Map<String, ModelsMap> models = super.postProcessAllModels(objs);

    // Pull out inline enums and turn into actual models and 
    // for OneOf check whether they are a oneOf primitives

    // Models to be added
    Map<String, ModelsMap> enumModels = new HashMap<String, ModelsMap>();
    // For all original models
    for (final String key : objs.keySet()) {
      // Get the model
      CodegenModel mo = ModelUtils.getModelByName(key, models);

      if (mo.isEnum) {
        // If the model is already an enum, just escape the names
        mo.setAllowableValues(sanitizeEnumValues(mo.allowableValues,mo.vendorExtensions));
      } else if (mo.hasVars) {
        // If the model is not an enum but has variables

        // Go through all variables
        for (CodegenProperty prop : mo.vars) {
          // If the variable is an enum
          if (prop.isEnum) {
            // Form an unique enum name based on the class and inline enum
            String newEnumName = truncateto63(mo.classname,prop.enumName);

            // Update the existing variable to refer to the newly generated enum
            prop.complexType = newEnumName;
            prop.isPrimitiveType = false;

            // Actually define a new model for the new enum
            ModelsMap mosMap = new ModelsMap();
            ModelMap moMap = new ModelMap();
            CodegenModel cgm = new CodegenModel();
              
            // Set the relevant properties
            // TODO investigate what else to set
            cgm.setName(newEnumName);
            cgm.isEnum = true;

            cgm.setAllowableValues(sanitizeEnumValues(prop.allowableValues,prop.vendorExtensions));

            cgm.setClassname(newEnumName);
            // Include all global additionalProperties (like jsonmapperPackage)
            moMap.putAll(additionalProperties);

            // Add to the model map
            moMap.setModel(cgm);
            mosMap.setModels(Collections.singletonList(moMap));
            enumModels.put(newEnumName, mosMap);
          }

          // For the oneOf check we want to check both properties which are oneOf directly as well
          // as properties which are an array of oneOfs
          if (prop.isArray) {
            prop = prop.items;
          }
          // If the property is indeed a oneOf
          if (prop.vendorExtensions.containsKey("x-one-of-name")) {
            // Get the Model which was generated for the OneOf
            CodegenModel oo = ModelUtils.getModelByName(prop.complexType, models);
            // And get the list of schemas of which it is composed
            CodegenComposedSchemas c = oo.getComposedSchemas();
            if (c != null) {
              List<CodegenProperty> l = c.getOneOf();
              // Check whether any is primitive or an array
              Boolean ip = false;
              for (CodegenProperty p: l) {
                ip = ip || p.isPrimitiveType || p.isArray;
              }
              // If so, add x-is-one-of-primitives tag
              if (ip) {
                prop.vendorExtensions.put("x-is-one-of-primitives", true);
              }
            }
          }
        }
      }
    }

    // Add all newly defined enum models
    models.putAll(enumModels);
    
    return models;

  }


  private String fullfile(CharSequence... elements) {
    return String.join(File.separator, elements);
  }

  /**
   * Returns human-friendly help for the generator. Provide the consumer with help
   * tips, parameters here
   *
   * @return A string value for the help message
   */
  public String getHelp() {
    return "Generates a MATLAB client library.";
  }


  List<CodegenParameter> objectParams = new ArrayList<CodegenParameter>();

  @Override
  public void processOpts() {
    super.processOpts();

    if (additionalProperties.containsKey(CodegenConstants.PACKAGE_NAME)) {
      setPackageName((String) additionalProperties.get(CodegenConstants.PACKAGE_NAME));
    } else {
      setPackageName("OpenAPIClientPackage");
    }
    additionalProperties.put(CodegenConstants.PACKAGE_NAME, packageName);

    if (additionalProperties.containsKey(CodegenConstants.PACKAGE_VERSION)) {
      setPackageVersion((String) additionalProperties.get(CodegenConstants.PACKAGE_VERSION));
    } else {
      setPackageVersion("1.0.0");
    }
    additionalProperties.put(CodegenConstants.PACKAGE_VERSION, packageVersion);

    if (additionalProperties.containsKey(CodegenConstants.TEMPLATE_DIR)) {
      setTemplateDir((String) additionalProperties.get(CodegenConstants.TEMPLATE_DIR));
    } else {
      String pathPWD = java.lang.System.getProperty("user.dir");
      File parent = new File(pathPWD);
      setTemplateDir(parent.getAbsolutePath() + File.separator + "Mustache");
    }
    additionalProperties.put(CodegenConstants.TEMPLATE_DIR, templateDir);

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
        additionalProperties.put("objectParams",objectParams);
      }
    }

    // Should only fall back to here if running from outside /Software or
    // /Software/Mustache is missing
    if (StringUtils.isBlank(templateDir)) {
      embeddedTemplateDir = templateDir = "defaultTemplateDirectory";
    }
    
    // Additional MATLAB files found relative to openapiRoot
    String openapiRoot;
    if (additionalProperties.containsKey("openapiRoot")) {
      openapiRoot = (String) additionalProperties.get("openapiRoot");
    } else {
      String pathPWD = java.lang.System.getProperty("user.dir");
      File parent = new File(pathPWD);
      openapiRoot = parent.getAbsolutePath() + File.separator + "MATLAB";
    }

    /**
     * Supporting Files. You can write single files for the generator with the
     * entire object tree available. If the input file has a suffix of `.mustache
     * it will be processed by the template engine. Otherwise, it will be copied
     */
    // Defined here rather than in MATLABClientCodegenGenerator so that packageName
    // is usable

    // Root output directory based on package name
    String outputPackageRoot = fullfile("+" + packageName.replace(".", File.separatorChar + "+"));

    // Add BaseClient.m which is generated from mustache template
    supportingFiles.add(new SupportingFile("Client.mustache",
      fullfile(outputPackageRoot, "BaseClient.m")));

    // Add FreeFormObject.m which is generated from mustache template
    supportingFiles.add(new SupportingFile("freeformobject.mustache",
      fullfile(outputPackageRoot, "+models","FreeFormObject.m")));

    // Add CookieJar.m as is
    supportingFiles.add(new SupportingFile(
      fullfile(openapiRoot , "app" , "system" , "CookieJar.m"), 
      fullfile(outputPackageRoot, "CookieJar.m")));
    // Set cookiejarPackage which can be used in mustache templates to determine in which package it was placed
    additionalProperties.put("cookiejarPackage",packageName);

    // Add JSONMapper files
    String jsonmapperRoot = fullfile(openapiRoot,"..","Modules","matlab-jsonmapper","Software","MATLAB");
    supportingFiles.add(new SupportingFile(
      fullfile(jsonmapperRoot , "app" , "system" , "JSONEnum.m"), 
      fullfile(outputPackageRoot, "JSONEnum.m")));
    supportingFiles.add(new SupportingFile(
      fullfile(jsonmapperRoot , "app" , "system" , "JSONMapper.m"), 
      fullfile(outputPackageRoot, "JSONMapper.m")));
    supportingFiles.add(new SupportingFile(
      fullfile(jsonmapperRoot , "app" , "system" , "JSONMapperMap.m"), 
      fullfile(outputPackageRoot, "JSONMapperMap.m")));
    supportingFiles.add(new SupportingFile(
      fullfile(jsonmapperRoot , "app" , "system" , "JSONDiscriminator.m"), 
      fullfile(outputPackageRoot, "JSONDiscriminator.m")));
    supportingFiles.add(new SupportingFile(
      fullfile(jsonmapperRoot , "app" , "system" , "JSONPropertyInfo.m"), 
      fullfile(outputPackageRoot, "JSONPropertyInfo.m")));
    // Set jsonmapperPackage which can be used in mustache templates to determine in which package it was placed
    additionalProperties.put("jsonmapperPackage",packageName);

    // Add a type mapping for JSONMapperMap *inside* package name
    typeMapping.put("map", packageName + ".JSONMapperMap");
    // Enable file postprocessing to allow replacing JSONMapper etc with packaged name
    setEnablePostProcessFile(true);

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
      if (securitySchemeMap==null) {
        securitySchemeMap = new HashMap<String,SecurityScheme>();
      }
      securitySchemeMap.put(name, s);
    }
    List<CodegenSecurity> list = super.fromSecurity(securitySchemeMap);
    return list;
  }

  @Override
  public void postProcessFile(File file, String fileType) {
    super.postProcessFile(file,fileType);
    // Inside the JSONMapper helper files
    if ("supporting-file".equals(fileType)) {
      String contents;
      try {
        // Replace JSONEnum|JSONMapper|JSONPropertyInfo with packaged names
        // (Except of course when in classdef definition or as constructor name)
        contents = FileUtils.readFileToString(file,"UTF-8");
        java.util.regex.Pattern p = java.util.regex.Pattern.compile("(?<!(classdef|function|error|warning).*)(JSONMapper|JSONPropertyInfo|JSONDiscriminator)");
        java.util.regex.Matcher m = p.matcher(contents);
        contents = m.replaceAll(additionalProperties.get("jsonmapperPackage") + ".$2");
        FileUtils.write(file,contents,"UTF-8");
      } catch (IOException e) {
        e.printStackTrace();
      }
      
    }
    
  }

  
  @Override
  public void postProcessParameter(CodegenParameter parameter) {
    for (CodegenParameter p: objectParams) {
      if (p.paramName.equals(parameter.paramName)) {
        parameter.vendorExtensions.put("x-is-object-param",true);
      }
    }
  }
  

  public List<SupportingFile> addSupportingFileDir(List<SupportingFile> supportingFiles, String srcDirPathStr,
      String dstDirPathStr) {

    Path path = Paths.get(srcDirPathStr);
    List<Path> filePathList;

    try (Stream<Path> walk = Files.walk(path)) {
      filePathList = walk.filter(Files::isRegularFile).collect(Collectors.toList());
      for (Path p : filePathList) {
        System.out.println(p.toString());
        supportingFiles
            .add(new SupportingFile(p.toAbsolutePath().toString(), dstDirPathStr, p.getFileName().toString()));
      }
    } catch (java.io.IOException e) {
      // Just throw for now
      System.err.println(e.toString());
    }
    return supportingFiles;
  }

  public void setTemplateDir() {
    String pathPWD = java.lang.System.getProperty("user.dir");
    File parent = new File(pathPWD);
    this.templateDir = parent.getAbsolutePath() + File.separator + "Mustache";
  }

  public void setTemplateDir(String templateDir) {
    this.templateDir = templateDir;
  }

  public MATLABClientCodegenGenerator() {
    super();

    legacyDiscriminatorBehavior = false;
    useOneOfInterfaces = true;
    supportsInheritance = true;

    // set the folder here
    // assumes execution is relative to the Software folder
    // points to an Output folder at the same level as Software
    // i.e. one level up from execution directory

    // String pathPWD = java.lang.System.getProperty("user.dir");
    // File parent = new File(pathPWD);
    // String parentPath = parent.getParent();

    // set the output folder here
    outputFolder = "Output";

    /*
     * Should not fall back to here as MATLAB Mustache files
     * do not ship as part of the codegen package
     */
    embeddedTemplateDir = "embeddedMustacheDirectory";

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
    setTemplateDir();

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

    // Reserved words. Reserved words specific to MATLAB
    // Output of iskeyword in MATLAB (R2023a)
    reservedWords = new HashSet<String>(
        Arrays.asList(
            "break", "case", "catch", "classdef", "continue", "else", "elseif", "end",
            "for", "function", "global", "if", "otherwise", "parfor", "persistent",
            "return", "spmd", "switch", "try", "while"));


    /**
     * Additional Properties. These values can be passed to the templates and
     * are available in models, apis, and supporting files
     */
    additionalProperties.put("apiVersion", packageVersion);

    /**
     * Language Specific Primitives. These types will not trigger imports by
     * the client generator
     */
    languageSpecificPrimitives = new HashSet<String>(
        Arrays.asList(
            "double", "single", "complex",
            "int8", "int16", "int32", "int64",
            "uint8", "uint16", "uint32", "uint64",
            "logical",
            "char", "string", "cellstr",
            "cell", "struct",
            "datetime", "duration",
            "timetable", "table",
            "categorical",
            "containers.Map",
            "timeseries"));

    typeMapping.clear();
    typeMapping.put("boolean", "logical");
    typeMapping.put("string", "string");
    typeMapping.put("integer", "int32");
    typeMapping.put("number", "double");
    typeMapping.put("number+float", "single");
    typeMapping.put("number+double", "double");
    typeMapping.put("long", "int64");
    typeMapping.put("DateTime", "datetime");
    typeMapping.put("date", "datetime");
    typeMapping.put("file", "string");
    typeMapping.put("UUID", "string");
    

    // Not standard OpenAPI but extensively used in MS Azure specs
    typeMapping.put("integer+unixtime", "datetime"); 

    cliOptions.clear();
    cliOptions.add(new CliOption(CodegenConstants.PACKAGE_NAME, "MATLAB Class Name Convention (+ not included)")
        .defaultValue("OpenAPIClientPackage"));
    cliOptions.add(new CliOption(CodegenConstants.PACKAGE_VERSION, "MATLAB package version.")
        .defaultValue("1.0.0"));

    cliOptions.add(new CliOption("openapiRoot",
            "Location of Software/MATLAB directory"));

  }

  public void setPackageName(String packageName) {
    this.packageName = packageName;
  }

  public void setPackageVersion(String packageVersion) {
    this.packageVersion = packageVersion;
  }

  @Override
  public String apiDocFileFolder() {
    return outputFolder + File.separator + apiDocPath;
  }

  /**
   * Escapes a reserved word as defined in the `reservedWords` array. Handle
   * escaping
   * those terms here. This logic is only called if a variable matches the
   * reserved words
   *
   * @return the escaped term
   */
  @Override
  public String escapeReservedWord(String name) {
    if (this.reservedWordsMappings().containsKey(name)) {
      return this.reservedWordsMappings().get(name);
    }
    return "x" + name; // add an x to the name
  }

  /**
   * Location to write model files. You can use the modelPackage() as defined when
   * the class is
   * instantiated
   */
  public String modelFileFolder() {
    return outputFolder + File.separatorChar + "+" + modelPackage().replace(".", File.separatorChar + "+");
  }

  /**
   * Location to write api files. You can use the apiPackage() as defined when the
   * class is
   * instantiated
   */
  @Override
  public String apiFileFolder() {
    return outputFolder + File.separatorChar + "+" + apiPackage().replace(".", File.separatorChar + "+");
  }

  @Override
  public String getSchemaType(Schema p) {
    String openAPIType = super.getSchemaType(p);
    String type = null;
    if (typeMapping.containsKey(openAPIType)) {
      type = typeMapping.get(openAPIType);
      if (languageSpecificPrimitives.contains(type)) {
        return type;
      }
    } else {
      type = toModelName(openAPIType);
    }
    return type;
  }

  @Override
  public String toModelFilename(String name) {
    return toModelName(name);
  }

  
  private HashMap<String,String> truncatedNames = new HashMap<String,String>();
  /**
   * Truncates names to 63 characters, the maximum length for variable, function
   * and class names in MATLAB. As this method may get called multiple times for
   * a given name, it tracks previously truncated names in a HashMap and ensures
   * the same name it returned each time. 
   * @param name input name
   * @return truncated name
   */
  private String truncateto63(String name) {
    return truncateto63(name,"");
  }
  
  private String truncateto63(String name, String suffix) {
    int suffixLen = suffix.length();
    // If shorter than 64 characters just return as is
    if (name.length() + suffixLen < 64) {
      return name + suffix;
    }

    // If truncated before, return the previously determined name
    if (truncatedNames.containsKey(name + suffix)) {
      return truncatedNames.get(name + suffix);
    }
    // If first time, append truncate and append _0000 to the name
    int counter = 0;  
    String newName = name.substring(0,58 - suffixLen ) + suffix + "_" + String.format("%04d", counter++);
    // Verify that this is unique and not used before for another name with the same prefix
    while (truncatedNames.containsValue(newName)) {
      // Keep increasing the counter until a unique name is formed
      newName = name.substring(0,58 - suffixLen ) + suffix + "_" + String.format("%04d", counter++);
    }
    // Store the new truncated name in the hashmap
    truncatedNames.put(name + suffix,newName);
    // Return the new truncated name
    return newName;
  }

  @Override
  public String toModelName(String name) {
    String origName = name;

    // sanitize name for Java
    name = sanitizeName(name);
    // remove dollar sign
    name = name.replaceAll("$", "");

    // model name cannot use reserved keyword, e.g. return
    if (isReservedWord(name)) {
      System.out.println(
          "Warning: Cannot use reserved word as model name: " + name + " renaming to: " + camelize("model" + name));
      name = camelize("model" + name); // e.g. return => ModelReturn (after camelize)
    }

    // model name starts with number
    if (name.matches("^\\d.*")) {
      System.out.println(
          "Warning: Model name cannot start with a number: " + name + " renaming to: " + camelize("model" + name));
      name = camelize("model" + name); // e.g. 200Response => Model200Response (after camelize)
    }

    // if model name starts with underscore prefix with x
    if (name.matches("^\\_.*")) {
      name = "x" + name;
    }    

    // remove any hypens from names, replace with underscores
    if (name.contains("-")) {
      System.out.println("Warning: Model name cannot contain - : " + name + " replacing with _");
      name.replaceAll("-", "_");
    }

    // if (!name.equals(origName)) {
    //   System.out.println("Warning: Model name changed from: " + origName + " to: " + name);
    // }

    name = truncateto63(name);

    return name;
  }

  @Override
  public String toParamName(String name) {
    String origName = name;

    // sanitize name for Java
    name = sanitizeName(name);

    // remove dollar sign
    name = name.replaceAll("$", "");

    // remove any hypens from names, replace with underscores
    if (name.matches("-")) {
      name.replaceAll("-", "_");
    }

    // if model name starts with number prefix with x
    if (name.matches("^\\d.*")) {
      name = "x" + name;
    }

    // if model name starts with underscore prefix with x
    if (name.matches("^\\_.*")) {
      name = "x" + name;
    }

    // for reserved word or prefix with _
    if (isReservedWord(name)) {
      name = "x" + name;
    }

    if (!name.matches(origName)) {
      System.out.println("Warning: Variable name changed from: " + origName + " to: " + name);
    }
    
    name = truncateto63(name);
    
    return name;
  }

  // In addition, words which are not valid property names
  HashSet<String> reservedVarWords = new HashSet<String>(
    Arrays.asList(
        "properties", "methods", "events", "enumerators"));

  @Override
  public String toVarName(String name) {
    String origName = name;

    // remove dollar sign
    name = name.replace("$", "");

    // remove any logical style operators replace with MATLAB equivalents
    name = name.replace("!", "not");
    name = name.replace("=", "eq");
    name = name.replace(">", "gt");
    name = name.replace("<", "lt");
    name = name.replace("~", "tilde");
        
    // sanitize name for Java
    name = sanitizeName(name);

    // remove any hyphens from names, replace with underscores
    name = name.replace("-", "_");

    // if model name starts with number prefix with x
    if (name.matches("^\\d.*")) {
      name = "x" + name;
    }

    // if model name starts with underscore prefix with x
    if (name.matches("^\\_.*")) {
      name = "x" + name;
    }

    // for reserved word or prefix with _
    if (name != null && (reservedWords.contains(name.toLowerCase(Locale.ROOT)) || reservedVarWords.contains(name.toLowerCase(Locale.ROOT)))) {
      name = "x" + name;
    }

    name = truncateto63(name);

    if (!name.matches(origName)) {
      System.out.println("Warning: Variable name changed from: " + origName + " to: " + name);
    }  
    
    return name;
  }

  @Override
  public String toApiFilename(String name) {
    return toApiName(name);
  }

  @Override
  public String toApiName(String name) {
    String origName = name;

    // sanitize name for Java
    name = sanitizeName(name);
    // remove dollar sign
    name = name.replaceAll("$", "");

    // model name cannot use reserved keyword, e.g. return
    if (isReservedWord(name)) {
      System.out.println(
          "Warning: Cannot use reserved word as model name: " + name + " renaming to: " + camelize("api" + name));
      name = camelize("api" + name); // e.g. return => ModelReturn (after camelize)
    }

    // model name starts with number
    if (name.matches("^\\d.*")) {
      System.out
          .println("Warning: api name cannot start with a number: " + name + " renaming to: " + camelize("api" + name));
      name = camelize("api" + name); // e.g. 200Response => Model200Response (after camelize)
    }

    // remove any hyphens from names, replace with underscores
    if (name.matches("-")) {
      System.out.println("Warning: api name cannot contain - : " + name + " replacing with _");
      name.replaceAll("-", "_");
    }

    if (!name.matches(origName)) {
      System.out.println("Warning: api name changed from: " + origName + " to: " + name);
    }

    name = truncateto63(name);

    return camelize(name);
  }

  @Override
  public String toOperationId(String name) {

    String origName = name;

    // sanitize name for Java
    name = sanitizeName(name);

    // if model name starts with number prefix with _
    if (name.matches("^\\d.*")) {
      name = "_" + name;
    }

    // remove any hyphens from names, replace with underscores
    if (name.matches("-")) {
      name.replaceAll("-", "_");
    }

    // remove dollar sign
    name = name.replaceAll("$", "");

    // check for empty method name
    if (StringUtils.isEmpty(name)) {
      System.out.println("Error: Empty method name / operationId not permitted");
    }

    // method name cannot be a reserved keyword
    if (isReservedWord(name)) {
      System.out.println(
          "Warning: Method name cannot be a reserved word: " + name + " renaming to: " + sanitizeName("call_" + name));
      name = "call_" + name;
    }

    if (!name.matches(origName)) {
      System.out.println("Warning: Method name changed from: " + origName + " to: " + name);
    }

    name = truncateto63(name);

    return name;
  }

  /*
   * @Override
   * public String getArgumentsLocation() {
   * return null;
   * }
   */

  @Override
  public String sanitizeTag(String tag) {
    return sanitizeName(tag);
  }

  @Override
  public String escapeQuotationMark(String input) {
    // remove " to avoid code injection
    return input.replace("\"", "");
  }

  @Override
  public String escapeUnsafeCharacters(String input) {
    return input.replace("'", "''");
  }

  @Override
  public void setParameterExampleValue(CodegenParameter p) {
    String example;

    if (p.defaultValue == null) {
      example = p.example;
    } else {
      example = p.defaultValue;
    }

    String type = p.baseType;
    if (type == null) {
      type = p.dataType;
    }

    // Refer to typeMapping entries in MATLABClientCodegenGenerator
    if ("logical".equalsIgnoreCase(type)) {
      if (example == null) {
        example = "true";
      }
    } else if ("string".equalsIgnoreCase(type)) {
      if (example == null) {
        example = "Example string";
      }
      example = "'" + escapeText(example) + "'";
    } else if ("int32".equalsIgnoreCase(type)) {
      if (example == null) {
        example = "56";
      }
    } else if ("double".equalsIgnoreCase(type)) {
      if (example == null) {
        example = "3.4";
      }
    } else if ("single".equalsIgnoreCase(type)) {
      if (example == null) {
        example = "3.4";
      }
    } else if ("int64".equalsIgnoreCase(type)) {
      if (example == null) {
        example = "56";
      }
     } else if ("datetime".equalsIgnoreCase(type)) {
      if (example == null) {
        example = "2013-10-20T19:20:30+01:00";
      }
    } else {
      System.out.println("Warning: + Type: " + type + " not handled in setParameterExampleValue");
    }

    if (example == null) {
      example = "exampleNULL";
    } else if (Boolean.TRUE.equals(p.isArray)) {
      example = "ListContainerExample[" + example + "]";
    } else if (Boolean.TRUE.equals(p.isMap)) {
      example = "MapContainerExample{'key': " + example + "}";
    }

    p.example = example;
  }

  // See:
  // https://javadoc.io/doc/io.swagger.core.v3/swagger-models/latest/index.html
  @Override
  public String toDefaultValue(Schema p) {
    if (ModelUtils.isStringSchema(p)) {
      // TODO add actual defaults
      if (p.getDefault() != null) {
        return " = " + p.toString();
      } else {
        return "";
      }

    } else if (ModelUtils.isBooleanSchema(p)) {
      if (p.getDefault() != null) {
        return " = " + p.toString();
      } else {
        return "";
      }

    } else if (ModelUtils.isDateSchema(p)) {
      // TODO
      return "DateSchemaNotImplemented";

    } else if (ModelUtils.isDateTimeSchema(p)) {
      // TODO
      return "DateTimeSchemaNotImplemented";

    } else if (ModelUtils.isNumberSchema(p)) {
      if (p.getDefault() != null) {
        return " = " + p.toString();
      } else {
        return "";
      }

    } else if (ModelUtils.isIntegerSchema(p)) {
      if (p.getDefault() != null) {
        return " = " + p.toString();
      } else {
        return "";
      }

    } else if (ModelUtils.isArraySchema(p)) {
      if (p.getDefault() != null) {
        return " = " + p.toString();
      } else {
        return "";
      }

    } else {
      if (p.getDefault() != null) {
        return " = " + p.toString();
      } else {
        return "";
      }
    }
  }
}
