

mkdir -p ~/.config/apptokit

[ -f "./.apptokit.yml" ] && rm .apptokit.yml
eval "echo \"$(cat test/env.yml)\"" > ./.apptokit.yml

[ -f "./bats_private_key.pem" ] && rm "./bats_private_key.pem"
echo "$BATS_PRIVATE_KEY" > ./bats_private_key.pem

ruby_version_major=$(ruby --disable-gems -e "print RUBY_VERSION.split('.').tap {|a| a[2] = '0'}.join('.')")
export GEM_PATH="$(pwd)/share/ruby/vendor/ruby/$ruby_version_major"

if [ ! -d $GEM_PATH ]; then
  gem install jwt 2>&1 1>/dev/null
fi