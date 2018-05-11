## Apptokit

Tools for GitHub App developers.

```bash
$ apptokit help
Usage: apptokit <command> [<args>]

Some useful apptokit commands are:
   fingerprint         Fingerprint the currently selected GitHub App private key.
   app-token           Generate a JWT for your GitHub App
   user-token          Generate an User-Server token for a GitHub App installation.
   installation-token  Generate an installation token for a GitHub App installation.
   curl                Perform a curl command authenticated as a GitHub App.
   commands            List all apptokit commands

See 'apptokit help <command>' for information on a specific command.
```

### Installation

Currently don't have a great story for this. This is build off of [basecamp/sub](https://github.com/basecamp/sub),
and it seems like the installation instructions are:

1. Clone this repo
2. Either put `bin` in your path or
3. Add the output of `apptokit init` to your shell config.

I'm not super happy with that process, but I wanted something slightly less Ruby centric than
a Ruby gem. While this does use Ruby, it's only non-standarb-library dependency is 
vendored in `share/` and all Ruby code runs under the Ruby version that ships with MacOS.

Options set from .apptokit.yaml, with a default loaded from ~/config/apptokit.yaml,
checkout apptokit.yaml.example for options.


### Examples

If you want to create an installation token (and you don't want to use `apptokit installation-token`)

```bash
$ apptokit curl app post installations/15/access_tokens
{
  "token": "v1.3f4e02159dd89notatokencb50f3a455b35e1",
  "expires_at": "2018-05-12T00:20:40Z"
}

```
