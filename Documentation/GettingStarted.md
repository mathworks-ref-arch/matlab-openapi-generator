# Getting Started

This package supports OpenAPI 3.0. OpenAPI was formerly known as Swagger and still is in many contexts. The terms are used largely interchangeably in this document.

Consider installing the [Swagger UI](SwaggerUI.md) package to help displaying and interacting with the spec. This is useful when comparing the generated code with expected behavior.

It is assumed that Maven, and a JDK are installed and configured per [requirements](../README.md).

## Required Java libraries

Two Java libraries are required by this package. The following steps describe how they can be provisioned.

### Installing the OpenAPI generator library

The OpenAPI Tools generator Java library is required, this can be downloaded from Maven or the `Software/MATLAB/setup.m` command can be used to do so. This is used to build the MATLAB specific generator in the next step. A `generatorVersion` can be specified if required.

```matlabsession
>> setup

MATLAB Generator for OpenAPI setup
----------------------------------

This package requires a library provided by the OpenAPI Tools project.
Project details and the associated license can be found here:
  https://github.com/OpenAPITools/openapi-generator

The version of this library used by default is: 7.10.0
This is defined in the file: /home/username/package_directory/Software/Java/pom.xml
This is used to build the MATLAB specific generator.

Download required OpenAPI generator jar file, version: 7.10.0? Y/N [Y]: y
Downloading: https://search.maven.org/remotecontent?filepath=org/openapitools/openapi-generator-cli/7.10.0/openapi-generator-cli-7.10.0.jar

Setup complete.
To use the package run: startup
```

If not using `setup.m` `npx` can be used with the `openapi-generator-cli`. `npx` should be part of a standard Node.js installation. `npx` will automatically offer to download the tool if it is not yet available locally.

To ensure the correct version of the actual code generator JAR-files are available, it is recommended to use the following before running actual code generation:

```bash
npx @openapitools/openapi-generator-cli version-manager set 7.1.0
```

### Building MATLAB code generation jar

This step builds Java code that defines how to generate MATLAB client code. This jar together with generic functionality in the OpenAPITools package generate the end-product MATLAB code. The resulting jar file is: ```<package_directory>/matlab-openapi-codegen/Software/MATLAB/lib/jar/MATLABClientCodegen-openapi-generator-0.0.1.jar```

```bash
cd <package_directory>/Software/Java
mvn clean package
```

## Adding MATLAB Generator *for OpenAPI* to the MATLAB Path

The code generator generates entirely standalone packages, all helper MATLAB code is included *in* the package. And it is not necessary to add anything other than the generated package itself to the MATLAB path to be able to use the generated client. However, the MATLAB Generator *for OpenAPI* package also contains some additional helper MATLAB functions which can be useful for generating packages in the first place, as well as for debugging. Run `Software/MATLAB/startup.m` to add the correct directories to the MATLAB path.

## Building MATLAB client code

Generating a MATLAB client for a provided spec can be done inside or outside of MATLAB. To generate the client outside of MATLAB using npx directly, use:

```bash
cd <package_directory>/Software
npx @openapitools/openapi-generator-cli --custom-generator MATLAB/lib/jar/MATLABClientCodegen-openapi-generator-0.0.1.jar generate -g MATLAB \
                 -i http://localhost:3000/api-json -o TestClient --package-name Test
```

If not working in the package's `Software` directory, use full paths and add the following additional arguments:

```bash
-t "<package_directory>/Software/Mustache" --additional-properties openapiRoot="<package_directory>/Software/MATLAB
```

Alternatively from within MATLAB, after running `startup.m`, the MATLAB client can also be generated using:

```matlab
c = openapi.build.Client(inputSpec="http://localhost:3000/api-json", packageName="Test", output="TestClient");
c.build
```

See the [Build Client](BuildClient.md) file for more details and command options for this approach.

## Verify the generated code in MATLAB

```{note}
This step requires MATLAB Generator *for OpenAPI* to have been added to the MATLAB path
```

After the code has been generated, the `verifyPackage` function can be used inside MATLAB to run [`checkcode`](https://www.mathworks.com/help/matlab/ref/checkcode.html) on all the M-files inside the specified directory, and which will then display any messages reported for these files. For example:

```matlabsession
>> openapi.verifyPackage('PetClient');
Running `checkcode` on all M-files inside `PetClient`.
Located 12 files.

Checked 12 files, 0 messages across 0 files were reported and printed above.
```

It may also be invoked via the client object:

```matlab
c.verifyPackage();
```

As the generated code should contain [code analyzer suppress comments](https://www.mathworks.com/help/matlab/matlab_prog/check-code-for-errors-and-warnings.html#brqxeeu-167) where appropriate, this should typically report no messages whatsoever in any of the files, any other messages *should* be further investigated, and if needed fixed manually.

In MATLAB R2023a an issue with the linter can produce the following error:
`'empty' is referenced but is not a property, method, or event name defined in this class.'`
While the referenced code should be checked for certainty, in general this error can be safely ignored.

## Customize the generated code

Further, it may be necessary to [customize the code](CustomizingGeneratedCode.md) if the API relies on functionality which is not directly supported by the package and/or to properly configure authentication.

## Use the generated code in MATLAB

See [Basic Usage](BasicUsage.md) to learn more about using the generated code in MATLAB.

## Sharing the generated code

After having generated, customized and tested the client code, the client code can be shared with other MATLAB users. The generated packages should be entirely standalone and end-users do not have to install the MATLAB Generator *for OpenAPI*, Node.js, nor the code generator and they do not have to build the Jar file. They will simply need the whole "output directory" into which the package was generated.

```{note}
If during customization of the code, additional dependencies were introduced, end-users of the customized package will of course also need those dependencies.
```

## Building MATLAB Code Generator

The [Build Generator](BuildGenerator.md) file provides some detail on how to build the underlying generator code used by this package, this is unlikely to be necessary.

[//]: #  (Copyright 2020-2025 The MathWorks, Inc.)
