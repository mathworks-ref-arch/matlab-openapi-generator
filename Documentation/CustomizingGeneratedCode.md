# Customizing Generated Client Code

After the MATLAB code has been generated it may be necessary to customize the generated code. The following describes tips to help in doing so and typical points within the generated code where modifications might be made.

## Hints

```{hint}
Generated models derive from a `JSONMapper` base class and the properties in the Model classes are "annotated" using `JSONMapper` "annotations". See [References/JSONMapper](JSONMapper.md) to learn more about this class.
```

```{hint}
For common functionality consider changing the `BaseClient` to that changes propagate to all derived API classes.
```

```{hint}
If changing the `preSend`, `postSend` or `BaseClient` call a function perhaps in separate namespace rather than several lines of code, [https://www.mathworks.com/help/matlab/matlab_oop/scoping-classes-with-packages.html](https://www.mathworks.com/help/matlab/matlab_oop/scoping-classes-with-packages.html) so that added code is more distinct from the generated code and reinserting just one line of code adds back functionality making diffs or merges simpler.
```

## Source control

Before modifying the code it is strongly advised to use source control of some form so if the code is regenerated later changes are not lost and changes can be checked against generated code.
Source controlling the source spec and any build scripts is also recommended so that changes to them can be recorded over time also. This provides an exact means of recording what version of a spec generated what version of a client and potentially recreating it if necessary. This package notes the version of the package used to generate code as a comment in the code itself.

## Selective generation

The generator takes standard openapi-tools arguments that would allow generation of the APIs or the Models or subsets. This is mostly useful if editing the spec itself or if it is known that a only specific part of a spec has changed. One can use a `.openapi-generator-ignore` file to define files to not regenerate.

## Unsupported Content-Type

The package only supports `application/json` and `application/x-www-form-urlencoded` body parameter inputs and `application/json` body replies. If some operations in the API only support other types e.g. `application/xml` the generated code will have to be manually modified to make these calls possible.

Each and every method/operation will check the in- and output content-types if there are any. For example the `addPet` method for the Pet Store v3 example will contain code like the following:

```matlab
% Verify that operation supports JSON or FORM as input
specContentTypeHeaders = [...
    "application/json", ...
    "application/xml", ...
];
if ismember("application/json",specContentTypeHeaders)
    request.Header(end+1) = matlab.net.http.field.ContentTypeField('application/json');
elseif ismember("application/x-www-form-urlencoded",specContentTypeHeaders)
    request.Header(end+1) = matlab.net.http.field.ContentTypeField('application/x-www-form-urlencoded');
else
    error("PetStore:api:addPet:UnsupportedMediaType","Generated OpenAPI Classes only support 'application/json' and 'application/x-www-form-urlencoded' MediaTypes.\n" + ...
        "Operation '%s' does not support this. It may be possible to call this operation by first editing the generated code.","addPet")
end
```

This code will be executed for each and every call to `addPet`. On the one hand this should not be necessary, this is basically static code resulting in the same code path being followed each call, and it for example does *not* depend on inputs. On the other hand though, overhead is minimal *and* this approach does allow easier customization on a per operation/method basis.

When manually adding support for other content-types for specific operations, make sure to also update these checks otherwise the method will still error out.

## Authentication

In OpenAPI 3, the spec can declare various named authentication methods. And then, for each separate operation, it can specify whether it requires authentication at all, and if so, which of the named methods are supported.

Basic or Digest authentication should work by default (as long as the correct `matlab.net.http.Credentials` are provided to the client object). API Key based authentication should work as well (if the correct `apiKey` is set on the client object). However, *proper* oAuth authentication may need customization. See the [Authentication](#authentication) section below to learn more about how the generated classes work with authentication and what customizations may be needed.

For the *entire* package exactly *one* `requestAuth` method is generated and it is part of the generated `<PackageName>.BaseClient` class. All the API classes derive from this `BaseClient` class. The `requestAuth` method will contain a `switch, case, otherwise` statement to handle the various authentication mechanisms based on their name. For example for the Pet Store v3 example, it will look like the following:

```matlab
function  [request, httpOptions, uri] = requestAuth(obj, request, httpOptions, authNames, uri)
    % requestAuth will be called by operations which require 
    % authentication. May have to be extended or modified after code 
    % generation. For example, authentication methods not present in the
    % service OpenAPI spec or methods not directly supported by the
    % generator will have to be added. Generated logic may also not be
    % 100% correct if the OpenAPI spec contained multiple different 
    % authentication methods of the same type.
    switch authNames
        case "api_key"
            % Key based authentication, assumes apiKey property has been set 
            request.Header(end+1) = matlab.net.http.field.GenericField("api_key",obj.apiKey);
        case "petstore_auth"
            % oAuth authentication, calls getOAuthToken and adds returned token as Bearer authorization header
            request.Header(end+1) = matlab.net.http.field.AuthorizationField("Authorization","Bearer " + obj.getOAuthToken("petstore_auth"));
        otherwise
            error("PetStore:UnknownAuthorization", "Operation requested an authentication method which was not specified in the OpenAPI spec.")
    end
end
```

Each operation which requires authentication will call this method before making its actual request. The `requestAuth` method then updates the request or HTTPOptions with the relevant settings and returns the updated request/options as output.

```{hint}
Not all specs follow this approach strictly. For example, in some cases where *all* operations require the same authentication, some specs may not list the supported authentication methods on a per operation basis. In that case, the generator will *not* generate calls to `requestAuth` in the operation methods. In such cases, consider using the [`AddOAuth` option](./Options.md#addoauth) when generating the client or use [`preSend`](#presend) to authenticate the requests before they are made.
```

```{note}
It is recommended to check the generated `requestAuth` for correctness and fix any issues it may contain to ensure safe usage of the generated code and safe access to the APIs.
```

As can be seen in the example above, where the `petstore_auth` method is in fact OAuth based, `requestAuth` will call another generated method for OAuth based authentication mechanisms: `getOAuthToken`. This method will very likely have to be customized.

### OAuth and `getOAuthToken`

For OAuth based authentication, the generator will generate an additional method `getOAuthToken`, for example:

```matlab
function token = getOAuthToken(obj, name) %#ok<INUSD> 
    %% To be customized after code generation
    % This template method simply returns the bearerToken of the object
    % which is assumed to have been manually set after manually having 
    % completed the OAuth flow. Typically this method should be 
    % customized to return a properly cached still valid token, refresh
    % an cached expired token just-in-time or perform the entire OAuth
    % flow from the start just-in-time and cache the token.
    %
    % As the exact OAuth flow may vary by OAuth provider, the full
    % authentication flow is not automatically generated and the 
    % template method simply returns the bearerToken property.
    token = obj.bearerToken;

    % The code below can be uncommented and then used as a starting 
    % point to fully implement the OAuth flows for the flows specified 
    % in the API spec.

    % switch name
    %     case "petstore_auth"
    %         % Implicit Flow
    %         authorizationUrl = "/api/oauth/dialog";
    %         refreshUrl = "";
    %         
    %         % Scopes defined in spec
    %         scopes = [...
    %             "write:pets",... % modify pets in your account
    %             "read:pets",... % read your pets
    %         ];
    %     otherwise
    %         error("PetStore:UnknownOAuth", "Operation requested an OAUth flow which was not specified in the OpenAPI spec.")
    % end
end
```

As indicated in the comments of this code, this is really just template code which *will* allow calling operations requiring an OAuth Bearer Token *if* the `bearerToken` property of the client object has been set to a *manually* obtained token. Ideally that token should not have to be obtained manually though; this is something which this method should actually do. Ideally this method is updated such that it can:

1. Obtain (with user interaction if needed) and then cache new tokens if there are no cached tokens yet.

2. (Silently without needing user interaction) return a cached token if available and still valid.

3. Just-in-time (silently without needing user interaction) refresh a cached token if available but expired. (And if automatically refreshing fails/is not possible, obtain and cache an entirely new token (which may require user interaction then)).

## preSend and postSend methods

The `BaseClient` is generated with `preSend` and `postSend` methods which will be called by all operations right before and after sending their requests. By default these methods do not actually do anything but they can be [customized](#presend-and-postsend-methods). The `BaseClient` class `preSend` and `postSend` methods:

```matlab
function [request, httpOptions, uri] = preSend(obj, operationId, request, httpOptions, uri) %#ok<INUSL> 
    % preSend is called by every operation right before sending the
    % request. This method can for example be customized to add a
    % header to all (or most) requests if needed. 
    %
    % If the requests of only a few operations need to be customized
    % it is recommended to modify the generated operation methods
    % in the API classes themselves rather than modifying preSend.
    %
    % By default the generated preSend does not do anything, it just
    % returns the inputs as is.
end

function response = postSend(obj, operationId, response, request, uri, httpOptions)  %#ok<INUSD,INUSL>
    % postSend is called by every operation right after sending the
    % request. This method can for example be customized to add
    % customized error handling if the API responds to errors in a
    % consistent way.
    %
    % If the responses of only a few operations need to be customized
    % it is recommended to modify the generated operation methods
    % in the API classes themselves rather than modifying postSend.
    %
    % By default the generated postSend does not do anything, it just
    % returns the response as is.
end
```

As noted in the comments in this code, these methods are called by all operations, right before and after sending their requests.

### preSend

By default the generated `preSend` method does not do anything but it offers an entrypoint for customization *if needed*.

The `preSend` method can be customized if *all or at least most* requests need some customization before being send. For example, a header field could be added.

Further, some APIs require authentication on *all* operations and then do not specify on a *per operation* basis that they require authentication. In that case it is possible to add the authentication in `preSend`, note however that it is also possible to use the [`AddOAuth` option](./Options.md#addoauth) for this.

```{note}
If only a few specific operations need customization it makes more sense to edit their methods in the API classes directly rather than handling this in `preSend`.
```

### postSend

By default the generated `postSend` method does not do anything but it offers an entrypoint for customization *if needed*.

The `postSend` can be used to customize or parse responses of all requests. For example, API specific error handling can be added here if most operations in the API respond to errors in a consistent way.

## Selective generation

By default, the tool will generate code for *all* models in the spec. To selectively generate a feature, the client can be configured using global-properties. For example:

```matlab
client.globalProperty = "models"; % Generate only models
client.globalProperty = "apis";   % Generate only APIs
client.globalProperty = "models,supportingFiles"   % Generate models and supporting files
client.globalProperty = "models=""User:Pet"""      % Generate the User and Pet models only
client.globalProperty = "skipFormModel = false"    % Generate for OAS3 and ver < v5.x using the form parameters in "requestBody"
```

[//]: #  (Copyright 2023-2024 The MathWorks, Inc.)
