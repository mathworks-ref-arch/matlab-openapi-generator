# JSONMapper

## JSONMapper Base Class

JSONMapper base class - adds JSON serialization and deserialization.
Derive MATLAB classes from this class to allow them to be
deserialized from JSON mapping the JSON fields to the class
properties. To allow proper nesting of objects, derived objects must
call the JSONMapper constructor from their constructor:

```matlab
function obj = myClass(s,inputs)
    arguments
        s {JSONMapper.ConstructorArgument} = []
        inputs.?myClass
    end
    obj@JSONMapper(s,inputs);
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

JSONMapper *methods* usable as *annotation*:

```{eval-rst}
:fieldName:         allows property to be mapped to a JSON field with different name
:JSONArray:         specifies field is a JSON array 
:epochDatetime:     for datetime properties specifies in JSON the date time is 
                    encoded as epoch. Must be the first attribute if used
:stringDatetime:    for datetime properties specifies in JSON the date time is
                    encoded as string with a particular format. Must be the 
                    first attribute if used.
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
    start_date {JSONMapper.epochDatetime}
    % end_date is UNIX timestamp in milliseconds
    end_date {JSONMapper.epochDatetime(end_date,'TicksPerSecond',1000)}
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
    start_date {JSONMapper.stringDatetime(start_date,'yyyy-MM-dd''T''HH:mm:ss')}
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

[//]: #  (Copyright 2022-2023 The MathWorks, Inc.)
