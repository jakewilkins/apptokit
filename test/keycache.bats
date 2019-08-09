#!/usr/bin/env bats

load test_helper

KEYCACHE="$HOME/.config/apptokit/.apptokit_bats_keycache"

function setup {
  [ ! -d ~/.config/apptokit ] && mkdir -p ~/.config/apptokit
  cp ./test/keycache.db "$KEYCACHE"
}

function teardown {
  if [[ -f "$KEYCACHE" ]]; then
    rm $KEYCACHE
  fi
}

@test "show lists values in keycache" {
  run $APPTOKIT keycache show

  [ "$status" -eq 0 ]
  [[ "$output" == *"'bats'"* ]]
  [[ "$output" == *"user:1410449"* ]]
  [[ "$output" == *"installation:1410449"* ]]
}

@test "drop removes 'all' keys" {
  run $APPTOKIT keycache drop all

  [ "$status" -eq 0 ]
  [ "$output" = "Clearing all keys for env 'bats'... done." ]

  run $APPTOKIT keycache show
  [ "$output" = "Apptokit cache is empty for env 'bats'" ]
}

@test "drop removes a single type of keys:user" {
  run $APPTOKIT keycache drop user

  result="Clearing key type 'user' for env 'bats'... done.
deleted keys:
 - user:1410449:"

  [ "$status" -eq 0 ]
  [ "$output" = "$result" ]

  run $APPTOKIT keycache show
  [[ "$output" == *"'bats'"* ]]
  [[ "$output" != *"user:1410449"* ]]
  [[ "$output" == *"installation:1410449"* ]]
}

@test "drop removes a single type of keys:installation" {
  run $APPTOKIT keycache drop installation

  result="Clearing key type 'installation' for env 'bats'... done.
deleted keys:
 - installation:1410449"

  [ "$status" -eq 0 ]
  [ "$output" = "$result" ]

  run $APPTOKIT keycache show
  [[ "$output" == *"'bats'"* ]]
  [[ "$output" == *"user:1410449"* ]]
  [[ "$output" != *"installation:1410449"* ]]
}
# vim set: ft=bash
