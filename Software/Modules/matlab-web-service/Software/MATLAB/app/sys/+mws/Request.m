classdef Request < dynamicprops
    % REQUEST class encapsulates the Custom Routes and Payloads request
    % structure in a more user-friendly interface.
    %
    % Request is a handle class with dynamic property support. It is
    % crucial this is a handle to allow the application to pass the same
    % Request object instance to different handlers in the handler chain.
    % I.e. it allows middleware to make changes to the object which are
    % then visible to the next function. Similarly, the dynamic property
    % support allows middleware to add extra fields to the request object
    % which are then available to the next functions.

    % Copyright 2025 The MathWorks, Inc.
    properties
        Raw struct
        Params struct
        Query dictionary = configureDictionary("string","string")
        Path matlab.net.URI
        Body uint8
        Headers matlab.net.http.HeaderField
        Application mws.Application
    end
                
    methods
        function obj = Request(raw)
            % REQUEST creates a new Request instance based on the raw
            % request struct as provided by Custom Routes and Payloads
            
            % Keep a reference of the original structure
            obj.Raw = raw;
            % Parse the Path into an easier to work with matlab.net.URI
            % instance
            obj.Path = matlab.net.URI(raw.Path);
            % Make the Body directly available as propery
            obj.Body = raw.Body;
            % Start a new structure that can hold path parameters
            obj.Params = struct;
            % If there is a query part to the Path parse the parameters in
            % an easy to access dictionary
            if ~isempty(obj.Path.Query)
                obj.Query = dictionary([obj.Path.Query.Name],[obj.Path.Query.Value]);
            else
                obj.Query = configureDictionary("string","string");
            end
            % Parse the headers into matlab.net.http.HeaderField instances
            if ~isempty(raw.Headers)
                h = raw.Headers';
                obj.Headers = matlab.net.http.HeaderField(h{:});
            end         
        end
        function obj = AddParams(obj,params)
            % ADDPARAMS adds path parameters to the Param property
            for p = string(fieldnames(params))'
                obj.Params.(p) = params.(p);
            end
        end
    end
end