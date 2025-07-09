# Project generation

The `openapi.auto.Project` class is a high-level wrapper that can be used to
quickly generate a client for a given spec and optional store the results in
GitLab™. This can provide a quick starting point for more specific customization
of a client.

## Examples

By default a project name and a spec path or URL are sufficient to create a project.

```matlab
projectBaseName = "GitLab"
spec = "https://gitlab.com/gitlab-org/gitlab/-/raw/master/doc/api/openapi/openapi.yaml"
p = openapi.auto.Project(projectBaseName, spec)
```

```matlab
projectBaseName = "GitLab"
spec = "c:\openapi\openapi.yaml"
clientArgs = {"copyrightNotice", " (c) 2025 Example.com"}
p = openapi.auto.Project(projectBaseName, spec, additionalClientArguments=clientArgs)
```

> Use `doc openapi.auto.Project` for a description to the supported optional arguments.

## Settings file

A template settings file is provided: `Software/MATLAB/config/project_settings.json.template`.
This file should be renamed to `project_settings.json` and customized. An alternative
path can be specified as an optional `openapi.auto.Project` input.

The template has the following content:

```json
{
    "projectBaseDirectory" : "/home/username/git",
    "baselineFiles" : ["/home/username/git/baseline/LICENSE.MD", "/home/username/git/baseline/SECURITY.md"],
    "copyrightNotice" : "My Company Inc.",
    "gitlabAPIToken" : "sdas[REDACTED]dasd",
    "gitLabEndpoint" : "https://gitlab.example.com/",
    "gitLabUsername" : "jdoe",
    "apiDocGeneratorPath" : "/home/username/git/APIMarkdownDocGenerator"
}
```

## Notes

* If a git repository is to be created a git client on the system path is assumed.
* API reference documentation generation is not currently enabled.
* Additional customization to enable authentication is typically required.

[//]: #  (Copyright 2024 The MathWorks, Inc.)
