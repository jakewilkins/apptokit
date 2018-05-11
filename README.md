## Apptokit

Tools for GitHub App developers.


Options in set from .apptokit.yml


```bash
apptokit fingerprint # verify the fingerprint of the key you're using
apptokit jwt         # generates a JWT for your app
apptokit token       # generates an installation token for your App & installation
apptokit user-token  # TBA: generates an user token for your App, installation, & user
```


## Curl usage

`jwt` & `token` will play nice when used with `curl`, you can:

```bash

# As an app
curl -H "Authorization: `apptokit jwt`" https://api.github.com/installations

# As an installation
curl -H "Authorization: `apptokit token`" https://api.github.com/installation/repositories
```
