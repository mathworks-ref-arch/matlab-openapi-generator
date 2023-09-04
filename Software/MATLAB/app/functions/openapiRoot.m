function [rootStr] = openapiRoot(varargin)
    % openapiRoot Function to return the root folder for the OpenAPI interface
    %
    % openapiRoot alone will return the root for the MATLAB code in the
    % project.
    %
    % openapiRoot with additional arguments will add these to the path
    % 
    %  funDir = openapiRoot('app', 'functions')
    %
    %  The special argument of a negative number will move up folders, e.g.
    %  the following call will move up two folders, and then into
    %  Documentation.
    %
    %  docDir = openapiRoot(-2, 'Documentation')

    % Copyright 2022 The MathWorks, Inc.
    
    rootStr = fileparts(fileparts(fileparts(mfilename('fullpath'))));

    for k=1:nargin
        arg = varargin{k};
        if isstring(arg) || ischar(arg)
            rootStr = fullfile(rootStr, arg);
        elseif isnumeric(arg) && arg < 0
            for levels = 1:abs(arg)
                rootStr = fileparts(rootStr);
            end
        else
            error('OPENAPI:openAPIRoot', ...
                'Bad argument for openAPIRoot');
        end
    end

end %function
