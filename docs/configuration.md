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

```bash
http://localhost:8075/callback
```

To configure this view the help docs for `user-token` by `apptokit help user-token`.


Those docs also explain how to split the process into separate commands if you're
unable to change the authorize callback URL for the GitHub App you're configuring.

### Changing environments

`apptokit` uses either `APPTOKIT_ENV` or `GH_ENV` to pick which GitHub App environment to use.
The two are equivalent in function, I just got tired of typing out APPTOKIT_ENV.

If you setup project specific YAML files you can specify a default env via a
`default_env` key.

