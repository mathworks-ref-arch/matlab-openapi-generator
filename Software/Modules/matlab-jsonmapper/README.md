# JSONMapper

Provides JSON serialization and deserialization of MATLAB class object hierarchies.

## Requirements

### MathWorks Products (http://www.mathworks.com)

* MATLAB R2020a or newer

## Introduction

The package provides a `JSONMapper` base class which adds JSON serialization and deserialization to objects. Derive MATLAB classes from this class to allow them to be deserialized from JSON mapping the JSON fields to the class properties.

During serialization or deserialization the MATLAB object definition
is leading. JSON data is converted to MATLAB data types based on the
type declaration in MATLAB.

Supported property datatypes: double, float, uint8, int8, uint16,
int16, uint32, int32, uint64, int64, logical, enum, string, char,
datetime, containers.Map, classes derived from JSONMapper.

Full precision of all types are preserved. datetimes can be automatically parsed from integer epoch timestamps or strings and upon serialization also converted back again. Properties can also be marked as array to ensure upon serializing a MATLAB scalar it is in fact serialized as array.

## Installation

Run `Software/MATLAB/startup.m`.

## Usage

Derive MATLAB classes from the `JSONMapper` class to allow them to be
deserialized from JSON mapping the JSON fields to the class
properties. To allow proper nesting of object, derived objects must
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

Make sure to update the class name (`myClass` in the example above) in both the function name *as well as in the arguments block*.

During serialization or deserialization the MATLAB object definition
is definitive. JSON data is converted to MATLAB data types based on the
type declaration in MATLAB. Therefore all properties of the MATLAB
class *must* have a type declaration. Also, fields are only
deserialized if they actually exist on the MATLAB class, any
additional fields in the JSON input are ignored.

Supported property datatypes: double, float, uint8, int8, uint16,
int16, uint32, int32, uint64, int64, logical, enum, string, char,
datetime (must be annotated), containers.Map, classes derived from
JSONMapper.

Annotations can be added to properties as "validation functions".

| Annotation     | Description |
|----------------|------------------------------------------------------------------|
| fieldName      | allows property to be mapped to a JSON field with different name |
| JSONArray      | specifies field is a JSON array |
| epochDatetime  | for datetime properties specifies in JSON the date time is encoded as epoch. Must be the first attribute if used |
| stringDatetime | for datetime properties specifies in JSON the date time is encoded as string with a particular format. Must be the first attribute if used. |

Please see the [documentation](Documentation/README.md) for more information.

## License

The license is available in the [LICENSE.MD](LICENSE.MD) file in this repository.

## Enhancement Requests

Provide suggestions for additional features or capabilities using the following link:
https://www.mathworks.com/products/reference-architectures/request-new-reference-architectures.html

## Support

Email: mwlab@mathworks.com

[//]: #  (Copyright 2022-2023 The MathWorks, Inc.)
