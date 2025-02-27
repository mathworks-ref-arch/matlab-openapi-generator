function [tf, response] = createGitLabProjectAPICall(obj)
    % createGitLabProjectAPICall Uses the GitLab REST API to create a new project
    % See: https://docs.gitlab.com/ee/api/projects.html#create-project
    % Additional GitLab options can be supported by exposing the data
    % struct.
    %
    % Curl equivalent example:
    %
    % curl --request POST --header "PRIVATE-TOKEN: <your-token>" \
    %  --header "Content-Type: application/json" --data '{
    %     "name": "new_project", "description": "New Project", "path": "new_project",
    %     "namespace_id": "42", "initialize_with_readme": "true"}' \
    %  --url "https://gitlab.example.com/api/v4/projects/"

    %  (c) 2024 MathWorks, Inc.

    arguments
        obj (1,1) openapi.auto.Project
    end
  
    if isfield(obj.settings, "gitlabAPIToken") &&...
            (ischar(obj.settings.gitlabAPIToken) || isStringScalar(obj.settings.gitlabAPIToken)) &&...
            strlength(obj.settings.gitlabAPIToken) > 0
        gitlabAPIToken = obj.settings.gitlabAPIToken;
    else
        error("Valid gitlabAPIToken field not found in settings file");
    end

    if isfield(obj.settings, "gitLabEndpoint") &&...
            (ischar(obj.settings.gitLabEndpoint) || isStringScalar(obj.settings.gitLabEndpoint)) &&...
            strlength(obj.settings.gitLabEndpoint) > 0
        uri = matlab.net.URI(obj.settings.gitLabEndpoint);
    else
        error("Valid gitLabEndpoint field not found in settings file");
    end

    uri.Path = ["api", "v4", "projects"];

    % Create the request object
    request = matlab.net.http.RequestMessage();
    % Configure request verb/method
    request.Method =  matlab.net.http.RequestMethod('POST');

    request.Header(end+1) = matlab.net.http.HeaderField('PRIVATE-TOKEN', gitlabAPIToken);

    request.Header(end+1) = matlab.net.http.field.ContentTypeField('application/json');

    data = struct;
    data.name = obj.projectPathName;
    data.description = obj.projectFullName;
    data.initialize_with_readme = "false";
 
    request.Body(1).Payload = jsonencode(data);

    [response, full, history] = send(request, uri); %#ok<ASGLU>

    if response.StatusCode == 201
        fprintf("Created gitLab repo: %s\n", response.Body.Data.path);
        tf = true;
    else
        tf = false;
        if isprop(response, "Body") && isprop(response.Body, "Data") && isfield(response.Body.Data, "message")
            disp("Response message:");
            disp(response.Body.Data.message);
        end
        fprintf(2, "GitLab repo creation failed: %s\n", response.StatusLine);
    end
end