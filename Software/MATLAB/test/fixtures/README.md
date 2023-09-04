# Third Party Spec Tests

This directory contains a number of good quality, 'real world' 3rd party specs
that are used to test the package.

To retain the output of the third party spec tests set the `OPENAPI_KEEP_OUTPUT`
environment variable, the test output will list the temporary directories used,
otherwise output is deleted upon completion of the tests:

```matlab
setenv('OPENAPI_KEEP_OUTPUT', 'true')
```

The generated output is only checked to see that valid MATLAB code is generated
using the MATLAB `checkcode` command. No functional tests are carried out.

The following specs are used but not currently distributed with this package:

* Redis
* MLflow
* PetStore
* Airflow
* Jira

[//]: #  (Copyright 2023 The MathWorks, Inc.)
