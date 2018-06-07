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

Options set from .apptokit.yml, with a default loaded from ~/config/apptokit.yml,
checkout apptokit.yml.example for options.


### Examples

If you want to create an installation token (and you don't want to use `apptokit installation-token`)

```bash
$ apptokit curl app post installations/15/access_tokens
{
  "token": "v1.3f4e02159dd89notatokencb50f3a455b35e1",
  "expires_at": "2018-05-12T00:20:40Z"
}

```

Performing a User-Server request like [List repositories accessible to the user for an installation](https://developer.github.com/v3/apps/installations/#list-repositories-accessible-to-the-user-for-an-installation)

NOTE: this will open your browser. There's a TODO here for caching User-Server tokens
and then trying to regenerate if it fails.

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

Or [creating an Issue Comment](https://developer.github.com/v3/issues/comments/#create-a-comment) as an app and a user, just switching one flag:

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
