# RWAHS Tools

Tools to assist with integration and deployment of RWAHS software.

## Overview

The `rwahs` command handles all steps of integration and deployment via various tasks.

The general syntax is:

    rwahs <task> --env <environment> --component <component>...

Using the shorthand form for parameters:

    rwahs <task> -e <environment> -c <component>...

## Standard Options

* The `--env`/`-e` and `--component`/`-c` parameters apply to most of the tasks.
* The `--component`/`-c` parameter can be repeated to process multiple components sequentially (in the order specified).

## Environments

The following environments are defined:

* `staging`
* `uat`
* `production`

## Components

* `tools` is this tools repository, i.e. a self-update: https://github.com/rwahs/tools
* `providence` is the CollectiveAccess management application: https://github.com/rwahs/providence
* `profile` is the CollectiveAccess installation profile (meta-schema): https://github.com/rwahs/installation-profile
* `config` is the CollectiveAccess local configuration: https://github.com/rwahs/providence-configuration
* `importer` is the collection of import scripts and queries: https://github.com/rwahs/import-scripts

## Tasks

### Build

Create a new release, which is a tag in the code repository.  

Syntax for the `build` task:

    rwahs build --component <component> [--release <release>]

Using shorthand form for parameters:

    rwahs build -c <component> [-r <release>]

The optional `--release`/`-r` parameter specifies the name of the release, which must be unique for the given 
component.  If the name already exists, an error is emitted.  If the `--release`/`-r` option is omitted, the release 
name is generated based on the current timestamp.

Note this task does not understand the `--env`/`-e` option, because releases exist independently of environments.

### Deploy

Transfer the specified release to the specified environment and update the environment to make the specified release
the "current" version used in the given environment.

Syntax for the `deploy` task:

    rwahs deploy --env <env> --component <component> --release <release>

Using the shorthand form for parameters:

    rwahs deploy -e <env> -c <component> -r <release>

Following the deployment, any required initialisation tasks are performed.  Specifically, when the "providence"
component is deployed, any pending database migrations are applied.  Additionally, caches are cleaned and services are
restarted as appropriate.

### Clean

Remove all data from the database, restoring it to a clean state following a fresh installation of the current profile
(i.e. the profile most recently deployed to the given environment).

Syntax for the `clean` task:

    rwahs clean --env <env> --component <component>

Using the shorthand form for parameters:

    rwahs clean -e <env> -c <component>

This task does not accept any additional parameters.

### Import

Run the import scripts, converting data from the legacy database format into the format required by CollectiveAccess,
and inserting the data into the environment's database.

Syntax for the `import` task:

    rwahs migrate --env <env> [--clean]

Using the shorthand form for parameters:

    rwahs migrate -e <env> [-C]

This task does not accept a `--component`/`-c` parameter, because it implicitly relates to running the import scripts.

If the `--clean`/`-C` parameter is specified, it is the equivalent of running the `clean` task followed by the 
`migrate` task.
