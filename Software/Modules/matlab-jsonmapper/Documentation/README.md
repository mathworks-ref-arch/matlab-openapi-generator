# JSONMapper

## JSONMapper Base Class

JSONMapper base class - adds JSON serialization and deserialization.
Derive MATLAB classes from this class to allow them to be
deserialized from JSON mapping the JSON fields to the class
properties. To allow proper nesting of objects, derived objects must
call the `initialize` method from their constructor

```{note}
In the past it was recommended to call the JSONMapper constructor from derived classes.
While this can indeed also still be used as an alternative to calling `initialize`, this
is no longer recommended as it does not allow building deeper class hierarchies, 
also see [Building class hierarchies](#building-class-hierarchies).
```

```matlab
function obj = myClass(s,inputs)
    arguments
        s {JSONMapper.ConstructorArgument} = []
        inputs.?myClass
    end
    obj = obj.initialize(s,inputs);
end
```

```{note}
Make sure to update the class name (`myClass` in the example above) in both the function name *as well as in the arguments block*.
```

During serialization or deserialization the MATLAB object definition
is leading. JSON data is converted to MATLAB data types based on the
type declaration in MATLAB. Therefore all properties of the MATLAB
class *must* have a type declaration. Also, fields are only
deserialized if they actually exist on the MATLAB class, any
additional fields in the JSON input are ignored.

Supported property data types: double, float, uint8, int8, uint16,
int16, uint32, int32, uint64, int64, logical, string, char,
datetime (must be annotated), JSONMapperMap, classes derived from
[JSONMapper](#jsonmappermap) and [JSONEnum](#jsonenum).

Annotations can be added to properties as "validation functions".

JSONMapper *methods* usable as *annotations*:

| Annotation | Description |
| ---------- | ----------- |
| fieldName | Allows property to be mapped to a JSON field with different name. |
| JSONArray | Specifies field is a JSON array. |
| epochDatetime | For datetime properties specifies in JSON the date time is encoded as epoch. Must be the first attribute if used. |
| stringDatetime | For datetime properties specifies in JSON the date time encoded as string with a particular format. Must be the first attribute if used. |
| discriminator | Indicates that the property acts as a discriminator based upon which the JSON document can be deserialized to a more specific derived class. Also see [Building class hierarchies](#building-class-hierarchies). |
| doNotDecode | Indicates that the property will not be decoded using MATLAB's jsondecode or otherwise when mapping to an object. |

### Building class hierarchies

It is possible to build entire object hierarchies on top of `JSONMapper`. It is for example possible to define
a `Pet` class and two classes `Cat` and `Dog` which derive from it. It is also possible to define a
[discriminator property](#jsonmapperdiscriminator) then; this is a property whose value specifies the exact subclass of an instance.

This all ties in with [composition, inheritance and polymorphism in OpenAPI compatible services](https://spec.openapis.org/oas/v3.0.3#composition-and-inheritance-polymorphism).

So, it is for example possible to implement the following MATLAB classes:

```matlab
classdef Pet < JSONMapper
    properties
        name string
        petType string {JSONMapper.discriminator(petType, "Cat","Cat","Dog","Dog")}
    end
    methods
        function obj = Pet(s,inputs)
            arguments
                s {JSONMapper.ConstructorArgument} = []
                inputs.?Pet
            end
            obj = obj.initialize(s,inputs);
        end
    end
end

classdef Cat < Pet
    properties
        huntingSkill string
    end
    methods
        function obj = Cat(s,inputs)
            arguments
                s {JSONMapper.ConstructorArgument} = []
                inputs.?Cat
            end
            obj = obj.initialize(s,inputs);
        end
    end    
end

classdef Dog < Pet
    properties
        packSize int32
    end
    methods
        function obj = Dog(s,inputs)
            arguments
                s {JSONMapper.ConstructorArgument} = []
                inputs.?Dog
            end
            obj = obj.initialize(s,inputs);
        end
    end    
end
```

Where if `Pet().fromJSON` is called with a JSON document with the `petType` set, it can actually return a `Cat` or `Dog` specifically rather than a more generic `Pet`, for example:

```matlabsession
>> p = Pet().fromJSON('{"name":"Garfield","petType": "Cat","huntingSkill":"lazy"}')

p = 

  Cat with properties:

    huntingSkill: "lazy"
            name: "Garfield"
         petType: "Cat"
```

```{note}
This is only possible when working with `fromJSON`, this will *not* work if calling the *constructor* with a JSON document as input. (A constructor cannot return object of other classes, regardless of whether those classes are children of the class in question or not).
```

### Annotations

#### JSONMapper.fieldName

fieldName JSONMapper Annotation
This can be added to properties if the MATLAB property name
and JSON field name differ. For example, when the JSON field
name is not a valid MATLAB identifier.

Example:

```matlab
properties
    some_field {JSONMapper.fieldName(some_field,"some.field")}
end
```

#### JSONMapper.JSONArray

JSONArray JSONMapper Annotation
Specified that the JSON field is an array.

Ensures that when serializing a MATLAB scalar it is in fact
encoded as a JSON array rather than a scalar if the property
has been annotated with this option.

#### JSONMapper.epochDatetime

epochDatetime JSONMapper Annotation
When working with datetime fields either epochDatetime or
stringDatetime annotation is required to specify how the
datetime is encoded in JSON. This must be the first
annotation.

When called without inputs POSIX time/UNIX timestamp is
assumed.

Optional Name-Value pairs TimeZone, Epoch and TicksPerSecond
can be provided, their meaning is the same as when working
with `datetime(d,'ConvertFrom','epochtime', OPTIONS)`.

Example:

```matlab
properties
    % start_date is a UNIX timestamp
    start_date datetime {JSONMapper.epochDatetime}
    % end_date is UNIX timestamp in milliseconds
    end_date datetime {JSONMapper.epochDatetime(end_date,'TicksPerSecond',1000)}
end
```

#### JSONMapper.stringDatetime

stringDatetime JSONMapper Annotation
When working with datetime fields either epochDatetime or
stringDatetime annotation is required to specify how the
datetime is encoded in JSON. This must be the first
annotation.

stringDatetime requires the string format as input.

Optional Name-Value pair TimeZone can be provided.

Example:

```matlab
properties
    start_date datetime {JSONMapper.stringDatetime(start_date,'yyyy-MM-dd''T''HH:mm:ss')}
end
```

#### JSONMapper.discriminator

Indicates that the property acts as a discriminator based upon which the JSON document can be deserialized to a more specific derived class. Also see [Building class hierarchies](#building-class-hierarchies).

discriminator requires pairs of values and classes as input. Where the pair indicates that if the property has a particular value then this maps to a particular class.

For example:

```matlab
properties
    petType string {JSONMapper.discriminator(petType,"cat","Cat","dog","Dog")}
end
```

Specifies that if:

* `petType=="cat"` then the object should be deserialized as `Cat` class
* `petType=="dog"` then the object should be deserialized as `Dog` class

#### JSONMapper.doNotDecode

Indicates that the text property should not be decoded using a JSON parser.
However it may be parsed and thus should be valid JSON.
A scenario where this can be useful is if receiving JSON which can only be
decoded correctly using a bespoke schema at a higher level.

Such a property should be a scalar string.
It should not be used in combination with other annotations.

For example:

```matlab
properties
    myJSONValue string {JSONMapper.doNotDecode}
end
```

### Methods

#### fromJSON

fromJSON deserializes the object from JSON format

Example:

```matlab
obj = myClass;
obj.fromJSON('{"answer": 42}')
```

#### jsonencode

jsonencode serializes the object as JSON

The function should only ever be called with one input: the
object to be serialized. The second input is only meant to be
used internally when jsonencode is called recursively.

Example:

```matlab
json = jsonencode(obj);
```

#### getPayload

getPayload JSON encodes the object taking into account
required and optional properties.

Verifies that required properties have indeed been set.
Includes optional properties in the output. All other
properties are not included in the output.

Example:

```matlab
obj = myClass();
obj.required1 = "foo"
obj.required2 = "bar"
obj.optional1 = 42;
json = obj.getPayload(["required1","required2"],["optional1","optional2"]);
```

If both inputs (required- as well as optional-parameter arrays) are set to empty
`[]`, no validation takes place and all properties which are non-empty are
included in the encoded JSON.

## JSONEnum

JSONEnum Base class for enumerations when working with JSONMapper
When adding enumeration properties to JSONMapper objects, the custom
enumeration classes must inherit from this JSONEnum base class. And
the custom enumeration class must declare string values for each enum
element, these represent the JSON representation of the enumeration
values; this is required since not all JSON values are guaranteed to
be valid MATLAB variable names whereas the actual MATLAB enumeration
values must be.

Example:

```matlab
classdef myEnum < JSONEnum
    enumeration
        VAL1 ("VAL.1")
        VAL2 ("VAL.2")
    end
end
```

Even if JSON values are valid MATLAB variables, the string value must
be provided, e.g.:

```matlab
classdef myEnum < JSONEnum
    enumeration
        VAL1 ("VAL1")
        VAL2 ("VAL2")
    end
end
```

## JSONMapperMap

JSONMapperMap is a wrapper around `containers.Map` which:

1.  Allows properties with free-form (string) key (string) value pairs. A typical
    use-case is in REST APIs where objects can have some user defined tags:

    ```json
    {
        // Standard fixed properties for this object
        "name": "foo",    
        "version": 1.2, 
        // Free-form map with user defined keys and values
        // (can also be empty if user does not want to set them)
        "tags": { 
            "someKey": "someValue",
            "someOtherKey": "anotherValue",
        }
    }
    ```

    A `JSONMapper` derived MATLAB class for this could look like the following:

    ```{code-block} matlab
    ---
    emphasize-lines: 5
    ---
    classdef myClass < JSONMapper
        properties
            name string
            version double
            tags JSONMapperMap
        end
        methods
            function obj = myClass(varargin)
                obj@JSONMapper(varargin{:});
            end   
        end
    end
    ```

2.  Avoids shared instances. *If* `tags` in the MATLAB snippet above would have
    been declared as `containers.Map` then all instances of `myClass` would have
    shared one single `containers.Map` instance. I.e., in the following, even
    though we assign a `someKey` to obj**1**.tags, obj**2**.tags changed as well:

    ```{code-block} matlabsession
    ---
    emphasize-lines: 9,19,29,39
    ---
    >> obj1 = myClass

    obj1 = 

    myClass with properties:

        name: [0×0 string]
        version: []
        tags: [0×1 containers.Map]

    >> obj2 = myClass

    obj2 = 

    myClass with properties:

        name: [0×0 string]
        version: []
        tags: [0×1 containers.Map]

    >> obj1.tags('someKey') = 'someValue'

    obj1 = 

    myClass with properties:

        name: [0×0 string]
        version: []
        tags: [1×1 containers.Map]

    >> obj2

    obj2 = 

    myClass with properties:

        name: [0×0 string]
        version: []
        tags: [1×1 containers.Map]
    ```

    `JSONMapperMap` avoids this, with `JSONMapperMap`:

    ```{code-block} matlabsession
    ---
    emphasize-lines: 9,19,29,39
    ---
    >> obj1 = myClass

    obj1 = 

    myClass with properties:

        name: [0×0 string]
        version: []
        tags: [0×0 JSONMapperMap]

    >> obj2 = myClass

    obj2 = 

    myClass with properties:

        name: [0×0 string]
        version: []
        tags: [0×0 JSONMapperMap]

    >> obj1.tags('someKey') = 'someValue'

    obj1 = 

    myClass with properties:

        name: [0×0 string]
        version: []
        tags: [1×1 JSONMapperMap]

    >> obj2

    obj2 = 

    myClass with properties:

        name: [0×0 string]
        version: []
        tags: [0×0 JSONMapperMap]
    ```

[//]: #  (Copyright 2022-2024 The MathWorks, Inc.)
