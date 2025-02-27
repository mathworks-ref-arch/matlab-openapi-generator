# Generator Configuration Options

There are various options which must be passed to the generator, for example to specify which OpenAPI to generate a client for. And there are additional optional options to customize the behavior of the generator. The following page gives a complete overview of all options and how these can be specified:

* Through `openapi.build.Client` inside MATLAB, or

* On the `npx @openapitools/openapi-generator-cli generate` command line *directly*, or

* Through a JSON configuration file which is then passed to the generator on the `npx @openapitools/openapi-generator-cli generate` command line.

```{contents}
:local:
```

## config

Instructs the command line tool to read further configuration options from a JSON-file.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

When working with `openapi.build.Client` you can provide such a configuration file, using the `inputConfigurationFile` argument or property.
When the `build()` method is called an output configuration file is written to the location given by the `outputConfigurationFile` argument or property or the default `openapitools.json`, in the current directory.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
% Only if necessary, normally the default value is correct
client.inputConfigurationFile = "/some/alternative/location/myconfig.json";

% Or, set during initialization
client = openapi.build.Client(inputConfigurationFile="/some/alternative/location/myconfig.json")
```

````

````{tab-item} JSON Configuration
:sync: json

This *is* the actual configuration file, and it does not refer to itself inside the configuration.
````

````{tab-item} Command Line
:sync: cli

Specified through the `--config` parameter

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --config /some/alternative/location/myconfig.json
```
````
`````

## jarPath

Instructs the command line tool where to find the custom MATLAB generator JAR-file. When working with `openapi.build.Client` this typically does not have to be set explicitly but when working with the generator in the shell directly, the location *must* be provided.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `jarPath` property. This typically does not have to be set explicitly and can typically be determined automatically based on the location of `openapi.build.Client` itself, but can be changed if necessary.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
% Only if necessary, normally the default value is correct
client.templateDir = "/some/alternative/location/MATLABClientCodegen-openapi-generator-0.0.1.jar";

% Or, set during initialization
client = openapi.build.Client(templateDir="/some/alternative/location/MATLABClientCodegen-openapi-generator-0.0.1.jar")
```

````

````{tab-item} JSON Configuration
:sync: json

Cannot be configured in the JSON configuration file. Must be provided on the command-line if not working with the client builder inside MATLAB.
````

````{tab-item} Command Line
:sync: cli

Specified through the `--custom-generator` parameter

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --custom-generator /some/location/Software/MATLAB/lib/jar/MATLABClientCodegen-openapi-generator-0.0.1.jar
```
````
`````

## generatorName

Specifies which generator to use to generate a client. For the MATLAB generator this must be set to `MATLAB`.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Cannot be changed, defaults to `MATLAB`.
````

````{tab-item} JSON Configuration
:sync: json

Specified through `generator-cli.generators.v3.0.generatorName`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "generatorName": "MATLAB"
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified through the `-g` parameter

Example:

```console
npx @openapitools/openapi-generator-cli generate ... -g MATLAB
```
````
`````

## inputSpec

Specifies the location of the OpenAPI spec to generate a MATLAB client for. This can refer to a local file or HTTP(S) URI. If the API specification is spread across multiple separate files consider using [`inputSpecRootDirectory`](#inputspecrootdirectory) instead. Either `inputSpec` or `inputSpecRootDirectory` must be set (if both are set `inputSpec` is ignored and `inputSpecRootDirectory` is used instead).

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `inputSpec` property.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
client.inputSpec = "/some/location/myspec.yaml";

% Or, set during initialization
client = openapi.build.Client(inputSpec="/some/location/myspec.yaml")
```

````
````{tab-item} JSON Configuration
:sync: json

Specified through `generator-cli.generators.v3.0.inputSpec`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "inputSpec": "/some/location/myspec.yaml"
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified through the `-i` parameter

Example:

```console
npx @openapitools/openapi-generator-cli generate ... -i /some/location/myspec.yaml
```
````
`````

## inputSpecRootDirectory

Specifies a directory containing a collection of JSON and/or YAML-files which make up the entire API specification. When working with this option a single MATLAB client is created which covers all APIs and Models from all files combined. Either `inputSpec` or `inputSpecRootDirectory` must be set (if both are set `inputSpec` is ignored and `inputSpecRootDirectory` is used instead).

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `inputSpecRootDirectory` property.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
client.inputSpecRootDirectory = "/some/location";

% Or, set during initialization
client = openapi.build.Client(inputSpecRootDirectory="/some/location")
```

````
````{tab-item} JSON Configuration
:sync: json

Specified through `generator-cli.generators.v3.0.inputSpecRootDirectory`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "inputSpecRootDirectory": "/some/location"
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified through the `--input-spec-root-directory` parameter

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --input-spec-root-directory /some/location
```
````
`````

## packageName

Specifies the name of the MATLAB package inside which to generate the MATLAB client.

If not set, defaults to `OpenAPIClientPackage`.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `packageName` property.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
client.packageName = "myPackage";

% Or, set during initialization
client = openapi.build.Client(packageName="myPackage")
```

````
````{tab-item} JSON Configuration
:sync: json

Specified through `generator-cli.generators.v3.0.packageName`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "packageName": "myPackage"
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified through the `--package-name` parameter

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --package-name myPackage
```
````
`````

## output

Specifies the output directory where the client is to be generated

If not set, defaults to `OpenAPIClient`.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `output` property.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
client.output = "myClient";

% Or, set during initialization
client = openapi.build.Client(output="myClient")
```

````
````{tab-item} JSON Configuration
:sync: json

Specified through `generator-cli.generators.v3.0.output`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "output": "myClient"
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified through the `-o` parameter

Example:

```console
npx @openapitools/openapi-generator-cli generate ... -o myClient
```
````
`````

## skipValidateSpec

By default the generator first validates the input spec to determine whether it conforms to the OpenAPI 3.0.x specification and it errors out if the spec is non-conformant. In some non-conformant cases it is still possible to generate useful clients though and in those cases it is possible to disable the check using `skipValidateSpec`.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `skipValidateSpec` property.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
client.skipValidateSpec = true;

% Or, set during initialization
client = openapi.build.Client(skipValidateSpec=true)
```

````
````{tab-item} JSON Configuration
:sync: json

Specified through `generator-cli.generators.v3.0.skipValidateSpec`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "skipValidateSpec": true
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified through the `--skip-validate-spec` parameter

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --skip-validate-spec
```
````
`````

## copyrightNotice

In some cases it may be desirable to include copyright notices in the generated code, this can be accomplished through the `copyrightNotice` option.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `copyrightNotice` property.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
client.copyrightNotice = "(c) 2023 My Company";

% Or, set during initialization
client = openapi.build.Client(copyrightNotice="(c) 2023 My Company")
```

````
````{tab-item} JSON Configuration
:sync: json

Specified as additional property named `copyrightNotice`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "additionalProperties": {
            "copyrightNotice": "(c) 2023 My Company"
        }
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified as additional property named `copyrightNotice`. Note that specifying this on the command line can be tricky as this may contain characters which need to be escaped.

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --additional-properties copyrightNotice="(c) My Company"
```
````
`````

## templateDir

Specifies the location of the template directory.

This does not have to be specified if the tooling is run from its default location and no alternative templates are to be used. Do specify when running from non-default locations or if you want to work with modified templates in a different location.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `templateDir` property. Typically does not have to be set and can be determined automatically.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
% Only if necessary/desired, normally the default value is correct
client.templateDir = "/some/alternative/location";

% Or, set during initialization
client = openapi.build.Client(templateDir="/some/alternative/location")
```

````
````{tab-item} JSON Configuration
:sync: json

Specified through `generator-cli.generators.v3.0.templateDir`. Does not have to be set if running the generator CLI from the `Software` directory and wanting to work with the default templates.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "templateDir": "/some/alternative/location"
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified through the `-t` parameter.  Does not have to be set if running the generator CLI from the `Software` directory and wanting to work with the default templates.

Example:

```console
npx @openapitools/openapi-generator-cli generate ... -t /some/alternative/location
```
````
`````

## openapiRoot

Specifies the location of the `MATLAB` directory inside the package. Some files and tooling need are located relative to this location.

This does not have to be specified if the tooling is run from its default location. Do specify when running from non-default locations.

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through `openapiRoot` property.

Example:

```matlab
% Set the property after initialization
client = openapi.build.Client();
% Only if necessary, normally the default value is correct
client.openapiRoot = "/some/location/Software/MATLAB";

% Or, set during initialization
client = openapi.build.Client(openapiRoot="/some/location/Software/MATLAB")
```

````
````{tab-item} JSON Configuration
:sync: json

Specified as additional property named `openapiRoot`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "additionalProperties": {
            "openapiRoot": "/some/location/Software/MATLAB"
        }
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified as additional property named `openapiRoot`.

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --additional-properties openapiRoot=/some/location/Software/MATLAB
```
````
`````


## AddOAuth

Adds OAuth authentication to all operations. Strictly speaking, whether or not authentication is required should be specified on a per operation basis in the OpenAPI spec. What often happens though, if *all* operations require authentication is that this is explained on a high level in text but the formal definitions on each and every operation is omitted from the spec. In that case, by default the generated MATLAB code will als *not* authenticate any of the requests. Use the `AddOAuth` option to override this and actually force *all* operations to use authentication.

`AddOAuth` is used with choosing a name for this authentication flow. That name can then later be used when [implementing the logic for the authentication flow](./CustomizingGeneratedCode.md#authentication).

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified as additional property named `AddOAuth`.

Example:

```matlab
% Set the additionalProperties after initialization
client = openapi.build.Client();
client.additionalProperties('AddOAuth') = 'MyAuthName';

% Or, set during initialization
aProps = containers.Map
aProps('AddOAuth') = 'MyAuthName'
client = openapi.build.Client(additionalProperties=aProps)
```

````
````{tab-item} JSON Configuration
:sync: json

Specified as additional property named `AddOAuth`.

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "additionalProperties": {
            "AddOAuth": "MyAuthName"
        }
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified as additional property named `AddOAuth`.

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --additional-properties AddOAuth=MyAuthName
```
````
`````


## ObjectParams

Specifies that certain parameters are to be treated as properties set on the client object rather than input parameters to specific operations.

For example, (virtually) all operations in all Microsoft Azure services are versioned and this version must be passed along as query parameter (`api_version`) to each and every operation separately. Often you also have to specify a `resourceGroupName`. By default, MATLAB clients generated for these services would then also require these parameters as input to each and every method call. Use `ObjectParams` to specify that such parameters can be set as a property of the client object rather than having to provide them as inputs to each and every method call.

So then in the end when working with the client instead of having to write:

```matlab
client = myPackage.api.SomeClient;
% Apart from providing method specific inputs, also specify the same
% version and resource group parameter over-and-over again
client.someMethod(someInputSpecificToSomeMethod,"2023-10-01","myResourceGroup")
client.otherMethod(someInputSpecificToOtherMethod,"2023-10-01","myResourceGroup")
% etc
```

This could then become:

```matlab
% Specify the common parameters once, on the client level
client = myPackage.api.SomeClient(api_version="2023-10-01",resourceGroupName="myResourceGroup");
% Now only the method specific inputs have to be provided
client.someMethod(otherInputSpecificToSomeMethod)
client.otherMethod(otherInputSpecificToOtherMethod)
% etc
```

Where it would then also be possible to [set default values for these object properties using a configuration file](./BasicUsage.md#set-properties-using-a-configuration-file).

`````{tab-set}
````{tab-item} MATLAB
:sync: matlab

Specified through the `objectParameters` property. Specified as `containers.Map` where the keys are the parameter name and the values are the parameter data types.

Example:

```matlab
% Set the additionalProperties after initialization
client = openapi.build.Client();
client.objectParameters('api_version') = 'string';
client.objectParameters('resourceGroupName') = 'string';

% Or, set during initialization
oParams = containers.Map
oParams('api_version') = 'string';
oParams('resourceGroupName') = 'string';
client = openapi.build.Client(objectParameters=oParams)
```

````
````{tab-item} JSON Configuration
:sync: json

Specified as additional property named `objectParameters`. The value of this property takes the form of:

```
NameOfParameter1/TypeOfParameter1/NameOfParameter2/TypeOfParameter2...
```

Example:

```json
{
  "$schema": "./node_modules/@openapitools/openapi-generator-cli/config.schema.json",
  "generator-cli": {
    "generators": {
      "v3.0": {
        "additionalProperties": {
            "objectParameters": "api_version/string/resourceGroupName/string"
        }
      }
    }
  }
}
```

````
````{tab-item} Command Line
:sync: cli

Specified as additional property named `objectParameters`. The value of this property takes the form of:

```
NameOfParameter1/TypeOfParameter1/NameOfParameter2/TypeOfParameter2...
```

Example:

```console
npx @openapitools/openapi-generator-cli generate ... --additional-properties objectParameters=api_version/string/resourceGroupName/string
```
````
`````