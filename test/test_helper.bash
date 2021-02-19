
export TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TMP_DIR="$(dirname "$TEST_DIR")/tmp"
export HOME="$TMP_DIR/bats"

mkdir -p $HOME

export PATH="./bin:$PATH"
export GH_ENV=bats
export APPTOKIT="./bin/apptokit"

export KEYCACHE="$HOME/.config/apptokit/.apptokit_bats_keycache"

function setup_apptokit_env {
  ./test/setup.sh
}

