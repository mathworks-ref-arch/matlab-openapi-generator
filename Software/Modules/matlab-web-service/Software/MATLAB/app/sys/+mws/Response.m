classdef Response < handle
    % RESPONSE class encapsulates the Custom Routes and Payloads response
    % structure in a more user-friendly interface.
    %
    % Response is a handle class. It is crucial this is a handle to allow
    % the application to pass the same Response object instance to
    % different handlers in the handler chain. I.e. it allows middleware to
    % make changes to the object which are then visible to the next
    % function and which the next function can add to.

    % Copyright 2025 The MathWorks, Inc.
    properties
        ApiVersion (1,3) double = [1 0 0]
        Body uint8
        HttpCode (1,1) int32 = 200
        Headers matlab.net.http.HeaderField
    end
    properties (Dependent)
        HttpMessage string
    end
    methods
        function obj = Status(obj,code)
            % STATUS sets the HttpCode.
            obj.HttpCode = code;
        end
        function obj = SendStatus(obj,code)
            % SENDSTATUS sets HttpCode to specified code, and body to the
            % corresponding default status text
            obj.HttpCode = code;
            obj.Set("Content-Type","text/plain");
            obj.Body = unicode2native(code + " - " + obj.HttpMessage,"UTF-8");
        end
        function obj = Json(obj,data)
            % JSON sets the body and adds "Content-Type: application/json"
            % header.
            obj.Set("Content-Type","application/json");
            obj.Body = unicode2native(jsonencode(data),"UTF-8");
        end
        function obj = JsonArray(obj,data)
            % JSONARRAY sets the body and adds "Content-Type:
            % application/json" header. This forces the output to
            % be a JSON Array (even if the input object is scalar only).
            obj.Set("Content-Type","application/json");
            if (isnumeric(data) || isstring(data)) 
                if isscalar(data)
                    obj.Body = unicode2native(jsonencode({data}),"UTF-8");
                else
                    obj.Body = unicode2native(jsonencode(data),"UTF-8");
                end
            elseif ischar(data)
                obj.Body = unicode2native(jsonencode({data}),"UTF-8");
            else
                obj.Body = unicode2native(data.getArrayPayload([],[]),"UTF-8");
            end
        end        
        function obj = Send(obj,data)
            % SEND sets the body.
            switch metaclass(data)
                case {?string,?char}
                    data = unicode2native(data,"UTF-8");
            end
            obj.Body = data;
        end
        function obj = SendText(obj,data)
            % SENDTEXT sets the body to the specified text and Content-Type
            % to text/plain.
            obj.Set("Content-Type","text/plain");
            obj.Body = unicode2native(data,"UTF-8");
        end        
        function val = get.HttpMessage(obj)
            % HttpMessage is automatically derived from the code.
            val = matlab.net.http.StatusCode(obj.HttpCode).getReasonPhrase;
        end
        function obj = Set(obj,name,value)
            % SET sets a header field.
            if isa(name,"matlab.net.http.HeaderField")
                if isempty(name)
                    return
                end
                value = name.Value;
                name = name.Name;
            end
            if isempty(obj.Headers.getFields(name))
                obj.Headers = obj.Headers.addFields(name,value);
            else
                obj.Headers = obj.Headers.changeFields(name,value);
            end

        end
        
        function s = GetStruct(obj)
            % GETSTRUCT gets the response as a MATLAB Production Server
            % compatible struct.
            
            % Form the struct which MATLAB Production Server expects
            s = struct( ...
                ApiVersion=obj.ApiVersion,...
                HttpCode=double(obj.HttpCode), ...
                HttpMessage=char(obj.HttpMessage));
            if ~isempty(obj.Body)
                s.Body = obj.Body;
            end
            if ~isempty(obj.Headers)
                s.Headers = [cellstr([obj.Headers.Name]);cellstr([obj.Headers.Value])]';
            end
            
        end

    end
    
end