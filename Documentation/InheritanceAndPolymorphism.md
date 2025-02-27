# Inheritance and Polymorphism

OpenAPI supports various forms of inheritance and polymorphism.

For example in the following spec:

```yaml
openapi: "3.0.3"
info:
  title: "Test API"
  version: "1.0.0"
servers:
- url: "http://localhost/test"
paths:
  /operation1:
    post:
      tags:
        - Test
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/WithBaseProperty'
      responses:
        200:
          description: success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/WithBaseProperty'
  /operation2:
    post:
      tags:
        - Test
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/BaseObject'
      responses:
        200:
          description: success
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/BaseObject'
  /operation3:
    post:
      tags:
        - Test
      requestBody:
        content:
          application/json:
            schema:
              oneOf:
              - $ref: '#/components/schemas/FirstDerivedObject'                
              - $ref: '#/components/schemas/SecondDerivedObject'   
      responses:
        200:
          description: success
          content:
            application/json:
              schema:
                oneOf:
                - $ref: '#/components/schemas/FirstDerivedObject'                
                - $ref: '#/components/schemas/SecondDerivedObject'                     
components:
  schemas:
    WithBaseProperty:
      type: object
      properties:
        TheProperty:
          $ref: '#/components/schemas/BaseObject'
    BaseObject:
      type: object
      properties:
        name:
          type: string
        objectType:
          type: string
      discriminator:
        propertyName: objectType
    FirstDerivedObject:
      allOf:
        - $ref: '#/components/schemas/BaseObject'
        - type: object
          properties:
            FirstProperty:
              type: string
    SecondDerivedObject:
      allOf:
        - $ref: '#/components/schemas/BaseObject'
        - type: object
          properties:
            SecondProperty:
              type: string
```

There is an object hierarchy:

```{mermaid}
classDiagram
    class WithBaseProperty{
        BaseObject TheProperty
    }
    class BaseObject {
        string name
        string objectType ~discriminator~
    }
    class FirstDerivedObject {
        string FirstProperty
    }
    class SecondDerivedObject {
        string SecondProperty
    }
    WithBaseProperty --> BaseObject
    BaseObject <|-- FirstDerivedObject
    BaseObject <|-- SecondDerivedObject
```

To summarize:

*   There is a `WithBaseProperty` object where one of its properties `TheProperty` contains a `BaseObject`.

*   There are two classes which derive from `BaseObject`: `FirstDerivedObject` and `SecondDerivedObject`. 

*   `BaseObject` has a discriminator property `objectType` this helps in determining whether a JSON representation is actually trying to represent a `FirstDerivedObject` or a `SecondDerivedObject`. I.e. the JSON representation of a `FirstDerivedObject` would be:
    
    ```json
    {
        "name": "foo",                      // Just an example value
        "objectType": "FirstDerivedObject", // Literally this value to specify the subtype
        "FirstProperty": "Hello"            // Just an example value
    }
    ```

    And for `SecondDerivedObject`:

    ```json
    {
        "name": "bar",                       // Just an example value
        "objectType": "SecondDerivedObject", // Literally this value to specify the subtype
        "SecondProperty": "World"            // Just an example value
    }
    ```

For this example, the generator will also really generate a `myPackage.models.BaseClass` MATLAB class (which derives from `JSONMapper`) and two child classes `myPackage.models.FirstDerivedObject` and `myPackage.models.SecondDerivedObject` which derive from `myPackage.models.BaseClass`.

In `myPackage.models.WithBaseProperty` the `TheProperty` property will be of type `myPackage.models.BaseClass` which means in that in practice it can hold a  `myPackage.models.BaseClass` but also a `myPackage.models.FirstDerivedObject` or `myPackage.models.SecondDerivedObject`.

When working with `/operation1` above, which expects a `WithBaseProperty` as input, ensure the right class is used for `TheProperty` depending on how the method is to be called. If the specific call you are trying to make requires a `FirstDerivedObject`, ensure you also really use that MATLAB type:

```matlab
data = myPackage.models.WithBaseProperty( ...
    TheProperty=myPackage.models.FirstDerivedObject( ...
        objectType="FirstDerivedObject", ...
        FirstProperty="Hello" ...
    ) ...
);
```

Or if the call requires a `SecondDerivedObject`:

```matlab
data = myPackage.models.WithBaseProperty( ...
    TheProperty=myPackage.models.SecondDerivedObject( ...
        objectType="SecondDerivedObject", ...
        SecondProperty="World" ...
    ) ...
);
```

Further, the generated code should also be able to automatically return the correct (most specific) type when a reply is received. For example if `/operation1` returns the following JSON document

```json
{
    "TheProperty": 
    {
        "name": "foo",
        "objectType": "SecondDerivedObject",
        "SecondProperty": "bar"
    }
}
```

The generated MATLAB client should be able to return a `myPackage.models.WithBaseProperty` instance where `TheProperty` contains a `myPackage.models.SecondDerivedObject` object with the `SecondProperty` filled out (and not a `myPackage.models.BaseClass` in which the `SecondProperty` value would have been lost).

Similarly for `/operation2` it is possible to call the generated `operation2Post` method with either a `myPackage.models.FirstDerivedObject` or `myPackage.models.SecondDerivedObject` (or `myPackage.models.BaseClass`) as input, depending on what you are trying to achieve. And the generated method should also be able to really return `myPackage.models.FirstDerivedObject` or `myPackage.models.SecondDerivedObject` specifically (or `myPackage.models.BaseClass` if `objectType` was missing or invalid in the response).

`/operation2` and `/operation3` try to convey the same message in that both operations accept a `FirstDerivedObject` or `SecondDerivedObject` as input and both can return a `FirstDerivedObject` or `SecondDerivedObject` as output. However because the exact definitions differ, one through defining a class hierarchy and one through using `oneOf`, the generated code will also be different for `/operation2` and `/operation3`.

For the `oneOf` approach, a new class is generated which is in fact the *union* of `FirstDerivedObject` *and* `SecondDerivedObject`. So this will be an object with properties `name`, `objectType` *and* `FirstProperty` *and* `SecondProperty`. Then depending on what call you are trying to make when calling `operation3Post` you choose which of these properties to fill-out and which to simply leave unset. Similarly the output will have all four fields as properties but only the relevant ones will be filled-out. Model classes generated for `oneOf` will have an extra method `getSpecificClass` which can be called in a second step to get an instance of the more specific class, discarding the irrelevant fields.
