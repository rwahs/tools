# RWAHS Tools

Tools to assist with integration and deployment of RWAHS software.

## Overview

The `rwahs` command handles all steps of integration and deployment via various tasks.

The general syntax is:

    rwahs <task> <options>

Where `<task>` is the name of the task to run, and `<options>` is any number of options in the form `-x <value>` (where
`x` is any single character).  See below for further details, including a table summarising the options for each task.

## Environments

The following environments are defined:

* `staging`
* `uat`
* `production`

## Components

* `tools` is this tools repository, i.e. a self-update: https://github.com/rwahs/tools
* `providence` is the CollectiveAccess management application: https://github.com/rwahs/providence
* `profile` is the CollectiveAccess installation profile (meta-schema): https://github.com/rwahs/installation-profile
* `configuration` is the CollectiveAccess local configuration: https://github.com/rwahs/providence-configuration
* `importer` is the collection of import scripts and queries: https://github.com/rwahs/import-scripts

## Tasks

### Build

Create a new release, which is a tag in the code repository.  

Syntax for the `build` task:

    rwahs build -c <component> [-t <target-commitish>] [-r <release>]

The optional `-t` parameter specifies the branch or commit that should form the basis of the tag and release.

The optional `-r` parameter specifies the name of the release, which must be unique for the given component.  If the
name already exists, an error is emitted.  If the `-r` option is omitted, the release name is generated based on the
current timestamp.

Note this task does not understand the `-e` option, because releases exist independently of environments.

This task requires an environment variable to be set outside the script and configuration, e.g. in a shell startup file
or similar, or as a prefix to the call to `rwahs`:

     RWAHS_ACCESS_TOKEN='access_token' rwahs build ...

This variable is defined externally so that it is not committed to any code repository.  If the variable is not
defined, then the command will fail with an error.  If the value is invalid, then the command will attempt to create a
release, but this will fail due to GitHub authentication.  See below for details about generating the token.

### Deploy

Transfer the specified release to the specified environment and update the environment to make the specified release
the "current" version used in the given environment.  Depending on the command line options, either a new release can
be built (by delegating to the `build` task), or an existing release (as created by a previous invocation of the
`build` task) can be used.  If no release is specified, then the default action is to determine the latest release by
querying the GitHub API.

Syntax for the `deploy` task:

    rwahs deploy [-e <environment>] -c <component> [-b | -r <release>]

Following the deployment, any required initialisation tasks are performed.  Specifically, when the "providence"
component is deployed, any pending database migrations are applied.  Additionally, caches are cleaned and services are
restarted as appropriate.  See below for instructions on allowing an unprivileged user to restart services.

### Nuke

Remove all data from the database, restoring it to a clean state following a fresh installation of the current profile
(i.e. the profile most recently deployed to the given environment).

Syntax for the `nuke` task:

    rwahs nuke [-e <environment>]

This task does not accept a `-c` parameter, because it implicitly relates to clearing the database in the given
environment.

This task does not accept any additional parameters.

### Import

Run the import scripts, converting data from the legacy database format into the format required by CollectiveAccess,
and inserting the data into the environment's database.

Syntax for the `import` task:

    rwahs import [-e <environment>] [-n]

This task does not accept a `-c` parameter, because it implicitly relates to running the import scripts.

If the `-n` parameter is specified, it is the equivalent of running the `nuke` task followed by the `import` task.

## Options Summary

The use of standard and additional parameters is summarised in the following table:

| Task     | `-e <environment>` | `-c <component>` | Additional parameters (optional)           |
|----------|--------------------|------------------|--------------------------------------------|
| `build`  |                    | Required         | `-t <target-commitish>` and `-r <release>` |
| `deploy` | Optional`*`        | Required         | either `-b` or `-r <release>`              |
| `nuke`   | Optional`*`        |                  |                                            |
| `import` | Optional`*`        |                  | `-n`                                       |

`*` If the `-e <environment>` parameter is missing, the task will operate locally.

## GitHub Access Token Generation

The `build` task requires a GitHub access token to be generated and set as the value of the `RWAHS_ACCESS_TOKEN`
environment variable.  To create a token, use the following command syntax:

    curl -u <username> --data '{"note":"<note>","scopes":["repo"],"client_id":"<client_id>","client_secret":"<client_secret>","fingerprint":"<fingerprint>"}' https://api.github.com/authorizations

Where:

* `<username>` is your GitHub username
* `<note>` is a note describing what the token is for, for example "RWAHS Deployment Script"
* `<client_id>` and `<client_secret>` are the values provided by GitHub in the Organisation's "Settings" tab under
  "Applications", for example: https://github.com/organizations/rwahs/settings/applications/304313
* `<fingerprint>` is an optional descriptor to distinguish between tokens, for example use the current date+time stamp

This command will prompt for your GitHub password.

The output of this command will include the token, for example:

````
{
    "id": 12345,
    "url": "https://api.github.com/authorizations/12345",
    "app": {
        "name": "RWAHS Deployment Script",
        "url": "http://histwest.org.au/",
        "client_id": "<client_id>"
    },
    "token": "<token>",
    "hashed_token": "<hashed_token>",
    "token_last_eight": "<token_tail>",
    "note": "RWAHS Deployment Script",
    "note_url": null,
    "created_at": "<current_date>",
    "updated_at": "<current_date>",
    "scopes": [
        "repo"
    ],
    "fingerprint": "<fingerprint>"
}
````

The `<token>` is the value you need to set to the `RWAHS_ACCESS_TOKEN` environment variable.

Note that the "repo" scope is required.  To check your assigned scopes after `RWAHS_ACCESS_TOKEN` is set and available,
use the following command:

    curl -H "Authorization: token ${RWAHS_ACCESS_TOKEN}" https://api.github.com/users/<username> -I

Where `<username>` is your GitHub username.

## Running Commands Remotely

### Concept of Operation

Some tasks accept a `-e` parameter, which specifies the environment to run in.  If no `-e` is given, the task is run
locally.  Similarly, if the `-e` value matches the `RWAHS_ENV` environment variable value, then the command is run
locally.  Otherwise, the task is run remotely based on the environment's configuration settings.

### The `RWAHS_ENV` Variable

In order to prevent loops, the correct `RWAHS_ENV` variable **must** be configured globally for at least the user being
used to run the remote commands.

When running in an environment where `RWAHS_ENV` is set, specifying `-e` is optional unless the value is different
(i.e. it is a remote call to a different environment).

### Using Identity Files

The `rwahs` script assumes that the local user can `ssh` to the remote server without specifying an identity file.  If
an identity file is required (e.g. when using AWS EC2), then it should be specified in an `ssh` configuration file, for
example `~/.ssh/config`:

    Host <host>
        IdentityFile ~/.ssh/<filename>.pem

Where `<host>` is the hostname configured in the environment configuration file, and `<filename>` is the name of the
PEM file.  The file could be anywhere, but it is standard to store it in `~/.ssh`.  Note also that the file permissions
must be restrictive, i.e. `chmod 400`, for `ssh` to use it.

## Initial Server Setup

There are some steps that need to be completed to allow remote deployment to work correctly.

### Allowing Service Restarts

To allow a regular, non-privileged user to restart services, which occurs following a `deploy` of the `providence` or
`configuration` components, the `service` command needs to be able to be run as root.

Add the following to the `/etc/sudoers` file:

    <user> ALL=(root) NOPASSWD: /usr/sbin/service

Where `<user>` is the username specified in the relevant environment's settings.

Note that, as with any provision for non-privileged users to run privileged commands, this presents a security risk.

### First Installation of `tools`

The `tools` component can deploy itself remotely, however it needs to be installed on the remote machine before this
operation will work.  Note this only applies to the `tools` component, once that is available remotely, then the other
components can be deployed directly.

To install the `tools` component in the first instance, perform the following steps:

    local$ rwahs build -c tools
    local$ ssh <user@host>
    remote$ mkdir --parents </path/to/tools>/<release-name>
    remote$ cd </path/to/tools>/<release-name>
    remote$ curl --location "https://github.com/rwahs/tools/archive/<release-name>.tar.gz" | tar --extract --gunzip --strip-components=1
    remote$ ln -s </path/to/tools>/<release-name> </path/to/tools>/current

### Setting `RWAHS_ENV`

To prevent an infinite loop, the `RWAHS_ENV` environment variable must be set to the correct value on the remote
machine, for at least the user doing the deployments.  For example, if running a task with `-e staging` then the
`staging` environment configuration is used to connect to a given `user@host`, and run the same command that was used
locally.  On the remote machine, `RWAHS_ENV` must be set to `staging` and then the script will know to run locally.

A good place to set the variable globally is in `/etc/environment`.
