# Advanced Example: Customizing the Generator (for Apache Airflow)

```{attention}
This is an *advanced* example aimed at developers who are familiar with [MATLAB object-oriented programming](https://www.mathworks.com/help/matlab/object-oriented-programming.html), Java code development, [mustache](https://mustache.github.io/) file templates, as well as the OpenAPI Specification. It also requires an understanding of the JSONMapper class documented [here](JSONMapper.md).
```

Apart from [customizing the generated code after generation](CustomizingGeneratedCode.md) it is also possible to customize the generator Java code and/or mustache templates. This can be of interest if a specific spec extensively uses some kind of custom data type or format.

For example in the Apache Airflow REST API 2.4.0:

<https://airflow.apache.org/docs/apache-airflow/2.4.0/_specs/v1.yaml>

There are many fields of `type: string` and then `format: datetime`. This format is *not* a built-in format of the OpenAPI 3.x standard. It appears that these fields represent datetime in a format *similar to* the one defined by [RFC 3339, section 5.6](https://www.rfc-editor.org/rfc/rfc3339#section-5.6) **but then *without* the timezone**.

```{note}
Interestingly, some other fields in the same Airflow REST API are of `type: string` with `format: date-time` (note the dash -) which *is* a built-in part of the OpenAPI 3.x standard and that *is* defined to use the *standard* format as defined by [RFC 3339, section 5.6](https://www.rfc-editor.org/rfc/rfc3339#section-5.6) (so *including* the timezone).
```

Now when generating code using the standard generator, fields of this type and format will become a `string` in MATLAB. And the generated clients and models *will* actually work correctly. They will simply be returning output fields as strings or accepting strings as inputs, as-is.

However, it would be more convenient for end-users if those fields would be handled as MATLAB `datetime` (just like how built-in OpenAPI `date-time` fields *do* become MATLAB `datetime` fields). Manually updating all those fields *after* code generation might be a quite cumbersome task though as the format is used quite often in the Airflow spec. And it may in fact be faster to (temporarily) modify the generator itself to just immediately generate code which can handle the fields as MATLAB `datetime`.

## Required changes

To accomplish this, two main changes are needed:

1.  The generator must be instructed to map `type: string` with `format: datetime` to MATLAB `datetime`.

2.  For fields of these types, the following JSONMapper annotation should be set: 

    ```matlab
    JSONMapper.stringDatetime(<field_name>,'yyyy-MM-dd''T''HH:mm:ss.SSS')
    ```
    
    Which is different from the annotation for standard RFC 3339 datetime:
    
    ```matlab
    JSONMapper.stringDatetime(<fieldname>,'yyyy-MM-dd''T''HH:mm:ss.SSSZ', 'TimeZone', 'local')
    ```

## Type Mapping

Adding the type mapping is easy. In `MATLABClientCodegenGenerator.java` there already is a `typeMapping` map with various types in it, and we just have to add one more:

```diff
     typeMapping.put("DateTime", "datetime");
     typeMapping.put("date", "datetime");
     typeMapping.put("file", "string");
     // Not standard OpenAPI but extensively used in MS Azure specs
     typeMapping.put("integer+unixtime", "datetime"); 
+    // Not standard either, used by Airflow
+    typeMapping.put("string+datetime","datetime");
```

Where `string+datetime` stands for type `string` with format `datetime`.

## Annotation

There are numerous ways in which the correct annotation can be added. What we will do here is try to minimize the changes needed to the mustache template. In order to do that we first need to understand how the current `JSONMapper.stringDatetime(<fieldname>,'yyyy-MM-dd''T''HH:mm:ss.SSSZ', 'TimeZone', 'local')` is added for `date-time` fields and then strip out the `Z` and `, 'TimeZone', 'local'` parts.

Currently the annotation is added in `model_generic.mustache` through:

```handlebars
{{#isDateTime}}{{jsonmapperPackage}}.JSONMapper.stringDatetime({{name}},'yyyy-MM-dd''T''HH:mm:ss.SSSZ', 'TimeZone', 'local'), {{/isDateTime}}
```

Which is relatively straightforward: this snippet is included if the field has a property `isDateTime` = `true`, which will indeed be the case for `date-time` fields (but not yet for `datetime`).

We can make a relatively simple change to this where we add `{{^vendorExtensions.x-isUnzonedTime}}..{{/vendorExtensions.x-isUnzonedTime}}` statements around the parts which should be omitted if `vendorExtensions.x-isUnzonedTime` is `true`.

```handlebars
{{#isDateTime}}{{jsonmapperPackage}}.JSONMapper.stringDatetime({{name}},'yyyy-MM-dd''T''HH:mm:ss.SSS{{^vendorExtensions.x-isUnzonedTime}}Z{{/vendorExtensions.x-isUnzonedTime}}'{{^vendorExtensions.x-isUnzonedTime}}, 'TimeZone', 'local'{{/vendorExtensions.x-isUnzonedTime}}), {{/isDateTime}}
```

Now, there are two more things we need to do, to make this modified template work correctly. For the `format: datetime` fields, we need to:

1.  Ensure property `isDateTime` is indeed set to `true`.

2.  We need to add property `vendorExtensions.x-isUnzonedTime` = `true`.

This can be accomplished in the `postProcessModelProperty` method of `MATLABClientCodegenGenerator.java`:

```diff
   @Override
   public void postProcessModelProperty(CodegenModel model, CodegenProperty property) {
     super.postProcessModelProperty(model, property);
     // Not standard OpenAPI but extensively used in MS Azure specs
     if ("unixtime".equals(property.getDataFormat())) {
       property.vendorExtensions.put("x-isPosixTime",true);
     }
+    // Not standard either but extensively used in Airflow API      
+    if ("datetime".equals(property.getDataFormat())){
+      property.setIsDateTime(true);
+      property.vendorExtensions.put("x-isUnzonedTime",true);
+    }
  }
```

## Recompile JAR and generate MATLAB code

Finally, [recompile the JAR-file](GettingStarted.md#building-matlab-code-generation-jar) and then [generate the MATLAB code](GettingStarted.md#building-matlab-client-code) using this modified generator.

[//]: #  (Copyright 2023 The MathWorks, Inc.)
