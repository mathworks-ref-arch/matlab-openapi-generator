# MATLAB Generator *for OpenAPI*

## Version 3.0.2 (September 24th 2025)

* Fixes issue where the data type of enum fields were not set correctly.

## Version 3.0.1 (August 25th 2025)

* Bug fix to Git repo generation on Windows

## Version 3.0.0 (July 9th 2025)

* **Breaking Change**: The MATLAB Client Generator previously named `MATLAB` was renamed to `matlab-client` (this brings the MATLAB Client generator better in line with other OpenAPI generator names, which by convention are in  kebab-case, and makes a clearer distinction between the Client generator and the newly introduced Server generator which is named `matlab-server`). When generating clients using `openapi.build.Client` inside MATLAB, no changes are required, the builder has been updated to reflect this change. However, if calling generator from the command line using `npx @openapitools/openapi-generator-cli` (or by invoking the generator through `java` directly) make sure to update the command line arguments, replace `-g MATLAB` (or `--generator MATLAB`) with `-g matlab-client` (or `--generator matlab-client`).

* **Breaking Change**:  The name of the MATLAB Generator JAR-file was changed from `MATLABClientCodegen-openapi-generator-0.0.1.jar` to `MATLAB-openapi-generator-3.0.0.jar` to better reflect the version of the generator and to reflect that it no longer supports generating clients only; it now also supports server stub generation. When generating clients using `openapi.build.Client` inside MATLAB, no changes are required, the builder has been updated to reflect this change. However, if calling generator from the command line using `npx` make sure to update the `--custom-generator` command line arguments.

* **Major New Feature**: Added a MATLAB server generator `matlab-server`. It generates skeleton code which is designed to be deployed to [MATLAB Production Server](https://www.mathworks.com/help/compiler_sdk/mps.html) or as [Microservice](https://www.mathworks.com/help/compiler_sdk/microservice.html) and makes use of the [Custom Routes and Payloads](https://www.mathworks.com/help/mps/custom-routes-and-payloads.html) feature.

* Updated listed system requirements for the client generator to MATLAB R2021a or newer. Previous versions of the package accidentally _incorrectly_ listed R2020b as minimum supported version. This is not necessarily a breaking change in this particular package update since older versions of the package were already not (fully) compatible with MATLAB R2020b. Note that the server generator supports release R2023b or newer as it depends on various newer MATLAB Production Server and MATLAB features.

* When `JAVA_HOME` is set `openapi.build.Client` and `openapi.build.Server` now specifically use `java` from the specified `JAVA_HOME`. I.e. if `JAVA_HOME` is set, `fullfile(getenv("JAVA_HOME"),"bin","java")` is called whenever `java` needs to run. If `JAVA_HOME` is unset, they simply continue to call `java` (which requires `java` to be on the `PATH`).

* It is no longer necessary to run `setup` to download the OpenAPI Generator CLI JAR-file (or to manually download it). The required JAR-file is now downloaded by Maven as part of the build process of the MATLAB Generator JAR-file. `setup` is still provided for backwards compatibility but may be removed in future versions of the package.

* The Maven Java build is no longer configured to specifically build the Java code as _Java 11 binaries_. Instead it simply allows the compiler to use its own default binary target. This for example enables support for Java 21 (which actually no longer supports producing Java 11 binaries). Note that the minimum supported Java version is still Java 11.

* Updated default generator Java library to v7.13.0.

* Publishing HTML rendered version of the package documentation to GitHub pages.

## Version 2.1.2 (March 18th 2025)

* Added support for path entries with subfields e.g. /{name}:myaction
* Allow JSON settings file to have entries that are not base client properties

## Version 2.1.1 (March 11th 2025)

* Improved semantic version handling
* Bug fix to setup download jar step

## Version 2.1.0 (February 25th 2025)

* Added support for generation based on a directory of several specs
* Added optional GitLab integration
* Updated default generator Java library to v7.1.0

## Version 2.0.0 (December 8th 2024)

* NodeJS & npx are no longer required
* Improved setup process
* Minor bug fixes
* JSONMapper Release 0.4.3 (January 12th 2025)
  * README.md typo fix, MATLAB R2020b is required.
  * Added startup verbosity option

## Version 1.1.0 (August 8th 2024)

* Updated JSON Mapper module to v0.4.0
* Added support for polymorphism through discriminators
* Added support for arrays of object bodies
* Documentation improvements
* Changed default location of the cookie jar

## Version 1.0.9 (October 27th 2023)

* Correctly set package version in file header when using the MATLAB client
* Added support for package names containing periods when using the MATLAB client
* Minor improvement to copyright string handling

## Version 1.0.8 (October 26th 2023)

* Minor bug fix to Client error message handling

## Version 1.0.7 (October 3rd 2023)

* Add validation to MATLAB client packageName property
* npx command documentation improvements

## Version 1.0.6 (September 15th 2023)

* Fix to Basic Auth credential handling

## Version 1.0.5 (September 4th 2023)

* Minor documentation improvements

## Version 1.0.4 (August 31st 2023)

* Improved Java requirement check
* Improved CLI version handling

## Version 1.0.3 (August 16th 2023)

* Added support for integer enums
* Added `getSpecificClass` method for oneOf interfaces

## Version 1.0.2 (Jul. 27th 2023)

* Documentation improvements
* JSONMapper Release 0.3.2 (July 27th 2023)
  * Typo fixes

## Version 1.0.1 (Jul. 14th 2023)

* Improved generation accuracy
* Added support for openapitools.json file usage by default
* Changed to skip spec validation by default

## Version 1.0.0 (Jul. 7th 2023)

* Updated JSONMapper
* Client property changes to align with corresponding opeanapitools.json field names
  * Changed additionalArgs property to additionalArguments, *Breaking change*
  * Changed outDir property to output, *Breaking change*
  * Changed mustachePath property to templateDir, *Breaking change*
  * Changed specPath property to inputSpec, *Breaking change*
  * Changed additionalProperties and globalProperty to containers.Map, *Breaking change*
* Added support for setting node and npx paths
* JSONMapper Release 0.3.1 (June 16th 2023)
  * Typo fix
  * Updated startup.m

## Version 0.4.0 (4th Apr. 2023)

* Added support for selective generation via client.globalProperty setting

## Version 0.3.0 (28th Mar. 2023)

* Added support for copyright notices
* Added autoinstall support for @openapitools/openapi-generator-cli using npx
* Improved checks for 3rd party tools

## Version 0.2.0 (13th Mar. 2023)

* Added AddOAuth option
* Removed fromInput methods in favor of constructor inputs
* Minor bug fixes

## Version 0.1.4 (13th Dec. 2022)

* Updated pom file

## Version 0.1.3 (13th Dec. 2022)

* Minor bug fixes

## Version 0.1.2 (4th Oct. 2022)

* Improved documentation
* Improved unit tests
* Improved property name handling
* Added 3p legal content
* Updated JSONMapper to v0.2.0
  * Improved enum and date handling
  * Updated documentation
  * Improved empty and null handling
  * Improved free-form handling with new JSONMapperMap class

## Version 0.1.1 (26th Sept. 2022)

* Fixed issue with internal packaging pipeline

## Version 0.1.0 (Internal Only)

* Redesigned package to take advantage of JSONMapper
* Use `npx` tools for client generation
* MATLAB helper functions for generating clients
* Updated documentation

## Version 0.0.2 (Internal Only)

* Added genclient.sh script
* Documentation updates
* Typo and minor fixes

## Version 0.0.1 (27th May 2020)

* Initial Release

[//]: #  (Copyright 2022-2023 The MathWorks, Inc.)
