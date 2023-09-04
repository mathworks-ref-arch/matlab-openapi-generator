classdef (Abstract) JSONMapper < handle
    % JSONMapper base class - adds JSON serialization and deserialization.
    % Derive MATLAB classes from this class to allow them to be
    % deserialized from JSON mapping the JSON fields to the class
    % properties. To allow proper nesting of object, derived objects must
    % call the JSONMapper constructor from their constructor:
    % 
    % function obj = myClass(s,inputs)
    %     arguments
    %         s {JSONMapper.ConstructorArgument} = []
    %         inputs.?myClass
    %     end
    %     obj@JSONMapper(s,inputs);
    % end
    %
    % Make sure to update the class name (myClass in the example) in both
    % the function name as well as in the arguments block.
    %
    % During serialization or deserialization the MATLAB object definition
    % is leading. JSON data is converted to MATLAB data types based on the
    % type declaration in MATLAB. Therefore all properties of the MATLAB
    % class *must* have a type declaration. Also, fields are only
    % deserialized if they actually exist on the MATLAB class, any
    % additional fields in the JSON input are ignored.
    % 
    % Supported property datatypes: double, float, uint8, int8, uint16,
    % int16, uint32, int32, uint64, int64, logical, enum, string, char,
    % datetime (must be annotated), containers.Map, classes derived from
    % JSONMapper.
    %
    % Annotations can be added to properties as "validation functions".
    %
    % JSONMapper Methods:
    %
    %   fieldName      - allows property to be mapped to a JSON field with 
    %                    different name
    %   JSONArray      - specifies field is a JSON array
    %   epochDatetime  - for datetime properties specifies in JSON the date
    %                    time is encoded as epoch. Must be the first
    %                    attribute if used
    %   stringDatetime - for datetime properties specifies in JSON the date
    %                    time is encoded as string with a particular format.
    %                    Must be the first attribute if used.
    
    % Copyright 2022-2023 The MathWorks, Inc.

    properties (Access=private)
        MATLABProperties JSONPropertyInfo
    end
    
    properties (Constant, Access=private)
        MATLABGSON = com.google.gson.GsonBuilder().serializeSpecialFloatingPointValues().create();
    end
    
    methods (Static)
        function fn = fieldName(~,fn)
            % FIELDNAME JSONMapper Annotation
            % This can be added to properties if the MATLAB property name
            % and JSON field name differ. For example, when the JSON field
            % name is not a valid MATLAB identifier.
            %
            % Example:
            %
            %   properties
            %       some_field {JSONMapper.fieldName(some_field,"some.field")}
            %   end
            %
        end


        function JSONArray(~)
            % JSONARRAY JSONMapper Annotation
            % Specified that the JSON field is an array.
            %
            % Ensures that when serializing a MATLAB scalar it is in fact
            % encoded as a JSON array rather than a scalar if the property
            % has been annotated with this option.
        end


        function out = epochDatetime(in,options)
            % EPOCHDATETIME JSONMapper Annotation
            % When working with datetime fields either epochDatetime or
            % stringDatetime annotation is required to specify how the
            % datetime is encoded in JSON. This must be the first
            % annotation.
            %
            % When called without inputs POSIX time/UNIX timestamp is
            % assumed.
            % 
            % Optional Name-Value pairs TimeZone, Epoch and TicksPerSecond
            % can be provided (their meaning is the same as when working
            % with datetime(d,'ConvertFrom','epochtime', OPTIONS).
            %
            % Example:
            %
            %   properties
            %       % start_date is a UNIX timestamp
            %       start_date {JSONMapper.epochDatetime}
            %       % end_date is UNIX timestamp in milliseconds
            %       end_date {JSONMapper.epochDatetime(end_date,'TicksPerSecond',1000)}
            %   end
            arguments
                in
                options.TimeZone = '' 
                options.Epoch = '1970-01-01'
                options.TicksPerSecond = 1;
            end

            if isa(in,'java.lang.String')
                in = string(in);
            end
            
            % Depending on the input type we are either converting from
            % JSON to datetime or the other way around

            if isstring(in) % From JSON to datetime
                % Value will have been passed as a string such that it can
                % be parsed to int64 without loss of precision. Perform
                % this conversion
                in = sscanf(in,'%ld');
                % Convert to MATLAB datetime
                
                % propertyClassCoercionException will mask the error in
                % datetime conversion if this is called as part of fromJSON
                % deserialization of an object hierarchy. Therefore
                % explicitly FPRINTF to stderr any errors here
                try
                    out = datetime(in,'ConvertFrom','epochtime',...
                        'TimeZone',options.TimeZone,...
                        'Epoch',options.Epoch,'TicksPerSecond',options.TicksPerSecond);
                catch ME
                    fprintf(2,'Error in JSONMapper: %s\n\n',ME.message);
                end                    
            elseif isdatetime(in) % From datetime to (JSON) int64
                in.TimeZone = options.TimeZone;
                out = convertTo(in,'epochTime', ...
                    'Epoch',options.Epoch,'TicksPerSecond',options.TicksPerSecond);
            end
        end


        function out = stringDatetime(in,format,options)
            % STRINGDATETIME JSONMapper Annotation
            % When working with datetime fields either epochDatetime or
            % stringDatetime annotation is required to specify how the
            % datetime is encoded in JSON. This must be the first
            % annotation.
            %
            % stringDatetime requires the string format as input.
            % 
            % Optional Name-Value pair TimeZone can be provided.
            %
            % Example:
            %
            %   properties
            %       start_date {JSONMapper.stringDatetime(start_date,'yyyy-MM-dd''T''HH:mm:ss')}
            %   end
            arguments
                in
                format string
                options.TimeZone = ''
            end
            if isa(in,'java.lang.String')
                in = string(in);
            end

            % Depending on the input type we are either converting from
            % JSON to datetime or the other way around

            if isstring(in) || ischar(in) % From JSON to datetime
                % propertyClassCoercionException will mask the error in
                % datetime conversion if this is called as part of fromJSON
                % deserialization of an object hierarchy. Therefore
                % explicitly FPRINTF to stderr any errors here.

                % Try to parse twice, once with fractional seconds, once
                % without
                try
                    out = datetime(in,'InputFormat', format,'TimeZone',options.TimeZone);
                catch 
                    try
                        out = datetime(in,'InputFormat', strrep(format,'.SSS',''),'TimeZone',options.TimeZone);
                    catch ME
                        fprintf(2,'Error in JSONMapper: %s\n\n',ME.message);
                    end
                end
            elseif isdatetime(in) % From datetime to (JSON) string
                in.Format = format;
                in.TimeZone = options.TimeZone;
                out = string(in);
            end
        end


        function ConstructorArgument(arg)
            % CONSTRUCTORARGUMENT to be used in derived constructors to
            % allow string or char arrays as input and allows the
            % constructor to be used when working with nested JSONMapper
            % derived classes.
            tf = isempty(arg) || isa(arg,'com.google.gson.JsonElement') || isstring(arg) || ischar(arg);
            if (~tf)
                error('JSONMapper:InvalidInput',[...
                    'Input must be either a string or char array which is ' ...
                    'a valid JSON string, or the Name part of a Name-Value ' ...
                    'pair where Name must then be the name of one of the ' ...
                    'class properties.']);
            end
        end
    end
    
    methods
        function obj = JSONMapper(s,inputs)
            % JSONMapper Constructor. Call this from
            % derived classes constructors:
            %
            % function obj = myClass(s,inputs)
            %     arguments
            %         s {JSONMapper.ConstructorArgument} = []
            %         inputs.?myClass
            %     end
            %     obj@JSONMapper(s,inputs);
            % end
            %
            % Make sure to update the class name (myClass in the example) 
            % in both the function name as well as in the arguments block.
            
            % Ensure that MATLABProperties is initialized
            obj.MATLABProperties = JSONPropertyInfo.getPropertyInfo(obj);
            
            % For backwards compatibility with derived classes with the old
            % constructor do check nargin, for derived classes with the new
            % constructor this should not be necessary
            if nargin > 0
                % If there is an input
                if ~isempty(s)
                    % And it is a JsonElement, string or char
                    if (isa(s,'com.google.gson.JsonElement') || isstring(s) || ischar(s))
                        % Use the helper method to copy values from this
                        % JsonElement to properties of the object
                        obj = obj.fromJSON(s);
                    else
                        error('JSONMapper:InvalidInput','%s constructor was called with an invalid input.',class(obj));
                    end
                end
            end
            
            % fromInputs behavior
            if nargin > 1
                for p = string(fieldnames(inputs))'
                    obj.(p) = inputs.(p);
                end
            end
        end


        function obj = fromJSON(obj,json)
            try
                % FROMJSON deserializes object from JSON format. 
                % Can deserialize whole hierarchies of objects if all classes
                % in the hierarchy derive from JSONMapper.
                %
                % Example:
                %   obj = myClass;
                %   obj.fromJSON('{"answer": 42}')
                
                % If input is char/string, parse it as json, when working with
                % nested objects, this can also be a com.google.gson.JsonObject
                % or JsonArray.
    
                % If data came in as binary raw bytes, do try to interpret as
                % UTF-8 string
                if isinteger(json)
                    json = native2unicode(json,"UTF-8");
                end
    
                if isstring(json) || ischar(json)
                    json = com.google.gson.JsonParser().parse(json);
                end
                
                % Ensure input is always an array
                if (~json.isJsonArray())
                    j = com.google.gson.JsonArray();
                    j.add(json);
                    json = j;
                end
                
                % For all elements in the JSON array
                N = json.size();

                % For an empty array
                if N == 0
                    obj = obj.empty;
                end

                for arrayIndex=1:N
    
                    % Get the current JSON element from the array
                    curElement = json.get(arrayIndex-1);
    
                    % For each property in the MATLAB class
                    for currProp = obj(1).MATLABProperties
                        
                        % Check whether property is also present in JSON and
                        % not explicitly null
                        if curElement.has(currProp.jName) && ~curElement.get(currProp.jName).isJsonNull
                            % If the property is present in JSON, get this
                            % JSONObject
                            curVal = curElement.get(currProp.jName);
                            % Now, how to convert this to a MATLAB type is
                            % governed by the data type specified on the MATLAB
                            % end. This is especially important for (u)int64
                            % such that we can avoid loss of precision as well
                            % as datetime such that we can correctly convert
                            % it.
                            switch currProp.dataType
                                case {?datetime}
                                    val = arrayfun(currProp.dtConversionFunction,getScalarOrArray(curVal,'string'));
                                    obj(arrayIndex).(currProp.mName) = val;
                                case {?single,?double}
                                    obj(arrayIndex).(currProp.mName) = getScalarOrArray(curVal,'double');
                                case {?int8,?uint8,?int16,?uint16,?int32,?uint32}
                                    obj(arrayIndex).(currProp.mName) = getScalarOrArray(curVal,'long');
                                case {?string,?char}
                                    obj(arrayIndex).(currProp.mName) = getScalarOrArray(curVal,'string');
                                case {?int64}
                                    obj(arrayIndex).(currProp.mName) = arrayfun(@(x)sscanf(char(x),'%ld'), getScalarOrArray(curVal,'string'));
                                case {?uint64}
                                    obj(arrayIndex).(currProp.mName) = arrayfun(@(x)sscanf(char(x),'%lu'), getScalarOrArray(curVal,'string'));
                                case {?logical}
                                    obj(arrayIndex).(currProp.mName) = getScalarOrArray(curVal,'bool');
                                case {?containers.Map}
                                    map = containers.Map('KeyType','char','ValueType','char');
                                    it = curVal.entrySet.iterator;
                                    while it.hasNext
                                        kv = it.next;
                                        map(char(kv.getKey)) = char(kv.getValue.getAsString());
                                    end
                                    obj(arrayIndex).(currProp.mName) = map;
                                case {?JSONMapperMap}
                                    map = JSONMapperMap;
                                    it = curVal.entrySet.iterator;
                                    while it.hasNext
                                        kv = it.next;
                                        map(char(kv.getKey)) = char(kv.getValue.getAsString());
                                    end
                                    obj(arrayIndex).(currProp.mName) = map;                                    
                                case {?meta.class} % freeform object, decode as struct
                                    obj(arrayIndex).(currProp.mName) = jsondecode(char(curVal.toString()));
                                otherwise
                                    if isenum(obj(1).(currProp.mName))
                                        obj(arrayIndex).(currProp.mName) = arrayfun(@(x)obj(arrayIndex).(currProp.mName).fromJSON(x),getScalarOrArray(curVal,'string'));
                                    else
                                        obj(arrayIndex).(currProp.mName) = curVal;
                                    end
                            end
                        else
                            % If the field is not present in the JSON data and
                            % not null, explicitly set the object property to
                            % empty of the correct class, this allows the same
                            % method to also be used for refreshing existing
                            % objects and not only for filling in properties in
                            % new objects
                            obj(arrayIndex).(currProp.mName) = eval([currProp.dataType.Name '.empty']);
                        end
                    end
                end
            catch ME
                fprintf(2,'%s\n',ME.getReport);
                rethrow(ME)
            end
        end

        function json = jsonencode(obj,raw)
            % JSONENCODE serializes object as JSON
            % Can serialize whole hierarchies of objects if all classes
            % in the hierarchy derive from JSONMapper.
            % 
            % The function should only ever be called with one input: the
            % object to be serialized. The second input is only meant to be
            % used internally when jsonencode is called recursively.
            %
            % Example:
            %
            %   json = jsonencode(obj);
            
            % External call
            if nargin==1
                raw = false;
            end

            % Determine whether input is an array
            isArray = length(obj) > 1;
            if isArray
                arr = com.google.gson.JsonArray;
            end
            % Start a new JsonObject for the current array element
            jObject = com.google.gson.JsonObject;
            % For all elements in the array
            for arrayIndex=1:length(obj)
                
                % For all properties on the MATLAB class
                for currProp = obj(arrayIndex).MATLABProperties
                    % Only include if the property actually has been set at
                    % all on MATLAB end
                    if isempty(obj(arrayIndex).(currProp.mName))
                        continue
                    end
                    % Again the MATLAB datatype is leading to determine how
                    % data gets serialized.
                    switch currProp.dataType
                        case {?datetime}
                            dt = obj(arrayIndex).(currProp.mName);
                            val = feval(currProp.dtConversionFunction,dt);
                            jObject.add(currProp.jName,getJSONScalarOrArray(val,currProp.isArray));
                        case {?single,?double,...
                                ?int8,?uint8,?int16,?uint16,?int32,?uint32,...
                                ?string,?char,...
                                ?int64,...
                                ?logical}
                            jObject.add(currProp.jName,getJSONScalarOrArray(obj(arrayIndex).(currProp.mName),currProp.isArray));
                        case {?uint64}
                            v = obj(arrayIndex).(currProp.mName);
                            if length(v) == 1 && ~currProp.isArray
                                val = java.math.BigInteger(sprintf('%lu',v));
                            else
                                val = javaArray('java.math.BigInteger',length(v));
                                for i=1:length(v)
                                    val(i) =  java.math.BigInteger(sprintf('%lu',v(i)));
                                end
                            end
                            jObject.add(currProp.jName,JSONMapper.MATLABGSON.toJsonTree(val));
                        case {?containers.Map}
                            vals = obj(arrayIndex).(currProp.mName).values;
                            keys = obj(arrayIndex).(currProp.mName).keys;
                            m = com.google.gson.JsonObject;
                            for i=1:length(vals)
                                m.add(keys{i},JSONMapper.MATLABGSON.toJsonTree(vals{i}));
                            end
                            jObject.add(currProp.jName,m);
                        case {?meta.class, ?JSONMapperMap} % free form
                            % Use built-in jsonencode to get a JSON string,
                            % parse back using JsonParser and add to the
                            % tree
                            v = obj(arrayIndex).(currProp.mName);
                            jObject.add(currProp.jName,com.google.gson.JsonParser().parse(jsonencode(v)));
                        otherwise
                            if isenum(obj(arrayIndex).(currProp.mName))
                                jObject.add(currProp.jName,getJSONScalarOrArray([obj(arrayIndex).(currProp.mName).JSONValue],currProp.isArray));
                            else
                                jObject.add(currProp.jName,getJSONScalarOrArray(jsonencode(obj(arrayIndex).(currProp.mName),true),currProp.isArray));
                            end
                    end 
                end
                % If input was an array, add object to the array
                % a new one
                if isArray
                    arr.add(jObject)
                    jObject = com.google.gson.JsonObject;
                end
            end
            % Full JSON has been built.

            % Now return the output as string if raw == false or as
            % JsonElement when raw == true
            if isArray
                if raw
                    json = arr;
                else
                    json = char(JSONMapper.MATLABGSON.toJson(arr));
                end
            else
                if raw
                    json = jObject;
                else
                    json = char(JSONMapper.MATLABGSON.toJson(jObject));
                end
            end
        end


        function json = getPayload(obj,requiredProperties,optionalProperties)
            % GETPAYLOAD JSON encodes the object taking into account
            % required and optional properties.
            %
            % Verifies that required properties have indeed been set.
            % Includes optional properties in the output. All other
            % properties are not included in the output.

            
            % Actually first simply encode the whole thing
            json = jsonencode(obj,true);

            % And then go through all properties, checking the required are
            % indeed there and ignored properties are actively removed
            % again
            for prop = obj.MATLABProperties
                if ~isempty(requiredProperties) && ismember(prop.mName,requiredProperties)
                    if ~json.has(prop.jName)
                        if prop.isArray
                            % In case of a required array set to an empty
                            % array
                            json.add(prop.jName,com.google.gson.JsonArray)
                        else
                            % If required but not set throw an error
                            error('JSONMAPPER:ERROR','Property "%s" must be set.',prop.mName)
                        end
                    else
                        % If required and set, leave it
                        
                    end
                elseif ~isempty(optionalProperties) && ismember(prop.mName,optionalProperties)
                    if ~isempty(obj.(prop.mName))
                        % If optional and set, keep
                        
                    end
                else
                    if ~isempty(obj.(prop.mName)) && ~(isempty(optionalProperties) && isempty(requiredProperties))
                        % If not used but set, warn and remove
                        json.remove(prop.jName);
                        warning('JSONMAPPER:IGNOREDPROPERTYSET','Property "%s" has explicitly been set but will be ignored.',prop.mName)
                    else
                        % Property was set and both requiredProperties and
                        % optionalProperties were entirely empty. This may
                        % happen in oneOf, anyOf, allOf cases. In that case
                        % assume the end-user knows what they are doing and
                        % just keep the property without errors or warnings
                    end
                end
            end
            % JSON encode the object
            json = char(json.toString());
        end
    end
end

function out = getJSONScalarOrArray(val,forceArray)
    % GETJSONSCALARORARRAY helper function to ensure values are serialized
    % as an array if required.
    if forceArray && ~isa(val,'com.google.gson.JsonArray') && length(val) == 1
        out = com.google.gson.JsonArray();
        out.add(JSONMapper.MATLABGSON.toJsonTree(val));
    else
        out = JSONMapper.MATLABGSON.toJsonTree(val);
    end
end

function val = getScalarOrArray(curVal,type)
    % GETSCALARORARRAY helper function which can return MATLAB datatypes
    % from an JsonArray as well as JsonObject.


    if curVal.isJsonArray()
        switch type
            case 'double'
                t = java.lang.Class.forName('[D');
            case 'long'
                t = java.lang.Class.forName('[J');
            case 'string'
                t = java.lang.Class.forName('[Ljava.lang.String;');
            case 'bool'
                t = java.lang.Class.forName('[Z');
        end
    else
        switch type
            case 'double'
                t = java.lang.Double.TYPE;
            case 'long'
                t = java.lang.Long.TYPE;
            case 'string'
                t = java.lang.Class.forName('java.lang.String');
            case 'bool'
                t = java.lang.Boolean.TYPE;
        end
    end
    val = JSONMapper.MATLABGSON.fromJson(curVal,t);
    if type == "string"
        val = string(val);
    end

end

