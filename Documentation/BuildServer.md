# Building MATLAB Server Code

The Server stub generator generates code which can eventually be deployed as MATLAB Compiler SDK Microservices or to MATLAB Production Server. The code it generates is compatible with the [Custom Routes and Payloads feature](https://www.mathworks.com/help/releases/R2024b/mps/custom-routes-and-payloads.html) of MATLAB Compiler SDK Microservices and MATLAB Production Server.

## Server stub generation

To generate the server stubs from inside MATLAB, use for example:

```matlab
% Run startup to configure the package's MATLAB paths
cd Software/MATLAB
startup

% Create a builder object
c = openapi.build.Server;

% Set the package name, defaults to "OpenAPIServer"
c.packageName = "MyServer";

% Set the path to the spec., this may also be a HTTP(S) URL
c.inputSpec = "openapi.yaml";

% Set a directory where the results will be stored
c.output = fullfile(pwd, "MyServer");

% Insert a copyright notice in generated code
c.copyrightNotice = sprintf("%% (c) %d My Company Name Inc.", year(datetime("now")));

% Trigger the build process
c.build;
```

This should produce a directory `MyServer` containing:

* `server.m` the main entry-point for the server, defining all the routes and handling requests.
* `routes.json` a MATLAB Production Server custom routes configuration file which maps all requests to the main `server.m` entrypoint.
* `buildfile.m` a [MATLAB Build Tool](https://www.mathworks.com/help/matlab/build-automation.html) build file which can help in creating the CTF-archive and packaging into Microservice Docker images.
* `+MyServer/+models` a directory containing model classes for the request and response payloads.
* `+MyServer/+impl` a directory containing the server stub implementations of the server endpoints.
* `+MyServer/+mws` a directory containing additional code which eases working with the Custom Routes and Payloads feature. This code does not have to be modified/customized.

The produced server code should then be further customized and implemented to handle the actual business logic of the server. The `+MyServer/+impl` directory contains the stub implementations that should be updated with the actual server-side logic.

## Server implementation

To implement the server-side logic, the generated code inside the `+MyServer/+impl` directory **must** be customized, it really only contains stub implementations with some _examples_ on how to access the function "inputs" and produce the correct "outputs". Other parts of the generated code should typically not have to be changed but can still be customized depending on your use-case. The sections below discuss the different parts of the code and how they can be customized/implemented.

If you do not make any changes to the generated code, the server should technically still be able to run, all generated code _should_ be valid MATLAB code; all methods will simply return `501 - Not Implemented` though. If you encounter a situation in which _truly invalid_ (e.g. syntactically incorrect) code is generated, please [submit a GitHub issue](https://github.com/mathworks-ref-arch/matlab-openapi-generator/issues).

### server.m

Typically `server.m` does not have to be modified. However it can be customized if you want to add additional endpoints to the server which are not part of the actual spec. Or when small changes are made to the  spec you can choose to manually update the code instead of regenerating it from scratch entirely.

`server.m` will have a structure similar to the following:

Overall it is a [Custom Routes and Payloads Web Request handler](https://www.mathworks.com/help/mps/server/use-web-handler-for-custom-routes-and-custom-payloads.html#mw_0756f11a-ac9b-47ec-9cea-8e69239907b1) which accepts a request structure as input and returns a response structure as output:

```matlab
function response = server(request)
```

Then instead of immediately trying to handle the raw request it creates an `MyServer.mws.Application` instance. This is a helper class which abstracts away some of the common request and response handling logic which are needed for all operations. This helper class only has to be created and configured once, and can then be reused for all consecutive requests. Therefore a `persistent` variable is used which is only instantiated when it has not been set yet, i.e. it is empty:

```matlab
    persistent app
    if isempty(app)
        % If it has not been set yet (i.e. on the first run), create the
        % instance
        app = MyServer.mws.Application();
```

This helper class also allows defining the routes inside code rather than a separate configuration file. This for example also makes it easier for the helper class to parse [path parameters](https://spec.openapis.org/oas/v3.0.3.html#parameter-object) from the URLs in a consistent and reusable way without needing a lot of duplicate code inside the operation specific handlers themselves. For example, for the [Petstore example](https://github.com/swagger-api/swagger-petstore), the following routes are added:

```matlab
        % Add the actual routes for the API
        %% Pet
        % Everything about your Pets
        app.post("/v3/pet",@MyServer.impl.Pet.addPet);
        app.del("/v3/pet/{petId}",@MyServer.impl.Pet.deletePet);
        app.get("/v3/pet/findByStatus",@MyServer.impl.Pet.findPetsByStatus);
        …
```

Where `app.post("/v3/pet",@MyServer.impl.Pet.addPet);` for example defines that when a POST request is made to path `/v3/pet`[^1], the `MyServer.impl.Pet.addPet` method should be called to further handle this specific request. And `app.del("/v3/pet/{petId}",@MyServer.impl.Pet.deletePet);` defines that a DELETE request to `/v3/pet/{petId}` (where `{petId}` is such an aforementioned path parameter) should be handled by the `MyServer.impl.Pet.deletePet` method.

[^1]: the `/v3` part in this example is an explicit part of the Petstore example, it is explicitly set in its spec. The OpenAPI server generator does _not_ add any versioning itself.

The routes definitions are grouped by the `tags` in the OpenAPI spec. Similarly the actual handler methods are organized in classes whose names are based on the same tags. For example, all operations with the `pet` tag are handled by the `MyServer.impl.Pet` class. And all operations with the `store` tag are handled by the `MyServer.impl.Store` class:

```matlab
        …
        %% Store
        % Operations about user
        app.del("/v3/store/order/{orderId}",@MyServer.impl.Store.deleteOrder);
        app.get("/v3/store/inventory",@MyServer.impl.Store.getInventory);
        …
```

After all the operations which were defined in the spec, one more endpoint is added which hosts the OpenAPI specification itself:

```matlab
        …
        % Add an endpoint which also simply serves the OpenAPI spec
        app.get("/v3/openapi{format}",@openApiSpec);
```

The handler for this (i.e. the `openApiSpec` function) is found at the very bottom of `server.m`. 

And then as final (optional) route, the code also shows how to add a SwaggerUI endpoint to the server, which would allow visualizing and interacting with the API directly in the browser:

```matlab
        % Optional, add a SwaggerUI endpoint.
        %   To add a SwaggerUI endpoint to the server. Create a directory
        %   named swagger in the same directory as this file and "install"
        %   SwaggerUI in it, see https://github.com/swagger-api/swagger-ui/blob/HEAD/docs/usage/installation.md#plain-old-htmlcssjs-standalone
        %   Then uncomment the lines below.
        %app.use("/v3/swagger",mws.Static.newHandler( ...
        %    LocalPath=fullfile(fileparts(mfilename("fullpath")),"swagger"),...
        %    MountPath="/v3/swagger"));
```

As the code documents, this would require you to create a directory named `swagger` in which you will have to place the SwaggerUI files. The easiest most straightforward option is to make use of the [unpkg approach](https://github.com/swagger-api/swagger-ui/blob/HEAD/docs/usage/installation.md#unpkg) where you just have to create a single `index.html` in the `swagger` directory and where further dependencies are then loaded from [unpkg](https://unpkg.com/). If you would like to host these dependencies yourself, use the [Plain old HTML/CSS/JS (Standalone) approach](https://github.com/swagger-api/swagger-ui/blob/HEAD/docs/usage/installation.md#plain-old-htmlcssjs-standalone). For both approaches update the HTML code such that it point to the endpoint which hosts the OpenAPI specification, i.e. in the example above `/v3/openapi.json` or `/v3/openapi.yaml`. 

If you want to add any further additional routes which are not directly part of the spec, this would then be the place to do so.

After all the route definitions, the one-time initialization ends:

```matlab
    end
```

And then the final line of the main `server` function, calls the `handleRequest` method on this (now fully configured) helper class to handle the incoming request and produce the response:

```matlab
    % Let the Application class handle the raw custom payload
    response = app.handleRequest(request);
end
```

This part of the code will be run every single time a request is made to any endpoint of the API.

Finally, at the very bottom of `server.m` we then also find the implementation of the `openApiSpec` function, which is used to handle the request to the `/v3/openapi{format}` endpoint. This endpoint serves the OpenAPI specification itself, either in JSON or YAML format:

```matlab
function openApiSpec(req,res,~)
…
end
```

### routes.json

Given the design of `server.m` above, i.e. with that helper class, there is really just one single entrypoint for the entire API. So, the [URL Routes](https://www.mathworks.com/help/mps/server/use-web-handler-for-custom-routes-and-custom-payloads.html#mw_1c57566a-9876-44ca-9f07-f67709bfb3f1) configuration file just needs to define one single route which maps all request (on a specific base-path) to `server.m`. So the generated `routes.json` will typically look something like:

```json
{
  "version": "1.0.0",
   "pathmap": [
       {
           "match": "/v3/.*",
           "webhandler": {
               "component": "Test",
               "function": "server"
           }
       }
    ]
}
```

### +MyServer/+models

Typically the generated models do not have to be manually modified but they can for example be manually updated if the spec changes and you do not want to fully regenerate the code from scratch. If you do want to customize the models, it is recommended to first [read up on the JSONMapper class](./JSONMapper.md) which the models derive from.

To learn more about how to work with the generated models as-is, you can [refer to the Basic Usage section](./BasicUsage.md#models). The generated models for servers are exactly the same as models generated for clients, so the same patterns apply.

### +MyServer/+impl

Inside the `+MyServer/+impl` directory a MATLAB class file will have been generated for each tag in the OpenAPI spec. Each class in turn contains a number of static methods which are the actual handler functions for the routes/operations in the spec. I.e. in the example above where path `/v3/pet` was mapped to method `MyServer.impl.Pet.addPet`: `addPet` is a static method in the `Pet` class which is in the `MyServer.impl` namespace. Where the `Pet` class M-file is then located at `+MyServer/+impl/Pet.m`.

Each of the methods will have a signature like the following:

```matlab
function myOperation(req,res,~)
```

Where `req` is a {class}`Request` object which contains more information about the incoming request like the full path of the request, the path parameters, query parameters, headers and the request body. And `res` is a {class}`Response` object which can be used to form the response which is to be send back to the client; the function does not have an actual output itself but you interact with the response object to define the response. The third input must be defined but is currently unused by the generated code and therefore it is defined as an [ignored input `~`](https://www.mathworks.com/help/matlab/matlab_prog/ignore-function-inputs.html), it may be used in future versions.

The generator may also have generated pieces of example code for each method. The accuracy and completeness of these examples will depend on the accuracy and the completeness of the spec. For example if the spec defines a request body, the generator will show how this can be parsed into a model and how you can verify that all, according to the spec, requires properties are set. But this obviously will not work if you only "intended" there to be a body but it was not actually properly defined in the spec. Similarly the code may show how you can start defining a response body and how you can use the Response object to return this to the client _if_ the response body is properly defined in the spec.

Further note that these examples are indeed just that: _examples_. You are expected to review the examples, understand the patterns and conventions used, and then build upon them to implement the full functionality required for your API. The generator can give you a head start, but you will need to complete the implementation yourself to match your specific requirements.

```{caution}
The values of all "input" (e.g. path, query) parameters which you receive in the handler functions will always be strings. If you need to convert these strings to numerical values **never** use {func}`str2num` for the conversion. Its usage of {func}`eval` can lead to security vulnerabilities.
```

For a more detailed overview on how to work with the {class}`Request` and {class}`Response` classes, see [](./ServerRequestResponse.md).

### buildfile.m

The generated `builfile.m` is a [MATLAB Build Tool](https://www.mathworks.com/help/matlab/build-automation.html) build file which can help with building the server into a CTF-archive which can the be deployed to MATLAB Production Server or be packed into a Microservice Docker image. It is not required to customize the generated `buildfile.m`, unless your implementation requires additional files to be added to the archive (i.e. if somehow the [dependency analysis](https://www.mathworks.com/help/compiler_sdk/ml_code/dependency-analysis-function.html) is not able to automatically include all required dependencies). Further, `buildfile.m` can be customized to change certain defaults (like the name of the output directory or the default tag of the Microservice Docker image).

## Server testing

The server code can be tested inside MATLAB using the testing interface of the {app}`Production Server Compiler` app. Since the generated server makes use of the Custom Routes and Payloads feature, it is important to configure the testing interface to work with the correct `routes.json` file. Set environment variable `PRODSERVER_ROUTES_FILE` to point to the generated `routes.json` file before starting the testing interface, for example using:

```matlabsession
>> setenv('PRODSERVER_ROUTES_FILE','MyServer/routes.json');
```

For more details see:

<https://www.mathworks.com/help/compiler_sdk/mps_dev_test/test-web-request-handler.html>

Then start the {app}`Production Server Compiler` app and:

1.  Set the `Archive Name` to the Package Name (i.e. in the example above `MyServer`).
2.  Add `server.m` as exported function.

You should then be able to start the test server under "Test Client" → "Start".

## Server deployment

Once all server logic has been implemented, it can be compiled into a CTF-archive using the {app}`Production Server Compiler` app, {func}`mcc` or {func}`compiler.build.productionServerArchive`. The resulting archive can then be packaged into a Microservice Docker image using {func}`compiler.package.microserviceDockerImage` or deployed to a MATLAB Production Server instance.

As discussed above, the generator also generates a [MATLAB Build Tool](https://www.mathworks.com/help/matlab/build-automation.html) `builfile.m` which should allow you to build the CTF-archive inside MATLAB using:

```matlabsession
>> buildtool build
```

It can also package the server into a Microservice Docker image using `buildtool microservice("image-name")` (where `image-name` allows you to specify the name/tag of the Docker image).

The generated `buildfile.m` is configured in such a way that it should automatically include all the relevant files and directories. See the sections below to learn more about which files and directories should be included.

### Building the archive 

Before/when creating the final package it is important to ensure that the "Archive Name" (`ArchiveName` option when working with {func}`compiler.build.productionServerArchive`) is set to the package name, e.g. `MyServer` (or to update the generated `routes.json`; update the `component` setting with whatever archive name you choose). Further, it is important that the following files are included: 

1.  `server.m` should be included as "exported function" (`FunctionFiles` option when working with {func}`compiler.build.productionServerArchive`).

2.  `openapi.json` and `openapi.yaml` should be manually added as "Additional files required for your archive to run" (`AdditionalFiles` when working with {func}`compiler.build.productionServerArchive`).

3.  If you have a `swagger` directory with the SwaggerUI implementation, that directory should also be manually added as "Additional files required for your archive to run" (`AdditionalFiles`).

4.  All other dependencies (like the model files, etc.) _should_ automatically be picked up by the MATLAB Compiler SDK dependency analysis. However, to be 100% certain, you can also manually add the entire `+MyServer` directory[^2] to "Additional files required for your archive to run" (or `AdditionalFiles`).

[^2]: It is possible to add entire directories using this option despite it being called "files"

### Archive deployment

When building a Microservice Docker image using {func}`compiler.package.microserviceDockerImage`, ensure to configure the `RoutesFile` property to point to the generated `routes.json` file. 

When deploying to MATLAB Production Server, copy the CTF-archive to the `auto_deploy` folder, configure the `routes.json` file on the server instance based on the generated `routes.json` file and (re)start the instance.

[//]: #  (Copyright 2025 The MathWorks, Inc.)