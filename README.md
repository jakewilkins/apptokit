# Apptokit

Tools for GitHub App developers.

Apptokit is a suite of tools that enable quick development and debugging of
GitHub Apps.

With Apptokit you can easily try out requests using user-to-server or server-to-server
authentication, create a GitHub App from an App Manifest, or generate tokens to be
used by other debugging software.


```bash
$ apptokit help
Usage: apptokit <command> [<args>]

Some useful apptokit commands are:
   app-token           Generate a JWT for your GitHub App
   commands            List all apptokit commands
   curl                Perform a curl command authenticated as a GitHub App.
   env                 Provide information about the currently configured GitHub App
   fingerprint         Fingerprint the currently selected GitHub App private key.
   init                Generate a .apptokit.yml or add a new App environment
   installation-token  Generate an installation token for a GitHub App installation.
   keycache            Work with the keycache for this Apptokit ENV
   manifest            Work with the cached manifest settings for this Apptokit ENV
   user-token          Generate an User-Server token for a GitHub App installation.

See 'apptokit help <command>' for information on a specific command.
```

## Installation

`apptokit` ships with an installation script, [read it over][install-script-html].

```bash
bash -c "$(curl https://raw.githubusercontent.com/jakewilkins/apptokit/main/install.sh -fsSL)" -- install
```

This will install `apptokit` into `/usr/local` and generate a comment-filled
`~/.config/apptokit.yml`.

If you're interested in `apptokit` having autocomplete follow the instructions in
the output from the install script.

Apptokit uses environments to work with multiple GitHub Apps, so you can have a
development app for testing new permissions and also a client configured for
debugging your production app.

### Quick start

Apptokit works with GitHub App Manifests and it ships with one in the example template.

Apptokit will walk you through creating the GitHub App specified in your manifest
the first time you use it.

You can try this out of the box like:

```bash
GH_ENV=manifest-app-env apptokit curl installation installation/repositories | jq
```

The first time you run this command you will be prompted to create a new GitHub
App and install it on an account. Apptokit will cache the app information and use
it for this environment.

Apptokit uses the concept of environments to allow you to work with multiple GitHub
Apps easily.

From here, check out some:

- [Configuration docs to learn about environments][configuration]
- [Example commands][examples]


[install-script-html]: https://github.com/jakewilkins/apptokit/blob/main/install.sh
[configuration]: https://github.com/jakewilkins/apptokit/blob/main/docs/configuration.md
[examples]: https://github.com/jakewilkins/apptokit/blob/main/docs/examples.md
