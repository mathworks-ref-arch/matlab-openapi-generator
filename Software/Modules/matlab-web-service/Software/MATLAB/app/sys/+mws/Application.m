classdef Application < dynamicprops
    % APPLICATION main class for implementing MATLAB based API Servers
    % using the MATLAB Web Service

    % Copyright 2025 The MathWorks, Inc.
    properties
       Debug = false
    end    
    properties (Access=private)
        routes cell

        currentIndex
        currentRes
        currentReq
    end

    methods
        function app = Application(config)
            % APPLICATION creates a new Application instance
            arguments
                config.?mws.Application
            end
            for p = string(fieldnames(config))'
                app.(p) = config.(p);
            end
        end
        function app = use(app,path,func)
            % USE add a generic handler for all http methods.
            % 
            % Typically used to add middleware.
            
            if isa(path,'function_handle')
                % If no path specified, add for any path
                app.routes{end+1} = {'.*',path};
            else
                % If a path is given, add for this path, but do still add
                % for all http methods
                app.routes{end+1} = {".*? " + path,func};
            end
        end
        function app = get(app,path,func)
            % GET add a get handler to the router
            app.routes{end+1} = {"GET " + app.processPath(path),func};
        end
        function app = post(app,path,func)
            % POST add a post handler to the router
            app.routes{end+1} = {"POST " + app.processPath(path),func};
        end
        function app = put(app,path,func)
            % PUT add a put handler to the router
            app.routes{end+1} = {"PUT " + app.processPath(path),func};
        end
        function app = patch(app,path,func)
            % PATCH add a patch handler to the router
            app.routes{end+1} = {"PATCH " + app.processPath(path),func};
        end
        function app = del(app,path,func)
            % DEL add a del handler to the router
            app.routes{end+1} = {"DELETE " + app.processPath(path),func};
        end

        function response = handleRequest(app,s)
            % HANDLEREQUEST fully handles the request based on the
            % Application configuration.

            % Initialize all default values for a new request
            app.currentIndex = 0;
            app.currentReq = mws.Request(s);
            app.currentReq.Application = app;
            app.currentRes = mws.Response();
            % If anything fails here, return a 500 error
            try 
                % Call next to start going through the routes. Next may
                % call itself recursively to achieve a whole chain of
                % function with middleware being called
                app.next(s)
                % When all the functions have been called, return the final
                % respsone 
                response = app.currentRes.GetStruct();
            catch ME 
                % Print the error report to internal logging
                fprintf(2,ME.getReport()+"\n");
                % In Debug mode return the error stack to the client
                if app.Debug
                    response = mws.Response().Status(500).Json( ...
                        struct('error',ME) ...
                    ).GetStruct();
                else
                    % As Http Response returna a generic internal server error
                    response = struct( ...
                        ApiVersion=[1 0 0], ...
                        HttpCode=500, ...
                        HttpMessage='Internal Server Error');
                end
            end

        end
    end

    methods (Access=private)
        function path = processPath(~,path)
            % PROCESSPATH replaces route parameters with the correct MATLAB
            % regular expressions such that they can be matched as named
            % tokens.

            % Replace any route parameters which are somewhere in the
            % middle of the path 
            % Express style
            path = regexprep(path,"/:([^/]*)/","/(?<$1>[^/]*)/");
            % OpenAPI style
            path = regexprep(path,"/\{([^/]*)\}/","/(?<$1>[^/]*)/");

            % Route parameters at the very end of the path (i.e. not
            % followed by a slash) are handled slightly differently, we
            % make the slash which precedes it optional. We obviously want
            % /foo/:myparam to be callable as /foo/somevalue (where then
            % Params.myparam = "somevalue")*but also* as /foo (where then
            % Params.myparam = "").
            % Express style
            path = regexprep(path,"/:([^/]*)","[/]?(?<$1>[^/]*)");
            % OpenAPI style
            path = regexprep(path,"/\{([^/]*)\}","[/]?(?<$1>[^/]*)");

            % Finally allow OpenAPI style path parameters anywhere in the
            % Path without any further special treatment of requiring
            % slashes or not, only do treat a slash at the end as the end
            % of the parameter
            path = regexprep(path,"\{([^/]*)\}","(?<$1>[^/]*)");
            % Add $ to not allow anything else after the path (other than
            % query parameters, which will be omitted when matching later).
            path = path + "$";
        end
        function next(app,s)
            % (Continue) going through the routes to see what needs to
            % be called
            
            % The current Path has to be preprocessed just once, do
            % this before the loop.
                        
            % Split off query parameters
            p = split(s.Path,"?");
            % Remove trailing slashes
            p = strip(p(1),"right","/");
            % Add request method
            p = upper(s.Method) + " " + p;
            
            % Use regexp to see whether there is a match (and if
            % there is to also immediately parse route parameters
            % into a struct).
            for i = app.currentIndex+1:length(app.routes)
                app.currentIndex = i;

                route = app.routes{i}{1};

                match = regexp(p,route,"names");
                
                if ~isempty(match)
                    % If matched, call the function
                    app.currentReq.AddParams(match);
                    feval(app.routes{i}{2},app.currentReq,app.currentRes,@()app.next(s));
                    % After that, return. Never just continue here, if
                    % the user's code want us to continue it should
                    % explcitly call next()
                    return
                end
            end
            % If this point is reached there was no match, in that case return a 404
            app.currentRes.SendStatus(404);
        end        
    end
end