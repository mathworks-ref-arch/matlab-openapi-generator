# Building MATLAB Client Code

## Generating a MATLAB client using a builder

A builder class is provided to simplify the process of building a client, e.g.:

```matlab
% Run startup to configure the package's MATLAB paths
cd Software/MATLAB
startup

% Create a builder object
c = openapi.build.Client;

% Set the package name, defaults to "OpenAPIClient"
c.packageName = "myPkg";

% Set the path to the spec., this may also be a HTTP URL
c.inputSpec = "/home/username/git/openapicodegen/Software/mySpec.yaml";

% Set a directory where the results will be stored
c.output = "/home/username/git/openapicodegen/myClient";

% Pass a string containing some optional additional arguments to the openapi-generator-cli
c.additionalArguments = "--my_extra_argument";

% Insert a copyright notice in generated code
c.copyrightNotice = sprintf("%% (c) %d My Company Name Inc.", year(datetime("now")));

% Trigger the build process
c.build;
```

Additional builder properties can be used to set non default properties:

* templateDir: set the path to the Mustache files, e.g. if providing a customized version of those provided with the package.
* jarPath: set the path to an alternative jar file, the default is `Software/MATLAB/lib/jar/MATLABClientCodegen-openapi-generator-0.0.1.jar`.

The builder will automatically install the `@openapitools/openapi-generator-cli` using `npx` if it is not already present.

A build log file is produced in the output directory.

## Spec validation

In general specs rarely completely pass validation despite being functional. With this in mind spec validation is *disabled* by default.
It can be enabled as follows. This can be useful when debugging or first evaluating a new spec. This package is not intended as a spec validation or writing tool.

```matlab
c.skipValidateSpec = false;
```

## node and npx configuration

At a high-level the MATLAB client provides an interface to the node (Node.js) based openapitools frontend to the Java based generation code and npx is used to manage the execution of the node package. Thus both node and npx must be available, recent versions of node include npx.
Particularly on Linux systems it is common for a system to have a default install of node which may be significantly older than user installed versions.
To use a specific version of node e.g. to meet the version requirements the client properties `nodePath` and `npxPath` can be used to specify the directory paths containing the node and npx executables. E.g.:

```matlab
c.nodePath = '/home/username/.nvm/versions/node/v16.15.1/bin/'; % Optional, to use a non-system node install
c.npxPath = '/home/username/.nvm/versions/node/v16.15.1/bin/';
```

Setting the nodePath or npxPath values currently has no effect on Windows systems.
The `checkDeps()` method on the client can be used to check if the client's dependencies are met, in which case it returns `true` and otherwise `false`. This method is called when the `build` method is called.

## Using an openapitools.json file

By default a configuration file, typically called called `openapitools.json`, is produced. This is populated by the builder and passed to the underlying tools. If command line invocation is used and if it does not already exist when the generator is invoked. A minimal generated configuration template is produced. Using a configuration file can be less error prone than the CLI based approach though they are equivalent. Storing the file in source control alongside code can be useful given the potential complexity of configurations. Furthermore it is easily overwritten accidentally and there are a great many potential configuration options that may be difficult to replicate if lost.

The following is a sample `openapitools.json` file, it is typically located in the working directory being used by the generator.
The schema for this file can provide further details: [https://github.com/OpenAPITools/openapi-generator-cli/blob/master/apps/generator-cli/src/config.schema.json](https://github.com/OpenAPITools/openapi-generator-cli/blob/master/apps/generator-cli/src/config.schema.json)

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "spaces": 2,
  "generator-cli": {
    "version": "6.6.0",
    "generators": {
      "v3.0": {
        "generatorName": "MATLAB",
        "output": "/tmp/Airflow",
        "inputSpec": "/home/username/git/openapicodegen/Software/MATLAB/test/fixtures/ApacheAirflow_v1.yaml",
        "packageName": "Airflow",
        "skipValidateSpec": true,
        "additionalProperties": {
          "openapiRoot": "/home/username/git/openapicodegen/Software/MATLAB",
          "copyrightNotice": "% (c) 2023 Example Company"
        },
        "templateDir": "/home/username/git/openapicodegen/Software/Mustache"
      }
    }
  }
}
```

If an alternative file is preferred or if the configuration is not to be used:

```matlab
% Property to indicate that an alternative json file should be used
c.configurationFile = '/my/alternative/path/openapitools.json';
```

```matlab
% Property to indicate that an openapitools.json file should be used
c.useFileConfiguration = false;
```

## Copyright notice insertion

A Copyright notice can be automatically inserted into generated code. To do so prior to calling the client's `build` method set the client's `copyrightNotice` property, e.g.:

```matlab
c.copyrightNotice = "(c) 2023 My Company Name Inc.";
```

The value will be inserted as a comment in the header of generated `api` and `model` code files. As the client passes the value as an argument to `npx` certain string processing rules are applied:

* Parentheses, ( & ), will be escaped.
* Spaces will be escaped.
* Single and double quotes will be removed.

The copyright symbol "©" is supported. Hyphens are supported.

This method is appropriate for short, simple statements as shown in the example. If more extensive text or legal statements, e.g. licensing details, are required in the generated code, then careful modification of the `Software/Mustache/copyrightNotice.mustache` template file is the suggested approach. Comment symbols, `%`, should be prepended to any such text.

## Specifying properties

`globalProperties` and `additionalProperties` can be specified as follows:

```matlab
c.globalProperties = containers.Map({'skipFormModel', 'debugOpenAPI'}, {false,true});
c.additionalProperties = containers.Map({'myKey'}, {'myValue'});
```

## Generator debug flags

The following Java flags can be set to obtain additional debugging information during the code generation process:

* `-DdebugModels` output models passed to the template engine
* `-DdebugOperations` output operations passed to the template engine
* `-DdebugSwagger` output the OpenAPI Specification
* `-DdebugSupportingFiles` output supporting files info
* `-DinvokerPackage` invoking package name

To easiest way to set these *Java* flags while working with `openapi-generator-cli` is by setting them through environment variable `JAVA_TOOL_OPTIONS`, i.e. before using `openapi-generator-cli`, in the same shell on Linux first use:

```bash
export JAVA_TOOL_OPTIONS=-DdebugModels
```

or on Windows

```bat
set JAVA_TOOL_OPTIONS=-DdebugModels
```

## Ancillary files

### .openapi-generator-ignore

A `.openapi-generator-ignore` file can be used to prevent files from being overwritten by the generator, for example if they have been customized in some way. A template version fo the file with detailed usage information is generated by the generator if the file does not already exist. This is can be thought of as being similar to a `.gitignore` or `.dockerignore` file. If the file is not used it can be safely removed or ignored.

### Build log

A log file is produced by the client containing generator output and other information, it is stored in the package output directory as `PACKAGE-NAME_build.log`. It should be reviewed for detailed information on the generation process.

## Generating a MATLAB client using the command line

The following commands show how a MATLAB client can be generated from a given spec. Using the provided generator without invoking MATLAB. Note that using the MATLAB builder can help to provide the initial syntax.

```bash
# Change to the packages software directory
cd <package_dir>/Software

npx @openapitools/openapi-generator-cli --custom-generator MATLAB/lib/jar/MATLABClientCodegen-openapi-generator-0.0.1.jar generate -g MATLAB -i http://localhost:3000/api-json -o TestClient --package-name Test
```

Note, the `-i` argument can also point to a local spec file in `.yaml` or `.json` format.

By default the client will be generated in a the current directory in a subdirectory named `OpenAPIClient`. This can be changed using the `-o` flag as shown in the syntax above. Similarly, by default the generator creates a package named `OpenAPIClient` which can be changed with the `--package-name` flag.

The generation process can produce a great deal of log output thus redirecting output to a file is recommended so the file can be more easily searched using a text editor if the output is redirected: ```... --package-name Test > log.txt```

An alternative Mustache files directory can be specified using the `-t` flag e.g.: `-t /home/username/MyMustacheFiles`, this can be useful if experimenting with alternative templates while retaining defaults.

If not running from the `Software` directory the location of the `Software/MATLAB` directory must be provided through `--additional-properties=openapiRoot=<location-of-Software/MATLAB>`, e.g. `--additional-properties=openapiRoot=/work/openapi/Software/MATLAB`. Without this the generator will not be able to find some of the helper MATLAB files which need to be included in the generated package. (When using the MATLAB Builder this option is set automatically).

Finally it is possible to add another flag `-p AddOAuth=name` (where name can be chosen freely), this will then add authentication calls to *all* operations and generates skeleton [`requestAuth` and `getOAuthToken` code which can then be customized](CustomizingGeneratedCode.md#authentication) to add OAuth 2.0 authentication to *all* operations.

Ultimately npx invokes Java to run the code having created the appropriate input arguments, one can avoid using npx and use Java directly, using npx initially to get the basic form of the Java command and then adjusting this can be useful.

[//]: #  (Copyright 2020-2023 The MathWorks, Inc.)