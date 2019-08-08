
export PATH="../bin:$PATH"
export GH_ENV=bats

function setup_apptokit_env {
  [ -f "./.apptokit.yml" ] && rm .apptokit.yml
  eval "echo \"$(cat test/env.yml)\"" > ./.apptokit.yml

  [ -f "./bats_private_key.pem" ] && rm "./bats_private_key.pem"
  echo "$BATS_PRIVATE_KEY" > ./bats_private_key.pem
}
