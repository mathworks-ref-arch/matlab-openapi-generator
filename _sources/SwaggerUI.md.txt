# Swagger UI

The [Swagger UI](https://swagger.io/tools/swagger-ui/) is a popular package for displaying and interacting with a spec. This is useful when comparing the generated code with expected behavior.

## Install steps

Two web servers are used. One to serve the spec itself and a second to host the UI. Here we use two different simple Node.js http server packages for clarity. Note the following is intended as an example for single desktop based development, deployment in a centralized setting serving a group of developers would require similar but more extensive infrastructure. It is assumed that Node.js, Maven and a JDK are installed and configured.

Configure Node.js web servers:

```bash
sudo npm install -g http-server
sudo npm install -g httpster
```

Install and build swagger-ui:

```bash
git clone https://github.com/swagger-api/swagger-ui.git
cd swagger-ui
npm install
```

Configure ```swagger-config.yaml``` file:

```yaml
---
url: "/pathToSpec/api.yaml"
dom_id: "#swagger-ui"
validatorUrl: "https://validator.swagger.io/validator"
```

Build the html content, by default in directory `dist`:

```bash
# Also to rebuild if required
npm run build
```

Use two shells for clarity, one for each web server. Serve the custom API spec file in YAML or JSON format:

```bash
# Shell 1
cd <my-api-spec-file-dir>
# Serve the directory content
http-server -p 3334 -c-1 --cors
```

Serve the swagger GUI that references the spec served in shell 1:

```bash
# Shell 2
cd /swagger-ui

# Set the ./dist/index.html URL string to point to a local YAML or JSON spec
# url: "http://localhost:3334/myopenapi.yaml",

# Server the content on port 3333
httpster -d dist/
```

To explore the *rendered* API open [http://127.0.0.1:3333](http://127.0.0.1:3333) in a browser.

[//]: #  (Copyright 2020-2023 The MathWorks, Inc.)
