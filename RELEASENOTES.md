# MATLAB Generator *for OpenAPI*

## Version 2.1.0 (February 25th 2024)

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
