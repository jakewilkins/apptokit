## Apptokit

Tools for GitHub App developers.

```bash
$ apptokit help
Usage: apptokit <command> [<args>]

Some useful apptokit commands are:
   env                 Provide information about the currently configured GitHub App
   fingerprint         Fingerprint the currently selected GitHub App private key.
   app-token           Generate a JWT for your GitHub App
   user-token          Generate an User-Server token for a GitHub App installation.
   installation-token  Generate an installation token for a GitHub App installation.
   curl                Perform a curl command authenticated as a GitHub App.
   keycache            Work with the keycache for this Apptokit ENV
   commands            List all apptokit commands

See 'apptokit help <command>' for information on a specific command.
```

## Getting Started

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

### Configuration

Setting up a new environment happens with:

```bash
apptokit init --global --env development
```

This will add new keys to `~/.config/apptokit.yml` for a development environment where
you can specify:

* `private_key_path_glob`: A path pattern to use to look for the `.pem` file to use.
* `app_id`: The GitHub App ID. Found on the settings page.
* `installation_id`: An installation ID to use for generation installation tokens.
* `client_id`: The Client ID for the GitHub App. Found on the settings page.
* `client_secret`: The OAuth client secret for the GitHub App. Found on the settings page.

To use `apptokit` for User-to-Server, you have to configure the User authorization
callback URL to

```
http://localhost:8075/callback
```

To configure this view the help docs for `user-token` by `apptokit help user-token`.


Those docs also explain how to split the process into separate commands if you're
unable to change the authorize callback URL for the GitHub App you're configuring.

### Changing environments

`apptokit` uses the ENV variables `APPTOKIT_ENV` & `GH_ENV` to pick the environment.

If you setup project specific YAML files you can specify a default env via a
`default_env` key.

### Examples

If you want to create an installation token (and you don't want to use `apptokit installation-token`)

```bash
$ apptokit curl app post installations/15/access_tokens
{
  "token": "v1.3f4e02159dd89notatokencb50f3a455b35e1",
  "expires_at": "2018-05-12T00:20:40Z"
}

```

Performing a User-Server request like [List repositories accessible to the user for an installation][list-repos]

NOTE: this will open your browser unless there is an existing user token in the key cache.

```bash
$ apptokit curl user user/installations/15/repositories | jq
{
	"total_count": 1,
		"repositories": [
		{
			"id": 534,
			"name": "fictional-octo-funicular",
			"full_name": "jakewilkins/fictional-octo-funicular",
      ... snip
		}
	]
}
```

Or [creating an Issue Comment][create-issue-docs] as an app and a user, just switching one flag:

```bash
$ cat issue_comment.json
{"body": "Here's your comment!"}

$ apptokit curl installation post repos/jakewilkins/fictional-octo-funicular/issues/16/comments -d @issue_comment.json
{
  "url": "http://api.github.com/repos/jakewilkins/fictional-octo-funicular/issues/comments/10566",
  "html_url": "http://github.com/jakewilkins/fictional-octo-funicular/issues/16#issuecomment-10566",
  "issue_url": "http://api.github.com/repos/jakewilkins/fictional-octo-funicular/issues/16",
  "id": 10566,
  "user": {
    "login": "test-app[bot]",
    "id": 5355,
    "avatar_url": "http://alambic.github.com/avatars/u/980?",
    "gravatar_id": "",
    "url": "http://api.github.com/users/test-app%5Bbot%5D",
    "type": "Bot",
    "site_admin": false
  },
  "created_at": "2018-05-11T23:43:16Z",
  "updated_at": "2018-05-11T23:43:16Z",
  "author_association": "NONE",
  "body": "Here's your comment!",
  "performed_via_github_app": null
}


### Swapping out to creating as a User

$ apptokit curl user post repos/jakewilkins/fictional-octo-funicular/issues/16/comments -d @issue_comment.json
{
  "url": "http://api.github.com/repos/jakewilkins/fictional-octo-funicular/issues/comments/10567",
  "html_url": "http://github.com/jakewilkins/fictional-octo-funicular/issues/16#issuecomment-10567",
  "issue_url": "http://api.github.com/repos/jakewilkins/fictional-octo-funicular/issues/16",
  "id": 10567,
  "user": {
    "login": "jakewilkins",
    "id": 980,
    "gravatar_id": "",
    "type": "User",
  },
  "created_at": "2018-05-11T23:43:34Z",
  "updated_at": "2018-05-11T23:43:34Z",
  "author_association": "OWNER",
  "body": "Here's your comment!",
  "performed_via_github_app": {
    "name": "test app",
    "description": "",
    "external_url": "http://example.com",
    "created_at": "2018-05-01T10:21:55.000-07:00",
    "updated_at": "2018-05-11T15:38:08.000-07:00"
  }
}

```


[install-script-html]: https://github.com/jakewilkins/apptokit/blob/master/install.sh
[create-issue-docs]: https://developer.github.com/v3/issues/comments/#create-a-comment
[list-repos]: https://developer.github.com/v3/apps/installations/#list-repositories-accessible-to-the-user-for-an-installation
