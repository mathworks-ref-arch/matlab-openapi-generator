# Server Generation Example

This example is a variation of the [Deploying a Simulation App with Simulink Compiler](https://www.mathworks.com/help/slcompiler/ug/deploy-mass-springr-app-with-simulink-compiler.html) example from the [Simulink Compiler](https://www.mathworks.com/products/simulink-compiler.html) documentation. Only, instead of deploying the model as a MATLAB App with an interactive graphical user interface in which an end-user can enter various parameters for the simulation, the model is going to be deployed as an API. This API should still have an easy-to-use and well defined interface.

To accomplish this, we first actually define the interface using an OpenAPI specification. Doing this first, rather than immediately jumping into MATLAB developing code and worrying about interfaces later, has several advantages:

1.  This interface forms a contract between server and client. Both sides know exactly what to expect from the other side. On the server side it is clear what inputs you can expect and you know exactly what outputs you need to provide. The client knows exactly how it can interact with the server; it knows which inputs it needs to provide and which outputs it can expect. 

1.  As a matter of fact, once the interface has been defined, a client developer could already immediately start developing the client even before the server is fully ready; actual implementation work can be done in parallel once the interfaces have been defined.

1.  Parts of both the client and server side can automatically be generated from the spec and do not have to be hand coded. In this example we the MATLAB Generator *for OpenAPI* package to generate part of the server side. And for the client side, [many other generators](https://openapi-generator.tech/docs/generators) are available[^1].

[^1]: Note that theoretically, it is also possible to use the MATLAB Generator *for OpenAPI* package to generate a MATLAB client. However if your MATLAB Production Server deployed functions are exclusively going to be called from MATLAB only, it may make more sense to work with MATLAB Production Server's standard interface and [MATLAB Client for MATLAB Production Server]() instead of going through these OpenAPI based workflows.

Code for the example can be found in:

```
Software/MATLAB/examples/server/simulink
```

If you want to _fully_ follow along this example you will need [Simulink Compiler](https://www.mathworks.com/products/simulink-compiler.html). However, even if you do not have Simulink Compiler you can still follow along this example for the most part but you will not be able to package the final CTF-archive. Also the concepts demonstrated in the example are transferable to other toolboxes, use-cases and APIs.

## Interface definition

### Path

First, we need to think about the path/URL on which the function can be called. It is probably good to group all operations in our package together below a path named after the package, so we can for example come up with a base path of `/openapi-example`. 

Then, in this example we will just add one model to the server, but in the future perhaps multiple models can be added, so it could be a good idea to define a path like `/sim` which represents "run a simulation". 

And then after that we can add a model name like `/mass-spring-damper`. Meaning our model then becomes callable as `/openapi-example/sim/mass-spring-damper`.

If in the future we want to add additional models to the package they could be made available as `/openapi-example/sim/some-new-other-model`.

### Input body

To define the interface for our specific example model we are going to take some inspiration from the GUI of the original example where the inputs are split into three main sections "Parameters", "Randomly Generated Force Input" and a global "Max number of points per signal" setting. And, we will actually replace this "Max number of points per signal", which in the original example configured how many points to plot of the simulation which actually runs indefinitely, with a parameter Stop Time which represents for how long to run the simulation; in our API the model will not be able to run indefinitely it actually has to stop at some point and return the results.

So on a higher level we want the inputs to look something like:

```json
{
    "parameters": {
        // Parameters go here
    },
    "inputs": {
       // Inputs go here 
    },
    "stopTime": 1000
}
```

Further, we are going to make an enhancement to the inputs, instead of only allowing the client to specify parameters to define a randomly generated input for the model, we will also allow the client to provide an exact input in the form of an array of doubles representing the input force, in combination with a time vector.

So the client will then be able to either call the endpoint with an input body like this:


```{code-block} json
:name: random-input-example
:caption: Random Input Example

{
  "parameters": {
    "m": 10,  // Mass
    "k": 100, // Stiffness
    "b": 1,   // Damping
    "x0": 0   // Initial Position
              //   Just as an example we will make x0 an optional parameter (default: 0)
  },
  "inputs": {
    "inputType": "MassSpringDamperRandomInput", // Extra property added to specify what type of input
                                // the client wants to provide RandomInput or ExactInput
    // If MassSpringDamperRandomInput, provide the parameters with which the server should generate the random input signal
    "maxMagnitude": 100,        // Max Magnitude
    "inputChangeInterval": 100, // Input Change Interval
    "seed": 1                   // Rand Stream Seed
                                // As an example this is also an optional setting (default: 0)
  },
  "stopTime": 1000 // The stop time of the model
                   // As an example this will also be an optional property (default: 1000)
}
```

or like this:

```{code-block} json
:name: exact-input-example
:caption: Exact Input Example

{
  "parameters": {
    "m": 10,  // Mass
    "k": 100, // Stiffness
    "b": 1,   // Damping
    "x0": 0   // Initial Position
              //   Just as an example we will make x0 an optional parameter (default: 0)
  },
  "inputs": {
    "inputType": "MassSpringDamperExactInput", // Extra property added to specify what type of input
                               // the client wants to provide RandomInput or ExactInput
    // If MassSpringDamperExactInput, provide the Input Force
    "F": { // Input Force
        "Time": [0,1,2],            // Time at which the force is specified
        "Data": [0.0, 2.718, 3.1415] // Samples of the force at those times
    }
  },
  "stopTime": 1000 // Stop time of the model
                   //   As an example this will also be an optional property (default: 1000)
}
```

Note how for the `inputs` field, we added an extra `inputType` property here which allows the client to specify whether it wants to work with a randomly generated input or with an exact input and then the other properties of the `inputs` field change accordingly. All of this (i.e. the "polymorphism") _can_ actually be specified in an OpenAPI spec and our generators _do_ support these constructs.

### Response Body

We then need to think about what the endpoint will return. The model has two actual outputs plus one logged signal, it makes sense to return these and it probably makes sense to use a format similar to what was used to allow providing the (exact) input force input signal (i.e. using a `Time` and `Data` vectors which mimics MATLAB's {class}`timeseries` somewhat). Also, if a randomly generated input signal was used, it probably makes sense to return this to the client so it knows what was generated exactly.

```json
{
  "F": { // Input Force, only included if it was generated, 
         // if it was provided as input by the client,
         // it already knows what this looks like
    "Time": [
      0, 1, 2
    ],
    "Data": [
      0, 2.17, 3.14
    ]
  },
  "a": { // Acceleration
    "Time": [
      0, 1, 2
    ],
    "Data": [
       0.9134, 0.6324, 0.0975
    ]
  },
  "v": { // Velocity
    "Time": [
      0, 1, 2
    ],
    "Data": [
      0.2785, 0.5469, 0.9575
    ]
  },
  "x": { // Position
    "Time": [
      0, 1, 2
    ],
    "Data": [
      0.9649, 0.1576, 0.9706
    ]
  }
}
```

```{note}
In this example all `Time` vectors are the same, but note that in general this does not have to be the case, Simulink may have determined simulation timesteps which differ from the timesteps of the input signals and outputs may have different rates; that is also why we repeat `Time` for each signal separately and we do not use a common `Time` vector for all signals.
```

### OpenAPI Spec

Now that we have come up with a good interface for the API, we should properly record it in an OpenAPI spec.

We start with the header of the file:

```yaml
# The version of OpenAPI in which we are writing this spec
openapi: 3.0.3 
# High-level information about our API
info:
  # A title for the API
  title: MATLAB Simulation Server
  # A description for the API
  description: Run simulations of various Simulink models
  # The version of our API, this can for example change if you additional models
  # and endpoints to the API or if the in- or output of an existing endpoint was
  # changed.
  version: 0.1.0
```

Then we define a list of servers to which our API may be deployed:

```yaml
# An array of known servers which may be hosting our API
servers:
  - url: http://localhost:9910/openapi-example          # The base URL of the API
    description: Local Testing MATLAB Production Server # Description
```

Note that a client can always choose to override the server address and base path but if you have one or more dedicated servers on which this service is going to run, adding them can help the client with finding the right one. In the example here, we add the typical local address of a testing server.

After that we define the paths/endpoints and we add our `/sim/mass-spring-damper` endpoint:

```yaml
# Start defining the actual paths
paths:
  # Add our API path
  /sim/mass-spring-damper:
    # Specify that this is a POST operation
    post:
      # Give the generators a hint on what they could name the method for calling this operation could be
      operationId: SimMassSpringDamper
      # Generators typically group operations by tag, for example creating a namespace for each tag
      # and grouping the operations with the same tag inside this namespace. Or by creating a class
      # with this name and then adding the operations as methods.
      tags: [Simulation]
      # A high-level summary of the operation, generators may include this in code comments or 
      # documentation generators will use it 
      summary: Mass Spring Damper Model
      # A more in-depth description of the operation
      description: |
         Run a simulation... (truncated here, see openapi.yaml in the example directory)
      # Define the input request body
      requestBody:
        # Specify that this request really requires a request body always
        required: true
        # Describe the body
        description: Request Body for Simulating the mass spring damper model
        # Define what the request body should look like
        content:
          # Specify that it expects JSON
          application/json:
            # Describe what this JSON should look like
            schema:
              # It is possible to describe the whole request body here, instead in this example
              # we choose to define it separately further down in our spec and refer to it here.
              # You typically do this for both readability and reusability. Also this typically
              # allows generators to generate cleaner code, it can use the names of these schemas
              # when it is generating names for model classes.
              $ref: "#/components/schemas/MassSpringDamperRequest"
      # Define what the response body will look like
      responses:
        # Specify that the endpoint may respond with code 200 (OK)
        "200":
          description: Results of the simulation
          content:
          # Specify that the response body will be in JSON as well
            application/json:
              # Describe what this JSON will look like
              schema:
                # Again refer to a definition further down in the OpenAPI spec
                $ref: "#/components/schemas/MassSpringDamperResponse"
        # We also define two other possible responses, one for when the client called
        # the operation with an incorrect/invalid request
        "400":
          description: The operations was called incorrectly by the client
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ErrorResponse"
        # And one for when an error occurs in the MATLAB code or simulation
        "500":
          description: An error occurred in the MATLAB code or simulation
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/ErrorResponse"
```

Now we can start defining those JSON schemas for the request and response bodies

```yaml
# These separate definitions are always done below components
components:
  # And we are actually defining schemas here
  schemas:
    # Define the request body for the mass-spring-damper model
    MassSpringDamperRequest:
      description: Request body for the Mass Spring Damper Model
      # The main request body is an object with a number of properties
      type: object
      # Define each of the properties
      properties:
        # Add the parameters field
        parameters:
          # Again this could be defined inline, but we choose to
          # split this into a separate definition and refer to it
          $ref: "#/components/schemas/MassSpringDamperParameters"
        # Add the inputs field
        inputs:
          $ref: "#/components/schemas/MassSpringDamperInput"
        # Add the stopTime field, this field is just a simple scalar number
        # so we do define it here without further references to definitions elsewhere
        stopTime: 
          description: Simulate the model until this specified stop time
          # Since we wanted this parameter to be optional we do also tell clients
          # which default the server will use if the value is not specified
          default: 1000
          # The data type for this field is a double which in OpenAPI is specified
          # by setting type = number and format = double
          type: number
          format: double
      # Specify which of the fields/properties are required
      required:
        - parameters
        - inputs
```

So now we then need to define those `MassSpringDamperParameters` and `MassSpringDamperInput` schemas which we referred to above, starting with `MassSpringDamperParameters`:

```yaml        
    # Define the MassSpringDamperParameters schema
    MassSpringDamperParameters:
      description: Tunable Parameters for the Mass Spring Damper Model
      # This one is actually pretty straightforward, it is an object
      # with a number of properties/fields and each of the fields
      # is simply a scalar double
      type: object
      properties:
        m:
          description: mass (kg)
          type: number
          format: double
        k:
          description: Stiffness (N/m)
          type: number
          format: double
        b:
          description: Damping (N/m/s)
          type: number
          format: double
        x0:
          description: Initial Position (m)
          # Again, we decided that x0 should be optional, so inform
          # clients what the assumed default is when omitted
          default: 0
          type: number
          format: double
      # Also, again specify which of the properties are required
      # (i.e. all expect x0)
      required:
        - m
        - k
        - b
```

Followed by the `MassSpringDamperInput` schema. For this schema we will do something slightly more complicated. Remember, we wanted the client to be able to either provide parameters which the server can then use to generate a random input signal _or_ provide an exact input signal as is. To allow this we will define a small "schema hierarchy" (similar to class hierarchies; typically OpenAPI generators will in fact generate class hierarchies for them when generating a client or server) where there is a base schema `MassSpringDamperInput` and then there are two child schemas `MassSpringDamperRandomInput` and `MassSpringDamperExactInput` which derive from it:

```{mermaid}
classDiagram
    MassSpringDamperInput <|-- MassSpringDamperRandomInput
    MassSpringDamperInput <|-- MassSpringDamperExactInput
    class MassSpringDamperInput{
      string inputType
    }
    class MassSpringDamperRandomInput{
      double maxMagnitude
      double inputChangeInterval
      double seed
    }
    class MassSpringDamperExactInput{
        SimulinkTimeSeries F
    }
```

The base schema (and the schemas derived from it) are going to have that `inputType` property which allows the client to explicitly specify what type of input (random or exact) it wants to work with. And `MassSpringDamperRandomInput` then adds the `maxMagnitude`, `inputChangeInterval` and `seed` parameters whereas `MassSpringDamperExactInput` adds this field named `F` representing the input force over time.

So now, let's first define the base `MassSpringDamperInput` class:

```yaml
    # Define the MassSpringDamperInput base class
    MassSpringDamperInput:
      description: Model Input Signal for the Mass Spring Damper Model
      # It is an object with one property
      type: object
      properties:
        # Add the inputType property
        inputType:
          # It is of type string
          type: string
      # This one field is required
      required:
        - inputType
      # And we also define it to be a discriminator. This allows generators
      # to generate code which can use the value of inputType to then determine
      # whether it should really return a MassSpringDamperRandomInput or
      # MassSpringDamperExactInput
      discriminator:
        propertyName: inputType
```

And then the derived `MassSpringDamperRandomInput` schema:

```yaml
    # Define child schema MassSpringDamperRandomInput      
    MassSpringDamperRandomInput:
      description: Parameters for generating a random input signal for the Mass Spring Damper Model
      # Now to define a child schema you can use this allOf keyword. We are going to say
      # MassSpringDamperRandomInput is going to have all properties of MassSpringDamperInput
      # (i.e. inherits from MassSpringDamperInput) plus a few additional properties which are
      # specific to this child schema.
      allOf:
        # Refer to the parent schema to inherit all of its properties
        - $ref: "#/components/schemas/MassSpringDamperInput"
        # Add additional properties specific to this derived schema.
        # All those properties are simple double scalars again
        - type: object
          properties:
            maxMagnitude:
              description: Max maxMagnitude (N)
              type: number
              format: double
            inputChangeInterval:
              description: Input Change Interval (s)
              type: number
              format: double
            seed:
              description: Random Stream Seed
              default: 0
              type: number
              format: double
          required:
            - maxMagnitude
            - inputChangeInterval
```

In a similar way we can define the other child schema `MassSpringDamperExactInput`:

```yaml
    # Define child schema MassSpringDamperExactInput      
    MassSpringDamperExactInput:
      description: An exact model input signal for the Mass Spring Damper Model
      # Again use allOf to inherit from the parent schema and add additional
      # properties specific to this particular child schema
      allOf:
        - $ref: "#/components/schemas/MassSpringDamperInput"
        - type: object
          properties:
            F:
              description: Force (N)
              # As discussed above this input signal is going to be defined
              # using Time and Data vectors, we again use a separate schema
              # to define this type and refer to it here
              $ref: "#/components/schemas/SimulinkTimeSeries"
          required:
            - F
```

Where we have again introduced a new schema `SimulinkTimeSeries` which we then have to define: 

```yaml            
    # Define the data object with fields Time and Data which are both arrays of doubles
    SimulinkTimeSeries:
      description: |
        A Simulink Signal specified in the form of a Time vector specifying at which exact points in time the samples are specified
        and a Data vector representing the signal samples at the specified times.
      type: object
      properties:
        Time:
          description: Time values
          # Specify that this is an array
          type: array
          # And inside the array, the items
          items:
            # are doubles
            type: number
            format: double
        Data:
          description: Sample data
          type: array
          items:
            type: number
            format: double
```

There is now one last schema which we need to define, the schema of the response body `MassSpringDamperResponse`:

```yaml            
    # Define the response body schema
    MassSpringDamperResponse:
      description: Output signals of the model and if a randomly generated input signal was used, also the input signal
      # Again this is an object with a number of properties, one for each of the output signals
      type: object
      properties:
        F:
          description: Input force (only returned if working with a randomly generated input)
          # And now here we can in fact reuse the SimulinkTimeSeries schema.
          $ref: "#/components/schemas/SimulinkTimeSeries"
        a:
          description: Acceleration
          $ref: "#/components/schemas/SimulinkTimeSeries"
        v:
          description: Velocity
          $ref: "#/components/schemas/SimulinkTimeSeries"
        x:
          description: Position
          $ref: "#/components/schemas/SimulinkTimeSeries"
      required:
        - a
        - v
```

Where once more we referred to another schema `SimulinkTimeSeries`, only in this case that one is already defined, we were simply able to reuse what we defined for the input signal.

The final schema which we then need to define is the `ErrorResponse`, which we keep relatively simple, it is going to be an object with one field `error_message` which is simply going to contain an error message:

```yaml
    ErrorResponse:
      description: An object containing the error message if an error has occurred
      type: object
      properties:
        error_message:
          type: string
```


In the end, when everything is combined we should get the following full spec:

```{literalinclude} ../Software/MATLAB/examples/server/simulink/openapi.yaml
:language: yaml
:caption: Software/MATLAB/examples/server/simulink/openapi.yaml
```

## Server generation

With the spec now in place we can generate the server stubs:

```matlabsession
>> cd Software/MATLAB/examples/server/simulink
>> s = openapi.build.Server(inputSpec="openapi.yaml",output="server",packageName="SimulationServer");
>> s.build;
Building client, executing command:
  java  -cp "/work/openapi/openapicodegen/Software/MATLAB/lib/jar/openapi-generator-cli-7.13.0.jar:/work/openapi/openapicodegen/Software/MATLAB/lib/jar/MATLAB-openapi-generator-3.0.0.jar" org.openapitools.codegen.OpenAPIGenerator generate --generator-name matlab-server --input-spec "openapi.yaml" --output "server" --package-name "SimulationServer" --template-dir "/work/openapi/openapicodegen/Software/Mustache" --additional-properties openapiRoot="/work/openapi/openapicodegen/Software/MATLAB",packageVersion=3.0.0 --skip-validate-spec

build completed, output directory: server
```
## Inspect the generated code

### server.m

Once the code has been generated, we can have a closer look at it. `server.m` in this case does not contain much, it simply contains the [standard code we expect to find in `server.m`](./BuildServer.md#serverm); it defines the one specific route for our `/openapi-example/sim/mass-spring-damper` path and all the rest is standard `server.m` code:

```matlab
…
app.post("/openapi-example/sim/mass-spring-damper",@SimulationServer.impl.Simulation.simMassSpringDamper);
…
```

Note though, how apart from the path, we also see a few other things which we defined in the spec coming back here. For example, the handler function here is named `SimulationServer.impl.Simulation.simMassSpringDamper` where `Simulation` comes from the `tags` which we set in the spec and `simMassSpringDamper` is the `operationId` which we specified.

Further, `SimulationServer` is the `packageName` which we specified when we generated the server stubs and `impl` is a fixed part which stands for "implementation" to signify that this package really is supposed to provide the actual implementation (and not just defines an interface).

Basically `server.m` is fine as-is and we won't have to modify it at all to correctly implement the server.

### SimulationServer.impl.Simulation.simMassSpringDamper

It is much more interesting to look at the handler method `SimulationServer.impl.Simulation.simMassSpringDamper` and see what has been generated. It starts with:

```matlab
function simMassSpringDamper(req,res,~)
    % simMassSpringDamper Mass Spring Damper Model
    % Run a simulation of the following Simulink Model:  ![](https://www.mathworks.com/help/examples/simulinkcompiler/win64/DeployingASimulationAppUsingSimulinkCompilerExample_01.png)  The mass-spring-damper model consists of discrete mass nodes distributed  throughout an object and interconnected via a network of springs and dampers.  This model is well-suited for modeling object with complex material  properties such as non-linearity and elasticity.  The model is parameterized using the following four tunable parameters which can be specified in the API call: * Mass - `m`. * Spring stiffness - `k`. * Damping - `b`. * Initial position - `x0`.  The model has an `External Force` input signal. The input signal can be randomly generated as part of the simulation run. Alternatively, it is possible to provide an exact input signal as part of the API request.  The model has two actual outputs `Position` and `Velocity` and since `Acceleration` is logged, it is returned as well. Further, when working with a randomly generated input signal, the input signal which was generated is returned as well.  Finally, it is possible to specify the stop time of the model. 
    %
    % Required parameters:
    %   MassSpringDamperRequest - Request Body for Simulating the mass spring damper model, Type: MassSpringDamperRequest
    %       Required properties in the model for this call:
    %           parameters
    %           inputs
    %       Optional properties in the model for this call:
    %           stopTime
    %
    % No optional parameters
    %
    % Responses:
    %   200: Results of the simulation
    %   400: The operations was called incorrectly by the client
    %   500: An error occurred in the MATLAB code or simulation
    %
    % Returns: MassSpringDamperResponse
    %
    % See Also: SimulationServer.models.MassSpringDamperResponse
    arguments
        req SimulationServer.mws.Request
        res SimulationServer.mws.Response
        ~
    end
```

Which [is a standard handler function](./BuildServer.md#myserverimpl) signature followed by a whole bunch of generated comments/help text in which we see all kinds of information from the spec coming back. `description` and `summary` fields have been used, we see it explicitly mentions the request requiring the request body and it even mentions which properties inside the request are required and optional.

```{note}
When it comes to required and optional fields/properties, only the top-level properties are mentioned, if there are nested objects which in turn may also contain required properties, those are not explicitly mentioned.
```

It also tells us what kind of response we should be generating in our handler. And it even mentions a helper model class `SimulationServer.models.MassSpringDamperResponse` which has been generated with can help with parsing and interpreting the request body; more on this later.

It then continues with some standard text and implementation which explains that we should indeed further customize this code:

```matlab
    % TODO implement SimulationServer.impl.Simulation.simMassSpringDamper

    % Depending on the level of detail of the OpenAPI spec,
    % the input parameters which this operation may require
    % or output bodies this operation may produce, various
    % pieces of example code may have been generated below.
    %
    % These are all just examples which should be further
    % customized. It is also possible to ignore the examples
    % altogether and replace the function body entirely with
    % your own code.

    % As long as the method is not yet implemented, return
    % status code 501. Remove these lines once the operation
    % has been fully implemented.
    res.SendStatus(501);
    return
```

And we then even get some example code on what an actual implementation can start to look like:

```matlab
    % This operation expects a MassSpringDamperRequest as input body - Request Body for Simulating the mass spring damper model
    % This can be parsed into a MATLAB MassSpringDamperRequest object using
    try
        input = SimulationServer.models.MassSpringDamperRequest().fromJSON(req.Body);
    catch 
        % In case parsing fails, return an error
        res.Status(400).SendText("Error parsing input body");
        return;
    end
    % Verify that required properties are set            
    requiredProperties = [...
        "parameters",...
        "inputs",...
    ];
    for prop = requiredProperties
        if isempty(input.(prop))
            res.Status(400).SendText(sprintf("Required body parameter '%s' has not been set.",prop)); 
            return
        end
    end
```

In here we again see this helper model `SimulationServer.models.MassSpringDamperRequest` coming back which we will have a closer look at in the next section. And we also see that some code has been generated which can help with verifying the inputs, it checks that all required properties of the request body have indeed been set.

```{note}
This check is only automatically implemented on the top-level input request object. If the object contains nested other objects, no code is automatically generated to check whether these nested objects also have all their required properties set. You would have to implement such checks by yourself if you need them.
```

Finally, it provides examples on how we could start on returning the output signals or return an error response:

```matlab
    % This operation may respond with status code 200 and a body of type MassSpringDamperResponse - Results of the simulation
    % Such a response can be formed in MATLAB using
    output = SimulationServer.models.MassSpringDamperResponse();

    % Write your code to fill out the values of output here

    % Write the output to the response
    res.Status(200).Json(output);

    % This operation may respond with status code 400 and a body of type ErrorResponse - The operations was called incorrectly by the client
    % Such a response can be formed in MATLAB using
    output = SimulationServer.models.ErrorResponse();

    % Write your code to fill out the values of output here

    % Write the output to the response
    res.Status(400).Json(output);    
    
    % This operation may respond with status code 500 and a body of type ErrorResponse - An error occurred in the MATLAB code or simulation
    % Such a response can be formed in MATLAB using
    output = SimulationServer.models.ErrorResponse();

    % Write your code to fill out the values of output here

    % Write the output to the response
    res.Status(500).Json(output);
    
    
end % simMassSpringDamper method
```

### Generated Models

Let have a closer look at `SimulationServer.models.MassSpringDamperRequest`. As shown in the generated code discussed in the previous section you can use the following to parse the JSON input into a MATLAB Object representation of the data:

```matlab
SimulationServer.models.MassSpringDamperRequest().fromJSON(jsonInput)

```

Let's explore this further and try this out with the input examples we had defined above.

First, if you are not already in the generated `server` directory:

```matlabsession
>> cd server 
```

And then try the {ref}`random-input-example`:

```matlabsession
>> randomInput = '{"parameters":{"m":10,"k":100,"b":1,"x0":0},"inputs":{"inputType":"MassSpringDamperRandomInput","maxMagnitude":100,"inputChangeInterval":100,"seed":1},"stopTime":1000}';
>> randomData = SimulationServer.models.MassSpringDamperRequest().fromJSON(randomInput)


randomData = 

  MassSpringDamperRequest with properties:

    parameters: [1×1 SimulationServer.models.MassSpringDamperParameters]
        inputs: [1×1 SimulationServer.models.MassSpringDamperRandomInput]
      stopTime: 1000

>> randomData.parameters

ans = 

  MassSpringDamperParameters with properties:

     m: 10
     k: 100
     b: 1
    x0: 0

>> randomData.inputs

ans = 

  MassSpringDamperRandomInput with properties:

           maxMagnitude: 100
    inputChangeInterval: 100
                   seed: 1
              inputType: "MassSpringDamperRandomInput"
```

Where we see that all the data has been parsed into easy to work with (nested) objects with properties set to the right values. Also note that in this case `inputs` quite specifically has become a `MassSpringDamperRandomInput` instance with indeed then `maxMagnitude`, `inputChangeInterval` and `seed` properties. Whereas if we try the {ref}`exact-input-example` we see that `inputs` then becomes a `MassSpringDamperExactInput` with a field `F` which in turn contains `Time` and `Data`.

```matlabsession
>> exactInput = '{"parameters":{"m":10,"k":100,"b":1,"x0":0},"inputs":{"inputType":"MassSpringDamperExactInput","F":{"Time":[0,1,2],"Data":[0.0,2.718,3.1415]}},"stopTime":1000}';
>> exactData = SimulationServer.models.MassSpringDamperRequest().fromJSON(exactInput)


exactData = 

  MassSpringDamperRequest with properties:

    parameters: [1×1 SimulationServer.models.MassSpringDamperParameters]
        inputs: [1×1 SimulationServer.models.MassSpringDamperExactInput]
      stopTime: 1000

>> exactData.parameters

ans = 

  MassSpringDamperParameters with properties:

     m: 10
     k: 100
     b: 1
    x0: 0

>> exactData.inputs

ans = 

  MassSpringDamperExactInput with properties:

            F: [1×1 SimulationServer.models.SimulinkTimeSeries]
    inputType: "MassSpringDamperExactInput"

>> exactData.inputs.F

ans = 

  SimulinkTimeSeries with properties:

    Time: [3×1 double]
    Data: [3×1 double]
```

The generated model code automatically takes care of such things. You basically get this functionality "for free" by working with an OpenAPI spec and a generator like this. Yes, there was some effort required in defining the spec properly, but once we did we get things like this for free.

## Server implementation

```{note}
This step and all following steps require Simulink Compiler, if you do not have this product available you can still read through the example in the documentation but you will not be able to fully follow along in MATLAB.
```

Now that we have a reasonable idea of the code which was generated for us, let's really implement the actual handler which will run the simulation and returns the results.

In this part we will be working in the `server` directory which was generated, if you are not in that directory yet:

```matlabsession
>> cd server 
```

And as a first step we will need to copy the example model into this directory, to obtain the model first we need to open the example:

```matlabsession
>> openExample('simulinkcompiler/DeployingASimulationAppUsingSimulinkCompilerExample','workDir','model')
```

Which will create a subdirectory `model` inside the `server` directory and it then copies in the example files including the model. We can then copy the model to the parent directory (`server`), go back into `server` and delete the `model` directory which we no longer need:

```matlabsession
>> copyfile('MassSpringDamperModel.slx','..')
>> cd ..
>> rmdir('model','s')
```

And we can then start really writing our implementation. The start of the function is mostly left as is. Obviously we remove the standard text which explains how to implement the function and we remove the `res.SendStatus(501)` placeholder. But other than that we only make two small changes to the generated code which returned errors to the client, we update this to use our specific `ErrorResponse` format instead:

```diff
function simMassSpringDamper(req,res,~)
    % simMassSpringDamper Mass Spring Damper Model
    % Run a simulation of the following Simulink Model:  ![](https://www.mathworks.com/help/examples/simulinkcompiler/win64/DeployingASimulationAppUsingSimulinkCompilerExample_01.png)  The mass-spring-damper model consists of discrete mass nodes distributed  throughout an object and interconnected via a network of springs and dampers.  This model is well-suited for modeling object with complex material  properties such as non-linearity and elasticity.  The model is parameterized using the following four tunable parameters which can be specified in the API call: * Mass - `m`. * Spring stiffness - `k`. * Damping - `b`. * Initial position - `x0`.  The model has an `External Force` input signal. The input signal can be randomly generated as part of the simulation run. Alternatively, it is possible to provide an exact input signal as part of the API request.  The model has two actual outputs `Position` and `Velocity` and since `Acceleration` is logged, it is returned as well. Further, when working with a randomly generated input signal, the input signal which was generated is returned as well.  Finally, it is possible to specify the stop time of the model. 
    %
    % Required parameters:
    %   MassSpringDamperRequest - Request Body for Simulating the mass spring damper model, Type: MassSpringDamperRequest
    %       Required properties in the model for this call:
    %           parameters
    %           inputs
    %       Optional properties in the model for this call:
    %           stopTime
    %
    % No optional parameters
    %
    % Responses:
    %   200: Results of the simulation
    %   400: The operations was called incorrectly by the client
    %   500: An error occurred in the MATLAB code or simulation
    %
    % Returns: MassSpringDamperResponse
    %
    % See Also: SimulationServer.models.MassSpringDamperResponse
    arguments
        req SimulationServer.mws.Request
        res SimulationServer.mws.Response
        ~
    end
    
-   % TODO implement SimulationServer.impl.Simulation.simMassSpringDamper
-
-   % Depending on the level of detail of the OpenAPI spec,
-   % the input parameters which this operation may require
-   % or output bodies this operation may produce, various
-   % pieces of example code may have been generated below.
-   %
-   % These are all just examples which should be further
-   % customized. It is also possible to ignore the examples
-   % altogether and replace the function body entirely with
-   % your own code.
-
-   % As long as the method is not yet implemented, return
-   % status code 501. Remove these lines once the operation
-   % has been fully implemented.
-   res.SendStatus(501);
-   return

    % This operation expects a MassSpringDamperRequest as input body - Request Body for Simulating the mass spring damper model
    % This can be parsed into a MATLAB MassSpringDamperRequest object using
    try
        input = SimulationServer.models.MassSpringDamperRequest().fromJSON(req.Body);
    catch 
        % In case parsing fails, return an error
-       res.Status(400).SendText("Error parsing input body");
+       res.Status(400).Json(SimulationServer.models.ErrorResponse(error_message="Error parsing input body"));
        return;
    end
    % Verify that required properties are set            
    requiredProperties = [...
        "parameters",...
        "inputs",...
    ];
    for prop = requiredProperties
        if isempty(input.(prop))
-           res.Status(400).SendText(sprintf("Required body parameter '%s' has not been set.",prop));         
+           res.Status(400).Json(SimulationServer.models.ErrorResponse(error_message=sprintf("Required body parameter '%s' has not been set.",prop))); 
            return
        end
    end
```

And then the remainder of the function becomes our actual implementation which:

1. Generates the input if necessary
1. Calls the model configured with the specified arguments and input
1. Forms the response based on the simulation results

```matlab
    % Run the entire actual code inside a TRY-CATCH such that if an
    % error occurs we can correctly return an ErrorResponse rather
    % than the code just erroring out which will lead to MATLAB
    % Production Server returning a generic error message
    try 
        % If no value specified for stopTime, use the default
        if isempty(input.stopTime)
            input.stopTime = 1000;
        end
        % If no value specified for x0, use the default
        if isempty(input.parameters.x0)
            input.parameters.x0 = 0;
        end
                
        % Set or generate the input signal based on the type of input that was
        % provided
        if input.inputs.inputType == "MassSpringDamperRandomInput"
            % If seed was not set use its default value
            if isempty(input.inputs.seed)
                input.inputs.seed = 0;
            end
            % Generate a random signal based on the provided properties
            rs = RandStream("mt19937ar", "Seed", input.inputs.seed);
            time = (0:input.inputs.inputChangeInterval:input.stopTime)';
            force = input.inputs.maxMagnitude * rand(rs,size(time));
            inputSignal = timeseries(force,time);
        elseif input.inputs.inputType == "MassSpringDamperExactInput"
            % Simply use the provided signal as is
            inputSignal = timeseries(input.inputs.F.Data,input.inputs.F.Time);
        else
            % Return an error
            res.Status(400).Json(SimulationServer.models.ErrorResponse(error_message="Invalid inputType specified")); 
            return
        end
        
        % Configure the inputs and parameters of the model based on the
        % provided inputs
        simIn = Simulink.SimulationInput('MassSpringDamperModel');
        % Set the force input signal
        simIn = simIn.setExternalInput(inputSignal);
        % Set the parameters
        simIn = simIn.setVariable('m',input.parameters.m,'Workspace','MassSpringDamperModel');
        simIn = simIn.setVariable('k',input.parameters.k,'Workspace','MassSpringDamperModel');
        simIn = simIn.setVariable('b',input.parameters.b,'Workspace','MassSpringDamperModel');
        simIn = simIn.setVariable('x0',input.parameters.x0,'Workspace','MassSpringDamperModel');
        % Set the stop time
        simIn = simIn.setModelParameter("StopTime",string(input.stopTime));
        % Needed for deployment using Simulink Compiler
        simIn = simulink.compiler.configureForDeployment(simIn);
        % Run the actual simulation
        out = sim(simIn);
        
        % Start building the response
        output = SimulationServer.models.MassSpringDamperResponse();
        % Fill-out all the signals based on the outputs from the model
        output.a(1).Time = out.logsout.get("acc").Values.Time;
        output.a(1).Data = out.logsout.get("acc").Values.Data;
        output.v(1).Time = out.logsout.get("vel").Values.Time;
        output.v(1).Data = out.logsout.get("vel").Values.Data;    
        output.x(1).Time = out.logsout.get("pos").Values.Time;
        output.x(1).Data = out.logsout.get("pos").Values.Data;    
        
        % In case a randomly generated input signal was used, also include it
        % in the output
        if input.inputs.inputType == "MassSpringDamperRandomInput"
            output.F(1).Time = inputSignal.Time;
            output.F(1).Data = inputSignal.Data;
        end

        % Write the output to the response
        res.Status(200).Json(output);
        return
    catch ME
        res.Status(500).Json(SimulationServer.models.ErrorResponse(error_message=ME.message));
        return
    end
```

Putting this all together then gives:

```matlab
function simMassSpringDamper(req,res,~)
    % simMassSpringDamper Mass Spring Damper Model
    % Run a simulation of the following Simulink Model:  ![](https://www.mathworks.com/help/examples/simulinkcompiler/win64/DeployingASimulationAppUsingSimulinkCompilerExample_01.png)  The mass-spring-damper model consists of discrete mass nodes distributed  throughout an object and interconnected via a network of springs and dampers.  This model is well-suited for modeling object with complex material  properties such as non-linearity and elasticity.  The model is parameterized using the following four tunable parameters which can be specified in the API call: * Mass - `m`. * Spring stiffness - `k`. * Damping - `b`. * Initial position - `x0`.  The model has an `External Force` input signal. The input signal can be randomly generated as part of the simulation run. Alternatively, it is possible to provide an exact input signal as part of the API request.  The model has two actual outputs `Position` and `Velocity` and since `Acceleration` is logged, it is returned as well. Further, when working with a randomly generated input signal, the input signal which was generated is returned as well.  Finally, it is possible to specify the stop time of the model. 
    %
    % Required parameters:
    %   MassSpringDamperRequest - Request Body for Simulating the mass spring damper model, Type: MassSpringDamperRequest
    %       Required properties in the model for this call:
    %           parameters
    %           inputs
    %       Optional properties in the model for this call:
    %           stopTime
    %
    % No optional parameters
    %
    % Responses:
    %   200: Results of the simulation
    %   400: The operations was called incorrectly by the client
    %   500: An error occurred in the MATLAB code or simulation
    %
    % Returns: MassSpringDamperResponse
    %
    % See Also: SimulationServer.models.MassSpringDamperResponse
    arguments
        req SimulationServer.mws.Request
        res SimulationServer.mws.Response
        ~
    end
    
    % This operation expects a MassSpringDamperRequest as input body - Request Body for Simulating the mass spring damper model
    % This can be parsed into a MATLAB MassSpringDamperRequest object using
    try
        input = SimulationServer.models.MassSpringDamperRequest().fromJSON(req.Body);
    catch 
        % In case parsing fails, return an error
        res.Status(400).Json(SimulationServer.models.ErrorResponse(error_message="Error parsing input body"));
        return;
    end
    % Verify that required properties are set            
    requiredProperties = [...
        "parameters",...
        "inputs",...
    ];
    for prop = requiredProperties
        if isempty(input.(prop))
            res.Status(400).Json(SimulationServer.models.ErrorResponse(error_message=sprintf("Required body parameter '%s' has not been set.",prop))); 
            return
        end
    end
    
    % Run the entire actual code inside a TRY-CATCH such that if an
    % error occurs we can corectly return an ErrorResponse rather
    % than the code just erroring out which will lead to MATLAB
    % Production Server returning a generic error message
    try 
        % If no value specified for stopTime, use the default
        if isempty(input.stopTime)
            input.stopTime = 1000;
        end
        % If no value specified for x0, use the default
        if isempty(input.parameters.x0)
            input.parameters.x0 = 0;
        end
                
        % Set or generate the input signal based on the type of input that was
        % provided
        if input.inputs.inputType == "MassSpringDamperRandomInput"
            % If seed was not set use its default value
            if isempty(input.inputs.seed)
                input.inputs.seed = 0;
            end
            % Generate a random signal based on the provided properties
            rs = RandStream("mt19937ar", "Seed", input.inputs.seed);
            time = (0:input.inputs.inputChangeInterval:input.stopTime)';
            force = input.inputs.maxMagnitude * rand(rs,size(time));
            inputSignal = timeseries(force,time);
        elseif input.inputs.inputType == "MassSpringDamperExactInput"
            % Simply use the provided signal as is
            inputSignal = timeseries(input.inputs.F.Data,input.inputs.F.Time);
        else
            % Return an error
            res.Status(400).Json(SimulationServer.models.ErrorResponse(error_message="Invalid inputType specified")); 
            return
        end
        
        % Configure the inputs and parameters of the model based on the
        % provided inputs
        simIn = Simulink.SimulationInput('MassSpringDamperModel');
        % Set the force input signal
        simIn = simIn.setExternalInput(inputSignal);
        % Set the parameters
        simIn = simIn.setVariable('m',input.parameters.m,'Workspace','MassSpringDamperModel');
        simIn = simIn.setVariable('k',input.parameters.k,'Workspace','MassSpringDamperModel');
        simIn = simIn.setVariable('b',input.parameters.b,'Workspace','MassSpringDamperModel');
        simIn = simIn.setVariable('x0',input.parameters.x0,'Workspace','MassSpringDamperModel');
        % Set the stop time
        simIn = simIn.setModelParameter("StopTime",string(input.stopTime));
        % Needed for deployment using Simulink Compiler
        simIn = simulink.compiler.configureForDeployment(simIn);
        % Run the actual simulation
        out = sim(simIn);
        
        % Start building the response
        output = SimulationServer.models.MassSpringDamperResponse();
        % Fill-out all the signals based on the outputs from the model
        output.a(1).Time = out.logsout.get("acc").Values.Time;
        output.a(1).Data = out.logsout.get("acc").Values.Data;
        output.v(1).Time = out.logsout.get("vel").Values.Time;
        output.v(1).Data = out.logsout.get("vel").Values.Data;    
        output.x(1).Time = out.logsout.get("pos").Values.Time;
        output.x(1).Data = out.logsout.get("pos").Values.Data;    
        
        % In case a randomly generated input signal was used, also include it
        % in the output
        if input.inputs.inputType == "MassSpringDamperRandomInput"
            output.F(1).Time = inputSignal.Time;
            output.F(1).Data = inputSignal.Data;
        end

        % Write the output to the response
        res.Status(200).Json(output);
        return
    catch ME
        res.Status(500).Json(SimulationServer.models.ErrorResponse(error_message=ME.message));
        return
    end
    
end % simMassSpringDamper method
```

## Server Testing

Now that the handler has been implemented we can test the server using the [testing interface for MATLAB Production Server](https://www.mathworks.com/help/compiler_sdk/mps_dev_test/test-in-process.html).

First we tell the test server where to find the routes configuration and then we start the Production Server Archive Compiler App:

```matlabsession
>> setenv('PRODSERVER_ROUTES_FILE','MyServer/routes.json');
>> productionServerArchiveCompiler
```

In the App add `server.m` as Exported Function and set the Archive Name to `SimulationServer`, the testing server can then be started under `Test Client` and by then clicking `Start`.

And then we can try calling the end-point. For example if you have cURL available, you can run the following from a command prompt:

```console
$ curl --location 'http://localhost:9910/openapi-example/sim/mass-spring-damper' --header 'Content-Type: application/json' --data '{"parameters":{"m":10,"k":100,"b":1,"x0":0},"inputs":{"inputType":"MassSpringDamperRandomInput","maxMagnitude":100,"inputChangeInterval":10,"seed":1},"stopTime":100}'
```

Or you can perform a similar request using tools like Postman or any other RESTful client.

This should return the output signals in the [JSON format as discussed above](#response-body).

### (Bonus) Test using a (partly generated) Python client

```{note}
This section requires NodeJS and Python.
```

As mentioned before, working with OpenAPI does not only allow us to generate parts of the server, it can also be used to generate (parts of) clients.

To get an idea of how this could work, and also to actually test our server even more, in this section we generate and then use a Python client.

To generate a client we can call the OpenAPI Generator CLI from a terminal. In the `Software/MATLAB/examples/server/simulink` directory, run:

```console
$ npx @openapitools/openapi-generator-cli generate -g python -i openapi.yaml -o python
```

This will generate a Python API client inside a directory named `python`. We can then go into that directory and install any Python dependencies which the generated package need:

```console
$ cd python
$ pip install -r requirements.txt matplotlib
```

We can then create a new file `example.py` with the following content which uses the generated OpenAPI client to call the server:

```python
# All these imports refer to code in the package which was generated
from openapi_client.models.mass_spring_damper_parameters import MassSpringDamperParameters
from openapi_client.models.mass_spring_damper_random_input import MassSpringDamperRandomInput
from openapi_client.models.mass_spring_damper_request import MassSpringDamperRequest
from openapi_client import SimulationApi

# Create an instance of the generated SimulationApi class
client = SimulationApi()
# Configure the request body using the generated classes
req = MassSpringDamperRequest(
    parameters=MassSpringDamperParameters(m=10,k=100,b=1),
    inputs=MassSpringDamperRandomInput(
        inputType="MassSpringDamperRandomInput",
        maxMagnitude=100,
        inputChangeInterval=10),
    stopTime=1000
)
# Call the API using the generated method
result = client.sim_mass_spring_damper(req)

# As an example, visualize the result
import matplotlib.pyplot as plt

ax = plt.subplot(4,1,1)
ax.set_title('Input Force')
ax.stairs(result.f.data[:-1],result.f.time)
ax = plt.subplot(4,1,2)
ax.set_title('Acceleration')
ax.plot(result.a.time,result.a.data)
ax = plt.subplot(4,1,3)
ax.set_title('Velocity')
ax.plot(result.v.time,result.v.data)
ax = plt.subplot(4,1,4)
ax.set_title('Position')
ax.plot(result.x.time,result.x.data)

plt.show()
```

If you are familiar with Python, you will notice that in this code we are not explicitly doing anything with JSON nor are we explicitly making any low-level HTTP requests. We have a clean, higher level, class-based interface which we can easily work with. 

Finally we can run the example:

```console
$ python example.py
```

## Package

To package the server into a CTF-archive, we can use the `buildfile.m` which was also generated:

```matlabsession
>> buildtool build
```

If you wish to build a Microservice Docker image (instead of deploying the CTF-archive to MATLAB Production Server), this can then be done using:

```matlabsession
>> buildtool microservice
```

## Deploy

To deploy the package to MATLAB Production Server, copy over the CTF-archive which was produced and update `routes.json` on the server instance. 

Or to run the Microservice image which was created:

```console
$ docker run --rm -p 9910:9910 simulationserver
```