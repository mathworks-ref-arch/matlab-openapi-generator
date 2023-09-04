# Building MATLAB Code Generator

This file relates to building the infrastructure used for generating MATLAB client code. It does not relate to building MATLAB clients themselves, as such it is *very unlikely that the following steps are relevant* unless undertaking deep customization of the generation process. See [Building MATLAB Client Code](BuildClient.md) for details of building MATLAB client code from an OpenAPI spec.

The OpenAPITools OpenAPI generator can be installed as follows using npm:

```bash
# Requires npm to installed
sudo npm install @openapitools/openapi-generator-cli -g
# Check installation
sudo openapi-generator-cli version
```

Initializing a project creates a shell project for a code generator for a given language:

```bash
# The node_modules path may vary based on your local installation preferences
# e.g. /usr/local/lib/node_modules/...
java -jar /usr/lib/node_modules/@openapitools/openapi-generator-cli/bin/openapi-generator.jar meta -o out/generators/my-codegen -n MATLABClientCodegen -p com.mathworks.codegen
# or
openapi-generator-cli meta -o out/generators/my-codegen -n MATLABClientCodegen -p com.mathworks.codegen
```

As an end user it is unlikely to be necessary as a configured MATLAB generator is included in this package. This process can be used to generate fresh mustache template files.

Similar syntax if using Swagger tools rather than OpenAPITools.

```bash
# Output to openapicodegen/template/ to avoid overwriting customized versions
java -jar <get checkout directory>/swagger-codegen/modules/swagger-codegen-cli/target/swagger-codegen-cli.jar \
    meta -o <get checkout directory>/openapicodegen/template/ \
    -n MATLABClientCodegen -p com.mathworks.codegen
```

[//]: #  (Copyright 2020-2022 The MathWorks, Inc.)
