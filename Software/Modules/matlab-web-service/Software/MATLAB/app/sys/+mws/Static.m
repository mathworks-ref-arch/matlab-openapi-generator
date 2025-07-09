classdef Static < handle
    % STATIC Serves static files from a local directory
    
    % Copyright 2025 The MathWorks, Inc.
    properties
        LocalPath
        MountPath
        IndexFileNames = ["index.html", "index.htm"]
    end
    methods (Access=private)
        function obj = Static(config)
            arguments
                config.?mws.Static
            end
            for p = string(fieldnames(config))'
                obj.(p) = config.(p);
            end
        end

        function handleRequest(obj,req,res,~)
            % Remove the mount path
            p = extractAfter(req.Path.EncodedPath,obj.MountPath);

            absPath = fullfile(obj.LocalPath,p);

            % If folder, not a file, consider serving index.htm(l)
            if isfolder(absPath)
                for fn = obj.IndexFileNames
                    if isfile(fullfile(absPath,fn))
                        absPath = fullfile(absPath,fn);
                        break
                    end
                end
            end
            
            % Check whether file exists locally
            if ~isfile(absPath)
                % If not,return 404 - Not Found
                res.SendStatus(404);
                return
            else
                % If found double check the file is indeed inside the shared root
                f = fopen(absPath,'r');
                absPath = fopen(f);
                fclose(f);
                % If not, return 404
                if ~startsWith(absPath,obj.LocalPath)
                    res.SendStatus(404);
                    return
                end
                % If so, simply serve up the file
                [~,~,ext] = fileparts(absPath);
                res.Set("Content-Type",getMimetype(ext));
                res.Status(200).Send(fileread(absPath));
            end

        end

    end
    methods (Static)
        function handler = newHandler(config)
            arguments
                config.?mws.Static
            end
            cfg = namedargs2cell(config);
            instance = mws.Static(cfg{:});
            handler = @instance.handleRequest;
        end
    end
end

function contentType = getMimetype(fileExt)
    switch lower(fileExt)
        case {'.html','.htm'}
            contentType = 'text/html';
        case '.css'
            contentType = 'text/css';
        case '.js'
            contentType = 'application/javascript';
        case {'.jpg', '.jpeg'}
            contentType = 'image/jpeg';
        case '.png'
            contentType = 'image/png';
        case '.gif'
            contentType = 'image/gif';
        case '.svg'
            contentType = 'image/svg+xml';
        case '.pdf'
            contentType = 'application/pdf';
        case '.json'
            contentType = 'application/json';
        case '.xml'
            contentType = 'text/xml';
        case '.txt'
            contentType = 'text/plain';
        case '.mp4'
            contentType = 'video/mp4';
        case '.mp3'
            contentType = 'audio/mpeg';
        case '.woff'
            contentType = 'font/woff';
        case '.woff2'
            contentType = 'font/woff2';
        case '.ttf'
            contentType = 'font/ttf';
        case '.otf'
            contentType = 'font/otf';
        case '.zip'
            contentType = 'application/zip';
        case '.rar'
            contentType = 'application/vnd.rar';
        case '.webmanifest'
            contentType = 'application/manifest+json';
        case {'.doc', '.docx'}
            contentType = 'application/msword';
        case {'.xls', '.xlsx'}
            contentType = 'application/vnd.ms-excel';
        case {'.ppt', '.pptx'}
            contentType = 'application/vnd.ms-powerpoint';
        case '.pages'
            contentType = 'application/vnd.apple.pages';
        case '.numbers'
            contentType = 'application/vnd.apple.numbers';
        case '.key'
            contentType = 'application/vnd.apple.keynote';
        case '.md'
            contentType = 'text/markdown';
        otherwise
            contentType = 'application/octet-stream';
    end
end