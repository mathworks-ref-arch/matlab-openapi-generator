classdef DataTypes < GenerateSpec
    properties
        packageName = "DT"
    end

    methods (Test)
        function Int32(testCase)
            testCase.generate('Int32',[ ...
                "type: integer" 
                "format: int32"
            ]);

            % Verify that no model was generated
            testCase.verifyEqual(exist('DT.models.Int32','class'),0);

        end

        function ArrayInt32(testCase)
            testCase.generate('ArrayInt32',[ ...
                "type: array" 
                "items:"
                "  type: integer"
                "  format: int32"
            ])
            % Verify that no model was generated
            testCase.verifyEqual(exist('DT.models.ArrayInt32','class'),0);
        end

        function ArrayArrayInt32(testCase)
            testCase.generate('ArrayArrayInt32',[ ...
                "type: array" 
                "items:"
                "  type: array"
                "  items:"
                "    type: integer"
                "    format: int32"
            ])
            % Verify that no model was generated
            testCase.verifyEqual(exist('DT.models.ArrayArrayInt32','class'),0);            
        end        

        function ObjectInt32(testCase)
            testCase.generate('ObjectInt32',[ ...
                "type: object"
                "properties:"
                "  field:"
                "    type: integer" 
                "    format: int32"
            ]);
            % Verify generated model

            % Model should exist
            testCase.verifyEqual(exist('DT.models.ObjectInt32','class'),8);
            % Type of the property should be int32
            m = ?DT.models.ObjectInt32;
            testCase.verifyEqual(m.PropertyList.Validation.Class,?int32);
            % JSONPropertyInfo must report int32 and NOT array
            pInfo = DT.JSONPropertyInfo.getPropertyInfo(DT.models.ObjectInt32);
            testCase.verifyEqual(pInfo.dataType,?int32)
            testCase.verifyFalse(pInfo.isArray);
        end

        function ObjectArrayInt32(testCase)
            testCase.generate('ObjectArrayInt32', [ ...
                "type: object"
                "properties:"
                "  field:"
                "    type: array"
                "    items:"
                "      type: integer" 
                "      format: int32"
            ])
            % Verify generated model

            % Model should exist
            testCase.verifyEqual(exist('DT.models.ObjectArrayInt32','class'),8);                        
            % Type of the property should be int32
            m = ?DT.models.ObjectArrayInt32;
            testCase.verifyEqual(m.PropertyList.Validation.Class,?int32);
            % JSONPropertyInfo must report int32 and array
            pInfo = DT.JSONPropertyInfo.getPropertyInfo(DT.models.ObjectArrayInt32);
            testCase.verifyEqual(pInfo.dataType,?int32)
            testCase.verifyTrue(pInfo.isArray);
        end

        function ObjectArrayArrayInt32(testCase)
            testCase.generate('ObjectArrayArrayInt32',[ ...
                "type: object"
                "properties:"
                "  field:"
                "    type: array"
                "    items:"
                "      type: array"
                "      items:"
                "        type: integer" 
                "        format: int32"
            ])
            % Verify generated model

            % Model should exist
            testCase.verifyEqual(exist('DT.models.ObjectArrayArrayInt32','class'),8);
            % Type of the property should be unset
            m = ?DT.models.ObjectArrayArrayInt32;
            testCase.verifyEmpty(m.PropertyList.Validation.Class);
            % JSONPropertyInfo must report ?meta.class and array
            pInfo = DT.JSONPropertyInfo.getPropertyInfo(DT.models.ObjectArrayArrayInt32);
            testCase.verifyEqual(pInfo.dataType,?meta.class)
            testCase.verifyTrue(pInfo.isArray);
        end

        function ObjectOneOfInt32Int64(testCase)
            testCase.generate('ObjectOneOfInt32Int64',[ ...
                "type: object"
                "properties:"
                "  field:"
                "    oneOf:"
                "    - type: integer"
                "      format: int32"
                "    - type: integer"
                "      format: int64"
                ])
            % Verify generated model

            % Model should exist
            testCase.verifyEqual(exist('DT.models.ObjectOneOfInt32Int64','class'),8);
            % Type of the property should be unset
            m = ?DT.models.ObjectOneOfInt32Int64;
            testCase.verifyEmpty(m.PropertyList.Validation.Class);
            % JSONPropertyInfo must report ?meta.class and NOT array
            pInfo = DT.JSONPropertyInfo.getPropertyInfo(DT.models.ObjectOneOfInt32Int64);
            testCase.verifyEqual(pInfo.dataType,?meta.class)
            testCase.verifyFalse(pInfo.isArray);
        end

        function ObjectOneOfObjectInt32Int64(testCase)
            testCase.generate('ObjectOneOfObjectInt32Int64', [ ...
                "type: object"
                "properties:"
                "  field:"
                "    oneOf:"
                "    - type: object"
                "      properties:"
                "        fieldA:"
                "         type: integer"
                "         format: int32"
                "    - type: object"
                "      properties:"
                "        fieldB:"
                "          type: integer"
                "          format: int64"
            ])
            % Verify generated model

            % Model should exist
            testCase.verifyEqual(exist('DT.models.ObjectOneOfObjectInt32Int64','class'),8);
            % Type of the property should be set
            m = ?DT.models.ObjectOneOfObjectInt32Int64;
            testCase.verifyEqual(m.PropertyList.Validation.Class,?DT.models.ObjectOneOfObjectInt32Int64_field);
            % JSONPropertyInfo must report same class and NOT array
            pInfo = DT.JSONPropertyInfo.getPropertyInfo(DT.models.ObjectOneOfObjectInt32Int64);
            testCase.verifyEqual(pInfo.dataType,?DT.models.ObjectOneOfObjectInt32Int64_field)
            testCase.verifyFalse(pInfo.isArray);

            % Nested Class must have fieldA int32 and fieldB int64
            m = ?DT.models.ObjectOneOfObjectInt32Int64_field;
            testCase.verifyEqual(m.PropertyList(1).Name,'fieldA');
            testCase.verifyEqual(m.PropertyList(1).Validation.Class,?int32);
            testCase.verifyEqual(m.PropertyList(2).Name,'fieldB');            
            testCase.verifyEqual(m.PropertyList(2).Validation.Class,?int64);
        end        

        function ObjectArrayOneOfObjectInt32Int64(testCase)
            testCase.generate('ObjectArrayOneOfObjectInt32Int64',[ ...
                "type: object"
                "properties:"
                "  field:"
                "    type: array"
                "    items:"
                "      oneOf:"
                "      - type: object"
                "        properties:"
                "          fieldA:"
                "           type: integer"
                "           format: int32"
                "      - type: object"
                "        properties:"
                "          fieldB:"
                "            type: integer"
                "            format: int64"
            ])
            % Verify generated model

            % Model should exist
            testCase.verifyEqual(exist('DT.models.ObjectArrayOneOfObjectInt32Int64','class'),8);
            % Type of the property should be set
            m = ?DT.models.ObjectArrayOneOfObjectInt32Int64;
            testCase.verifyEqual(m.PropertyList.Validation.Class,?DT.models.ObjectArrayOneOfObjectInt32Int64_field_inner);
            % JSONPropertyInfo must report same class and array
            pInfo = DT.JSONPropertyInfo.getPropertyInfo(DT.models.ObjectArrayOneOfObjectInt32Int64);
            testCase.verifyEqual(pInfo.dataType,?DT.models.ObjectArrayOneOfObjectInt32Int64_field_inner)
            testCase.verifyTrue(pInfo.isArray);

            % Nested Class must have fieldA int32 and fieldB int64
            m = ?DT.models.ObjectArrayOneOfObjectInt32Int64_field_inner;
            testCase.verifyEqual(m.PropertyList(1).Name,'fieldA');
            testCase.verifyEqual(m.PropertyList(1).Validation.Class,?int32);
            testCase.verifyEqual(m.PropertyList(2).Name,'fieldB');            
            testCase.verifyEqual(m.PropertyList(2).Validation.Class,?int64);
        end 

        function StringEnum(testCase)
            testCase.generate('MyEnum',[ ...
                "type: string" 
                "enum:"
                "- foo"
                "- 123"
            ]);

            % Verify model was generated
            testCase.verifyEqual(exist('DT.models.MyEnum','class'),8);
            % Verify that it is an enum
            m = ?DT.models.MyEnum;
            testCase.verifyTrue(m.Enumeration)
            % Verify it has two values
            ev = m.EnumerationMemberList;
            testCase.verifyEqual(length(ev),2)
            % Verify the names are correct
            testCase.verifyEqual(ev(1).Name,'foo')
            testCase.verifyEqual(ev(2).Name,'x123')
            % Verify their underlying values
            testCase.verifyEqual(DT.models.MyEnum.foo.JSONValue,"foo")
            testCase.verifyEqual(DT.models.MyEnum.x123.JSONValue,"123")
        end

        function EnumAsField(testCase)
            testCase.generate('MyModel',[ ...
                "type: object" 
                "properties:"
                "  my_enum:"
                "    type: string"
                "    enum:"
                "    - foo"
                "    - 123"
            ]);


            % Verify MyModel model was generated
            testCase.verifyEqual(exist('DT.models.MyModel','class'),8);
            % Verify that MyModel has an my_enum field and it is of the
            % DT.models.MyModelMy_enumEnum type
            m = ?DT.models.MyModel;
            p = m.PropertyList;
            testCase.verifyEqual(p.Name,'my_enum');
            testCase.verifyEqual(p.Validation.Class,?DT.models.MyModelMy_enumEnum)

            % Verify enum model was generated
            testCase.verifyEqual(exist('DT.models.MyModelMy_enumEnum','class'),8);

            % Verify that it is an enum
            m = ?DT.models.MyModelMy_enumEnum;
            testCase.verifyTrue(m.Enumeration)
            % Verify it has two values
            ev = m.EnumerationMemberList;
            testCase.verifyEqual(length(ev),2)
            % Verify the names are correct
            testCase.verifyEqual(ev(1).Name,'foo')
            testCase.verifyEqual(ev(2).Name,'x123')
            % Verify their underlying values
            testCase.verifyEqual(DT.models.MyModelMy_enumEnum.foo.JSONValue,"foo")
            testCase.verifyEqual(DT.models.MyModelMy_enumEnum.x123.JSONValue,"123")

        end        

        function IntEnum(testCase)
            testCase.generate('MyEnum',[ ...
                "type: integer" 
                "enum:"
                "- 1"
                "- 2"
            ]);

            % Verify model was generated
            testCase.verifyEqual(exist('DT.models.MyEnum','class'),8);
            % Verify that it is an enum
            m = ?DT.models.MyEnum;
            testCase.verifyTrue(m.Enumeration)
            % Verify it has two values
            ev = m.EnumerationMemberList;
            testCase.verifyEqual(length(ev),2)
            % Verify the names are correct
            testCase.verifyEqual(ev(1).Name,'x1')
            testCase.verifyEqual(ev(2).Name,'x2')
            % Verify their underlying values
            testCase.verifyEqual(DT.models.MyEnum.x1.JSONValue,int32(1))
            testCase.verifyEqual(DT.models.MyEnum.x2.JSONValue,int32(2))
        end

        function IntEnumWithNames(testCase)
            testCase.generate('MyEnum',[ ...
                "type: integer" 
                "enum:"
                "- 1"
                "- 2"
                "x-enumNames:"
                "- foo"
                "- bar "
            ]);

            % Verify model was generated
            testCase.verifyEqual(exist('DT.models.MyEnum','class'),8);
            % Verify that it is an enum
            m = ?DT.models.MyEnum;
            testCase.verifyTrue(m.Enumeration)
            % Verify it has two values
            ev = m.EnumerationMemberList;
            testCase.verifyEqual(length(ev),2)
            % Verify the names are correct
            testCase.verifyEqual(ev(1).Name,'foo')
            testCase.verifyEqual(ev(2).Name,'bar')
            % Verify their underlying values
            testCase.verifyEqual(DT.models.MyEnum.foo.JSONValue,int32(1))
            testCase.verifyEqual(DT.models.MyEnum.bar.JSONValue,int32(2))
        end



        function AllOfOneOffDiscriminator(testCase)
            testCase.generate('MyResponse',[ ...
                "type: array" 
                "items:"
                "  oneOf:"
                "  - $ref: '#/components/schemas/ObjectA'"
                "  - $ref: '#/components/schemas/ObjectB'"
            ],'BaseObject',[...
                "type: object"
                "properties:"
                "  objectType:"
                "    type: string"
                "discriminator:"
                "  propertyName: objectType"
                "  mapping:"
                "    A: '#/components/schemas/ObjectA'"
                "    B: '#/components/schemas/ObjectB'"
            ],'ObjectA',[...
                "type: object"
                "allOf:"
                "- $ref: '#/components/schemas/BaseObject'"
                "- type: object"
                "  properties:"
                "    fieldA:"
                "      type: string"
            ],'ObjectB',[...
                "type: object"
                "allOf:"
                "- $ref: '#/components/schemas/BaseObject'"
                "- type: object"
                "  properties:"
                "    fieldB:"
                "      type: string"
            ]);

            % Verify model was generated
            testCase.verifyEqual(exist('DT.models.MyResponse_inner','class'),8);
            % Verify that DT.models.MyResponse_inner has all the expected
            % properties
            m = ?DT.models.MyResponse_inner;
            testCase.verifyEqual(m.PropertyList(1).Name,'objectType');
            testCase.verifyEqual(m.PropertyList(1).Validation.Class,?string);           
            testCase.verifyEqual(m.PropertyList(2).Name,'fieldA');
            testCase.verifyEqual(m.PropertyList(2).Validation.Class,?string);
            testCase.verifyEqual(m.PropertyList(3).Name,'fieldB');            
            testCase.verifyEqual(m.PropertyList(3).Validation.Class,?string);            
            % And has getSpecificClass method
            me = m.MethodList(strcmp('getSpecificClass',{m.MethodList.Name}));
            testCase.verifyNotEmpty(me);
            % Verify getSpecificClass works as expected
            o = DT.models.MyResponse_inner('[{"objectType":"A","fieldA":"foo"},{"objectType":"B","fieldB":"bar"}]');
            oA = o(1).getSpecificClass();
            testCase.verifyClass(oA,?DT.models.ObjectA)
            oB = o(2).getSpecificClass();
            testCase.verifyClass(oB,?DT.models.ObjectB)
            
        end

        function ReturnBaseClass(testCase)
            testCase.generate('MyResponse',[ ...
                "ref: #/components/schemas/BaseObject" 
            ],'BaseObject',[...
                "type: object"
                "properties:"
                "  objectType:"
                "    type: string"
                "discriminator:"
                "  propertyName: objectType"
            ],'ObjectA',[...
                "type: object"
                "allOf:"
                "- $ref: '#/components/schemas/BaseObject'"
                "- type: object"
                "  properties:"
                "    fieldA:"
                "      type: string"
            ],'ObjectB',[...
                "type: object"
                "allOf:"
                "- $ref: '#/components/schemas/BaseObject'"
                "- type: object"
                "  properties:"
                "    fieldB:"
                "      type: string"
            ]);

           % Verify that both ObjectA and ObjectB actually derive from
           % BaseObject
           mA = ?DT.models.ObjectA;
           testCase.verifyEqual(mA.SuperclassList,?DT.models.BaseObject)
           mB = ?DT.models.ObjectB;
           testCase.verifyEqual(mB.SuperclassList,?DT.models.BaseObject)

           % Verify that BaseClass correctly deserializes to ObjectA and
           % ObjectB respectively
           A = DT.models.BaseObject().fromJSON('{"fieldA": "foo","objectType":"ObjectA"}');
           testCase.verifyClass(A,?DT.models.ObjectA);
           B = DT.models.BaseObject().fromJSON('{"fieldB": "bar","objectType":"ObjectB"}');
           testCase.verifyClass(B,?DT.models.ObjectB);
        end
        
    end



end