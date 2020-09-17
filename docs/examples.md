
### Examples

If you want to create an installation token (and you don't want to use `apptokit installation-token`)

```bash
$ apptokit curl app post app/installations/15/access_tokens
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

[create-issue-docs]: https://developer.github.com/v3/issues/comments/#create-a-comment
[list-repos]: https://developer.github.com/v3/apps/installations/#list-repositories-accessible-to-the-user-for-an-installation
