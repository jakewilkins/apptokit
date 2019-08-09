
export PATH="../bin:$PATH"
export GH_ENV=bats
export APPTOKIT="./bin/apptokit"

function setup_apptokit_env {
  ./test/setup.sh
}

