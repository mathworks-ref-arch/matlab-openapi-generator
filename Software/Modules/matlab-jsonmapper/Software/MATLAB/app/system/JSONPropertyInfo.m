classdef JSONPropertyInfo < handle
    % JSONPROPERTYINFO class used by JSONMapper internally

    % Copyright 2022 The MathWorks, Inc.

    properties
        mName string
        jName string
        dataType meta.class
        isArray logical
        dtConversionFunction function_handle
    end


    methods (Access=private)
    
    end
    methods (Static)
        function props = getPropertyInfo(obj)
            % For all public properties
            ps = properties(obj);
            N = length(ps);
            props = JSONPropertyInfo.empty(N,0);
            for i = 1:N
                pm = findprop(obj,ps{i});
                % Set basic properties like the MATLAB name and class
                props(i).mName = pm.Name;
                props(i).dataType = pm.Validation.Class;
                % If class was not set (to allow freeform object properties)
                % still set a specific dataType to allow fromJSON to parse this
                % into a struct using standard jsondecode.
                if isempty(props(i).dataType)
                    % meta-ception
                    props(i).dataType = ?meta.class;
                end
                % Check the "attributes" for further settings
                attrs = cellfun(@(x)functions(x).function,pm.Validation.ValidatorFunctions,'UniformOutput',false);
                if isempty(attrs) % If there are no attributes
                    % Names are the same
                    props(i).jName = pm.Name;
                    % It is not an array
                    props(i).isArray = false;
                    % Throw an error if data type is datetime because this
                    % should have had a dtConversionFunction
                    if props(i).dataType == ?datetime
                        error('JSONMapper:InvalidDatetimeProperty', ...
                            'Property %s is defined as `datetime` but does not have a valid conversion function.',pm.Name);
                    end
                else
                    % If datetime, the first "attribute" must be the
                    % type definition
                    if props(i).dataType == ?datetime
                        props(i).dtConversionFunction = pm.Validation.ValidatorFunctions{1};
                    end
                    % Check for JSONArray attribute
                    props(i).isArray = any(strcmp(attrs,'JSONMapper.JSONArray'));
                    % Check for fieldName attribute
                    fi = find(contains(attrs,"JSONMapper.fieldName"));
                    if isempty(fi) 
                        % If there is none JSON name is same as MATLAB
                        props(i).jName = pm.Name;
                    else
                        % If there is one, call it to obtain the JSON name
                        fieldNameFcn = pm.Validation.ValidatorFunctions{fi};
                        props(i).jName = feval(fieldNameFcn,[]);
                    end
                end

            end
        end
    end

end