
export PATH="../bin:$PATH"
export GH_ENV=bats
export APPTOKIT="./bin/apptokit"

export KEYCACHE="$HOME/.config/apptokit/.apptokit_bats_keycache"

function setup_apptokit_env {
  ./test/setup.sh
}

