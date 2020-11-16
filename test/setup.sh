
export TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export TMP_DIR="$(dirname "$TEST_DIR")/tmp"
export HOME="$TMP_DIR/bats"

mkdir -p $HOME

mkdir -p ~/.config/apptokit

[ -f "./.apptokit.yml" ] && rm .apptokit.yml
eval "echo \"$(cat test/env.yml)\"" > ./.apptokit.yml

[ -f "./bats_private_key.pem" ] && rm "./bats_private_key.pem"
echo "$BATS_PRIVATE_KEY" > ./bats_private_key.pem
