# MATLAB Generator *for OpenAPI*

MATLAB® Generator *for OpenAPI™* provides a generator to enable generation of RESTful Clients and Models based on OpenAPI 3.0 specifications. OpenAPI was formerly known as Swagger. The core of this package is a Java class that extends the community Generator CLI and Mustache template files for APIs and Models.

## Requirements

### MathWorks Products (https://www.mathworks.com)

* Requires MATLAB release R2020b or later

### 3rd Party Products

* Java Development Kit (JDK) 11 or compatible
* [Maven](https://maven.apache.org/) 3.6 or greater
* [Node.js®](https://nodejs.org/en/) 16.x LTS or greater (required by OpenAPITools openapi-generator)
* [OpenAPITools openapi-generator](https://github.com/openapitools/openapi-generator), (downloaded by Maven build step and/or Node.js `npx`)
* [npx/npm](https://github.com/npm/cli) 8.12.1 or greater, in recent Node.js >= v16 releases `npx` is included and the version numbers match so this is typically not an issue

## Introduction

This package is developed and tested using [OpenAPI](https://github.com/OAI/OpenAPI-Specification)
version 3, in many cases it may work with a version 2 specifications however this is not supported. Please consider migrating the specification to version 3.

## Getting Started

Please refer to the [Documentation](Documentation/README.md) to get started. The [Getting Started](Documentation/GettingStarted.md) and [Basic Usage](Documentation/BasicUsage.md) documents provide more detailed instructions on setting up and using the interface.

## Installation

The MathWorks provided Java code in this package uses the OpenAPITools openapi-generator package. A `pom.xml` files is provided. The resulting jar can be built using:

```bash
cd package-directory/Software/Java
mvn clean package
```

## Usage

To generate MATLAB client code for the well known [PetStore](https://github.com/swagger-api/swagger-petstore/blob/master/src/main/resources/openapi.yaml) sample spec, download it and use a command similar to:

### Using a MATLAB client builder

```matlab
% Run startup to configure the package's MATLAB paths
cd Software/MATLAB
startup
cd ..

% Create a builder object
c = openapi.build.Client;
% Set the package name, defaults to "OpenAPIClient"
c.packageName = "PetStore";
% Set the path to the spec., this may also be a HTTP URL
c.inputSpec = "openapi.yaml";
% Set a directory where the results will be stored
c.output = fullfile(pwd, "PetClient");
% Trigger the build process
c.build;
```

### Using the command line

On Linux:

```bash
npx @openapitools/openapi-generator-cli --custom-generator MATLAB/lib/jar/MATLABClientCodegen-openapi-generator-0.0.1.jar generate -g MATLAB -i openapi.yaml -o PetClient --package-name PetStore
```

Or on Windows replace the forward slashes in local paths with back slashes:

```bat
npx @openapitools/openapi-generator-cli --custom-generator MATLAB\lib\jar\MATLABClientCodegen-openapi-generator-0.0.1.jar generate -g MATLAB -i openapi.yaml -o PetClient --package-name PetStore
```

> The slash in `@openapitools/openapi-generator-cli` is Node/npx syntax and not a local path, so this needs to remain a forward slash.

## License

The license for the MATLAB Generator *for OpenAPI* is available in the [LICENSE.txt](LICENSE.txt) file in this repository. This package uses certain third-party content which is licensed under separate license agreements. Please see the pom.xml file for third-party software downloaded at build time.

## Enhancement Requests

Provide suggestions for additional features or capabilities using the following link:
https://www.mathworks.com/products/reference-architectures/request-new-reference-architectures.html

## Support

Email: `mwlab@mathworks.com` or please log an issue.

[//]: #  (Copyright 2019-2023 The MathWorks, Inc.)
