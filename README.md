# MATLAB Generator *for OpenAPI*

MATLAB® Generator *for OpenAPI™* provides a generator to enable generation of RESTful Clients and Models based on OpenAPI 3.0 specifications. OpenAPI was formerly known as Swagger. The core of this package is a Java class that extends the community Generator CLI and Mustache template files for APIs and Models.

## Requirements

### MathWorks Products [https://www.mathworks.com](https://www.mathworks.com)

* Requires MATLAB release R2020b or later.

### 3rd Party Products

* Java Development Kit (JDK) 11 or compatible.
* [Maven](https://maven.apache.org/) 3.6 or greater.
* [OpenAPITools openapi-generator](https://github.com/openapitools/openapi-generator), downloaded by `setup.m`.
* Node.js is required only if using the unit test suite or using `npx` at the command line.

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

To generate MATLAB client code for the well known [PetStore](https://github.com/swagger-api/swagger-petstore/blob/master/src/main/resources/openapi.yaml) sample spec, download it and use commands similar to:

### Using a MATLAB client builder

```matlab
% Run startup to configure the package's MATLAB paths
cd <package_directory>/Software/MATLAB
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

If there is a preference to work directly with the Node.js `npx` command rather than the higher-level MATLAB client, it can be called as follows. On Linux:

```bash
cd <package_directory>/Software
npx @openapitools/openapi-generator-cli --custom-generator MATLAB/lib/jar/MATLABClientCodegen-openapi-generator-0.0.1.jar generate -g MATLAB -i openapi.yaml -o PetClient --package-name PetStore
```

If not working in the package's `Software` directory, use full paths and add the following additional arguments:

```bash
-t "<package_directory>/Software/Mustache" --additional-properties openapiRoot="<package_directory>/Software/MATLAB
```

Or on Windows replace the forward slashes in local paths with back slashes:

```bat
cd <package_directory>\Software
npx @openapitools/openapi-generator-cli --custom-generator MATLAB\lib\jar\MATLABClientCodegen-openapi-generator-0.0.1.jar generate -g MATLAB -i openapi.yaml -o PetClient --package-name PetStore
```

If not working in the package's `Software` directory, use full paths and add the following additional arguments:

```bat
-t "c:\<package_directory>\Software\Mustache" --additional-properties openapiRoot="c:\ <package_directory>\Software\MATLAB"
```

> The slash in `@openapitools/openapi-generator-cli` is Node/npx syntax and not a local path, so this needs to remain a forward slash.

## License

The license for the MATLAB Generator *for OpenAPI* is available in the [LICENSE.txt](LICENSE.txt) file in this repository. This package uses certain third-party content which is licensed under separate license agreements. Please see the pom.xml file for third-party software downloaded at build time.

## Enhancement Requests

Provide suggestions for additional features or capabilities using the following link:
<https://www.mathworks.com/products/reference-architectures/request-new-reference-architectures.html>

## Support

Email: `mwlab@mathworks.com` or please log an issue.

[//]: #  (Copyright 2019-2025 The MathWorks, Inc.)
