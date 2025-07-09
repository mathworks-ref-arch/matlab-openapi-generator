package com.mathworks.codegen;

import static org.openapitools.codegen.utils.StringUtils.camelize;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.apache.commons.io.FileUtils;
import org.apache.commons.lang3.StringUtils;
import org.openapitools.codegen.CodegenComposedSchemas;
import org.openapitools.codegen.CodegenConfig;
import org.openapitools.codegen.CodegenConstants;
import org.openapitools.codegen.CodegenModel;
import org.openapitools.codegen.CodegenParameter;
import org.openapitools.codegen.CodegenProperty;
import org.openapitools.codegen.DefaultCodegen;
import org.openapitools.codegen.SupportingFile;
import org.openapitools.codegen.model.ModelMap;
import org.openapitools.codegen.model.ModelsMap;
import org.openapitools.codegen.utils.ModelUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.swagger.v3.oas.models.media.Schema;

// Copyright 2022-2025 The MathWorks, Inc.

public class MATLABCodegen extends DefaultCodegen implements CodegenConfig {
    private final Logger LOGGER = LoggerFactory.getLogger(MATLABCodegen.class);

    public String packageName; // e.g. petstore_api
    public String packageVersion;

    MATLABCodegen() {
        super();
        
        legacyDiscriminatorBehavior = false;
        useOneOfInterfaces = true;
        supportsInheritance = true;

        // Reserved words. Reserved words specific to MATLAB
        // Output of iskeyword in MATLAB (R2023a)
        reservedWords = new HashSet<String>(
                Arrays.asList(
                        "break", "case", "catch", "classdef", "continue", "else", "elseif", "end",
                        "for", "function", "global", "if", "otherwise", "parfor", "persistent",
                        "return", "spmd", "switch", "try", "while"));
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

        setTemplateDir();

        /*
         * Should not fall back to here as MATLAB Mustache files
         * do not ship as part of the codegen package
         */
        embeddedTemplateDir = "embeddedMustacheDirectory";

    }

    public void setTemplateDir() {
        String pathPWD = java.lang.System.getProperty("user.dir");
        File parent = new File(pathPWD);
        this.templateDir = parent.getAbsolutePath() + File.separator + "Mustache";
    }

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
            setPackageVersion("3.0.0");
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

        // Should only fall back to here if running from outside /Software or
        // /Software/Mustache is missing
        if (StringUtils.isBlank(templateDir)) {
            embeddedTemplateDir = templateDir = "defaultTemplateDirectory";
        }
        // Additional MATLAB files found relative to openapiRoot

        if (additionalProperties.containsKey("openapiRoot")) {
            openapiRoot = (String) additionalProperties.get("openapiRoot");
        } else {
            String pathPWD = java.lang.System.getProperty("user.dir");
            File parent = new File(pathPWD);
            openapiRoot = parent.getAbsolutePath() + File.separator + "MATLAB";
        }

        // Root output directory based on package name
        outputPackageRoot = fullfile("+" + packageName.replace(".", File.separatorChar + "+"));

        // Add JSONMapper files
        String jsonmapperRoot = fullfile(openapiRoot, "..", "Modules", "matlab-jsonmapper", "Software", "MATLAB");
        supportingFiles.add(new SupportingFile(
                fullfile(jsonmapperRoot, "app", "system", "JSONEnum.m"),
                fullfile(outputPackageRoot, "JSONEnum.m")));
        supportingFiles.add(new SupportingFile(
                fullfile(jsonmapperRoot, "app", "system", "JSONMapper.m"),
                fullfile(outputPackageRoot, "JSONMapper.m")));
        supportingFiles.add(new SupportingFile(
                fullfile(jsonmapperRoot, "app", "system", "JSONMapperMap.m"),
                fullfile(outputPackageRoot, "JSONMapperMap.m")));
        supportingFiles.add(new SupportingFile(
                fullfile(jsonmapperRoot, "app", "system", "JSONDiscriminator.m"),
                fullfile(outputPackageRoot, "JSONDiscriminator.m")));
        supportingFiles.add(new SupportingFile(
                fullfile(jsonmapperRoot, "app", "system", "JSONPropertyInfo.m"),
                fullfile(outputPackageRoot, "JSONPropertyInfo.m")));
        // Set jsonmapperPackage which can be used in mustache templates to determine in
        // which package it was placed
        additionalProperties.put("jsonmapperPackage", packageName);

        // Add FreeFormObject.m which is generated from mustache template
        supportingFiles.add(new SupportingFile("freeformobject.mustache",
                fullfile(outputPackageRoot, "+models", "FreeFormObject.m")));

        // Add a type mapping for JSONMapperMap *inside* package name
        typeMapping.put("map", packageName + ".JSONMapperMap");
        // Enable file postprocessing to allow replacing JSONMapper etc with packaged
        // name
        setEnablePostProcessFile(true);

    }

    public String openapiRoot;

    public String outputPackageRoot;

    public void setPackageName(String packageName) {
        this.packageName = packageName;
    }

    public void setPackageVersion(String packageVersion) {
        this.packageVersion = packageVersion;
    }

    private String ensureNotEmpty(String val) {
        if (val.isBlank()) {
            return "EMPTY_STRING";
        }
        return val;
    }

    private String[] supportedEnumNameExtensions = { "x-enumNames" };

    private Map<String, Object> sanitizeEnumValues(Map<String, Object> allowableValues,
            Map<String, Object> vendorExtensions) {
        // Add enum values as allowableValues
        ArrayList<Object> allEnumValues = new ArrayList<Object>();
        ArrayList<Object> vals = (ArrayList<Object>) allowableValues.get("values");
        ArrayList<String> nameList = null;
        for (String pn : supportedEnumNameExtensions) {
            if (vendorExtensions.containsKey(pn)) {
                nameList = (ArrayList<String>) vendorExtensions.get(pn);
                break;
            }
        }
        for (int i = 0; i < vals.size(); i++) {
            HashMap<String, Object> enumVal = new HashMap<String, Object>();
            enumVal.put("baseName", vals.get(i));
            if (nameList != null) {
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
            property.vendorExtensions.put("x-isPosixTime", true);
        }
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
                mo.setAllowableValues(sanitizeEnumValues(mo.allowableValues, mo.vendorExtensions));
            } else if (mo.hasVars) {
                // If the model is not an enum but has variables

                // Go through all variables
                for (CodegenProperty prop : mo.vars) {
                    // If the variable is an enum
                    if (prop.isEnum) {
                        // Form an unique enum name based on the class and inline enum
                        String newEnumName = truncateto63(mo.classname, prop.enumName);

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

                        cgm.setAllowableValues(sanitizeEnumValues(prop.allowableValues, prop.vendorExtensions));

                        cgm.setClassname(newEnumName);
                        // Include all global additionalProperties (like jsonmapperPackage)
                        moMap.putAll(additionalProperties);

                        // Add to the model map
                        moMap.setModel(cgm);
                        mosMap.setModels(Collections.singletonList(moMap));
                        enumModels.put(newEnumName, mosMap);
                    }

                    // For the oneOf check we want to check both properties which are oneOf directly
                    // as well
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
                            for (CodegenProperty p : l) {
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

    public String fullfile(CharSequence... elements) {
        return String.join(File.separator, elements);
    }

    @Override
    public void postProcessFile(File file, String fileType) {
        super.postProcessFile(file, fileType);
        // Inside the JSONMapper helper files
        if ("supporting-file".equals(fileType) && file.getName().endsWith("m")) {
            String contents;
            try {
                // Replace JSONEnum|JSONMapper|JSONPropertyInfo with packaged names
                // (Except of course when in classdef definition or as constructor name)
                contents = FileUtils.readFileToString(file, "UTF-8");
                java.util.regex.Pattern p = java.util.regex.Pattern.compile(
                        "(?<!(classdef|function|error|warning).*)(JSONMapper|JSONPropertyInfo|JSONDiscriminator)");
                java.util.regex.Matcher m = p.matcher(contents);
                contents = m.replaceAll(additionalProperties.get("jsonmapperPackage") + ".$2");
                FileUtils.write(file, contents, "UTF-8");
            } catch (IOException e) {
                e.printStackTrace();
            }

        }
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

    @Override
    public String toApiFilename(String name) {
        return toApiName(name);
    }

    private HashMap<String, String> truncatedNames = new HashMap<String, String>();

    /**
     * Truncates names to 63 characters, the maximum length for variable, function
     * and class names in MATLAB. As this method may get called multiple times for
     * a given name, it tracks previously truncated names in a HashMap and ensures
     * the same name it returned each time.
     * 
     * @param name input name
     * @return truncated name
     */
    private String truncateto63(String name) {
        return truncateto63(name, "");
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
        String newName = name.substring(0, 58 - suffixLen) + suffix + "_" + String.format("%04d", counter++);
        // Verify that this is unique and not used before for another name with the same
        // prefix
        while (truncatedNames.containsValue(newName)) {
            // Keep increasing the counter until a unique name is formed
            newName = name.substring(0, 58 - suffixLen) + suffix + "_" + String.format("%04d", counter++);
        }
        // Store the new truncated name in the hashmap
        truncatedNames.put(name + suffix, newName);
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
            LOGGER.info(
                    "Cannot use reserved word as model name: " + name + " renaming to: "
                            + camelize("model" + name));
            name = camelize("model" + name); // e.g. return => ModelReturn (after camelize)
        }

        // model name starts with number
        if (name.matches("^\\d.*")) {
            LOGGER.info(
                    "Model name cannot start with a number: " + name + " renaming to: "
                            + camelize("model" + name));
            name = camelize("model" + name); // e.g. 200Response => Model200Response (after camelize)
        }

        // if model name starts with underscore prefix with x
        if (name.matches("^\\_.*")) {
            name = "x" + name;
        }

        // remove any hypens from names, replace with underscores
        if (name.contains("-")) {
            LOGGER.info("Model name cannot contain - : " + name + " replacing with _");
            name.replaceAll("-", "_");
        }

        // if (!name.equals(origName)) {
        // LOGGER.info("Model name changed from: " + origName + " to: "
        // + name);
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
            LOGGER.info("Variable name changed from: " + origName + " to: " + name);
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
        if (name != null && (reservedWords.contains(name.toLowerCase(Locale.ROOT))
                || reservedVarWords.contains(name.toLowerCase(Locale.ROOT)))) {
            name = "x" + name;
        }

        name = truncateto63(name);

        if (!name.matches(origName)) {
            LOGGER.info("Variable name changed from: " + origName + " to: " + name);
        }

        return name;
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

            LOGGER.info(
                    "Cannot use reserved word as model name: " + name + " renaming to: "
                            + camelize("api" + name));
            name = camelize("api" + name); // e.g. return => ModelReturn (after camelize)
        }

        // model name starts with number
        if (name.matches("^\\d.*")) {
            System.out
                    .println("api name cannot start with a number: " + name + " renaming to: "
                            + camelize("api" + name));
            name = camelize("api" + name); // e.g. 200Response => Model200Response (after camelize)
        }

        // remove any hyphens from names, replace with underscores
        if (name.matches("-")) {
            LOGGER.info("api name cannot contain - : " + name + " replacing with _");
            name.replaceAll("-", "_");
        }

        if (!name.matches(origName)) {
            LOGGER.info("api name changed from: " + origName + " to: " + name);
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
            LOGGER.info("Error: Empty method name / operationId not permitted");
        }

        // method name cannot be a reserved keyword
        if (isReservedWord(name)) {
            LOGGER.info(
                    "Method name cannot be a reserved word: " + name + " renaming to: "
                            + sanitizeName("call_" + name));
            name = "call_" + name;
        }

        if (!name.matches(origName)) {
            LOGGER.info("Method name changed from: " + origName + " to: " + name);
        }

        name = truncateto63(name);

        return name;
    }

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
            LOGGER.info("Type: " + type + " not handled in setParameterExampleValue");
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

    /**
     * Location to write api files. You can use the apiPackage() as defined when the
     * class is
     * instantiated
     */
    @Override
    public String apiFileFolder() {
        return outputFolder + File.separatorChar + "+" + apiPackage().replace(".", File.separatorChar + "+");
    }

    /**
     * Location to write model files. You can use the modelPackage() as defined when
     * the class is
     * instantiated
     */
    @Override
    public String modelFileFolder() {
        return outputFolder + File.separatorChar + "+" + modelPackage().replace(".", File.separatorChar + "+");
    }
}
