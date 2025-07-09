# Server Request and Response Classes

This section of the documentation documents the {class}`Request` and {class}`Response` classes in more detail.

`````{class} Request

The {class}`Request` class basically only has properties which you can simply read from directly. You do not need to interact with any of its methods.

**Properties**

````{attribute} Raw
The original raw request in its Custom Routes and Payloads low-level structure format. Generally you should not have to interact with this directly, and instead use the higher-level properties listed below, but it is available here if necessary.
````

````{attribute} Params
A structure representing all the path parameters which were parsed from the path. If there are no path parameters defined for the operation, this will be an empty struct. If path parameters have been defined it will be a structure in which the names of the fields match the names of the path parameters. The fields should always exist, but their values may be empty depending on how the operation was called exactly.

Note that all values will always be strings. If you are expecting a numerical value convert it as appropriate.

```{caution}
Do **not** use {func}`str2num` to convert path parameter values to numerical values. Its usage of {func}`eval` can lead to security vulnerabilities. 
```

For example if a route was defined as:

```matlab
app.get('/some/path/{foo}/{bar}',@myHandler);
```

Then inside `@myHandler` you should be able to write:

```matlab
function myHandler(req,res,~)
    % Get the value of Path parameter foo
    foo = req.Params.foo;
    % And bar
    bar = req.Params.bar
```

And the following table then shows what values `foo` and `bar` could for example get, depending on the request path:

| Request Path       | foo     | bar     |
|--------------------|---------|---------|
| /some/path/abc     | `"abc"` | `""`    |
| /some/path/abc/123 | `"abc"` | `"123"` |

Note that if you make a request to `/some/path`, this will not be handled by `@myHandler` at all, only the _last_ path parameter may be empty.
````

````{attribute} Query
A dictionary with all query parameters. The query parameters are also available as part of the {attr}`Path` property, but this provides a more convenient way to access them. Note that all values will always be strings. If you are expecting a numerical value convert it as appropriate.

```{caution}
Do **not** use {func}`str2num` to convert query parameter values to numerical values. Its usage of {func}`eval` can lead to security vulnerabilities. 
```

For example if a route was defined as:

```matlab
app.get('/some/path',@myHandler);
```

Then when a request was made to `/some/path?foo=hello&bar=123`

You should be able to access parameters `foo` and `bar` as follows:

```matlab
function myHandler(req,res,~)
    % Get the value of foo
    foo = req.Query("foo");
    % Note that the line above would fail if parameter "foo"
    % had not been set in the request, so it is better to
    % use `lookup` with a `FallbackValue`
    bar = req.Query.lookup("bar",FallbackValue="");
    % And for example then also verify the input
    if bar == ""
        res.Status(400).SendText("Value bar must be provided and cannot be empty.");
        return
    end
```

````

````{attribute} Path
The path of the request, parsed into a {class}`matlab.net.URI` instance.
````

````{attribute} Body
The raw request body as {class}`uint8` bytes. It is not automatically parsed into anything else, regardless of what `Content-Type` headers may have been set. If you for example want to parse the data into a string you will need to manually do this using {func}`native2unicode`. Or if you have a model class for the request body in question you can for example use:

```matlab
myData = MyServer.models.MyData().fromJSON(req.Body);
```
````

````{attribute} Headers
The headers of the request, parsed into an array of {class}`matlab.net.http.HeaderField`.
````

`````


`````{class} Response

The {class}`Response` class has both properties and methods. While it is possible to directly modify the properties to influence the response, it is generally recommended to use the methods to construct the response. 

```{note}
None of the methods immediately send a response to the client when that method is called (despite some of them even being called `Send...`). They rather set up the response to be sent later once the method fully completes. Explicitly include {func}`return` statements in your code where appropriate to end the function and allow the response to be send. Note that when the function ends and the response has been send, this also really end the entire interaction with the client and you can no longer send additional data/responses/etc.
```

The {class}`Response` class aims to offer a fluent API, which means that most methods below will return the {class}`Response` instance itself as output. Which allows you to "chain" calls of methods together. E.g. you can write `res.Status(200).SendText("Hello World")` to set the status code, response body, and content type in a single line.

**Methods**

````{method} SendStatus(res,code)
Sets the HTTP response code to the specified response code, the response body to the default text message corresponding to the code and `Content-Type` header to `text/plain`.

:param code: the numeric HTTP response code.
:returns: `res` the response instance itself.
````

````{method} Status(res,code)
Sets the HTTP response code to the specified response code.

:param code: the numeric HTTP response code.
:returns: `res` the response instance itself.
````

````{method} Json(res,data)
Sets the {attr}`Body` to a JSON representation of the input data and sets `Content-Type` header to `application/json`.

The data is first converted into a string JSON representation internally by calling `jsonencode(data)`. In that sense `data` must be compatible with built-in {func}`jsonencode` or if `data` is a class it may implement its own `jsonencode` method. Generated Model classes, do implement such a method and are fully compatible with this.

The string JSON data is then UTF-8 encoded using {func}`unicode2native` to form the raw binary response body.

:param data: input data.
:returns: `res` the response instance itself.
````

````{method} JsonArray(res,data)
Sets the {attr}`Body` to a JSON **Array** representation of the input data and sets `Content-Type` header to `application/json`. The difference with the {meth}`Json` method is that this really forces the output to always be a JSON array even if the input was just a scalar, whereas {meth}`Json` will output a _scalar_ JSON object or primitive if the input was a scalar.

This method can be helpful because in MATLAB in general there is no real difference between "an array containing a scalar" and "just a scalar". This method abstracts away some of the logic which you would need to add to force your scalar to become a JSON array (like having to wrap your scalar in a cell-array).

:param data: input data.
:returns: `res` the response instance itself.
````

````{method} Send(res,data)
Sets the {attr}`Body` to the input data. If the input is of type {class}`char` or {class}`string`, it is automatically encoded as UTF-8 bytes using {func}`native2unicode`. If the input is of any other type, it is passed through as-is meaning it should already by of type {class}`uint8` or MATLAB must be able to automatically convert it to {class}`uint8`.

Note this method _never_ sets the `Content-Type` header, even if it did automatically encode {class}`char` or {class}`string`. Use {meth}`SendText` if you also automatically set it to `text/plain`. Or use {meth}`Set` to set your own headers.

:param data: input data.
:returns: `res` the response instance itself.
````

````{method} SendText(res,text)
Sets the {attr}`Body` to the input text and `Content-Type` header to `text/plain`. The input text is automatically encoded as UTF-8 using {func}`unicode2native`.

:param data: input text.
:returns: `res` the response instance itself.
````

````{method} Set(res,name,value)
Sets a header field to the specified value. If a header with the same name had already been set, it will be overwritten with the new value. If a header with the specified name did not yet exist it will be added. 

:param name: name of the header field.
:param data: value of the header field.
:returns: `res` the response instance itself.
````

````{method} GetStruct(res)
Returns the response in Custom Routes and Payloads response structure format. You generally do not have to call this method ever, the higher level framework will call it where necessary.

:returns: a Custom Routes and Payloads response structure.
````

**Properties**

````{attribute} ApiVersion
The internal API version of the Custom Routes and Payloads feature. At the time of writing there is only one version: `[1 0 0]`.
````

````{attribute} Body
The response body. This is in {class}`uint8` binary format.

Instead of interacting with this property directly it is recommended to use methods like {meth}`Send`, {meth}`SendText`, {meth}`Json` or {meth}`JsonArray` to set the {attr}`Body` instead.
````

````{attribute} HttpCode
The HTTP status code to set on the response. 

Instead of interacting with this property directly it is recommended to use {meth}`Status` or {meth}`SendStatus` to set the {attr}`HttpCode` instead.

Its default value is `200` but for clarity it is recommended to always explicitly set the response code in your code even if should be `200`. For example:

```matlab
name = req.Query.lookup("name",FallbackValue="")
if name == ""
    % For an error response you will really want to set an error response code
    res.Status(400).SendText("name parameter is required and cannot be empty");
else
    % Strictly speaking not absolutely necessary to set the Status to 200 - OK
    % as it is the default, but recommended to make a clear distinction from
    % the condition above
    res.Status(200).SendText("Hello " + name);
end
```
````

````{attribute} Headers
Array of matlab.net.http.HeaderField

Instead of interacting with this property directly it is recommended to use {meth}`Set` to set headers instead.
````


`````