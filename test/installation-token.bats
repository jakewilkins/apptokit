#!/usr/bin/env bats

load test_helper

function teardown {
  if [[ -f "$KEYCACHE" ]]; then
    rm $KEYCACHE
  fi
}

@test "fetches an installation token" {
  setup_apptokit_env

  run $APPTOKIT installation-token

  if [ ! "$status" -eq 0 ]; then
    echo "$output" >&2
  fi
  [ "$status" -eq 0 ]
  [[ "$output" == "token ghs_"* ]]
}

@test "uses cached result if available" {
  setup_apptokit_env

  run $APPTOKIT installation-token

  first_token="$output"

  if [ ! "$status" -eq 0 ]; then
    echo "$output" >&2
  fi
  [ "$status" -eq 0 ]
  [[ "$output" == "token ghs_"* ]]

  run $APPTOKIT installation-token

  if [ ! "$status" -eq 0 ]; then
    echo "$output" >&2
  fi
  [ "$status" -eq 0 ]
  [[ "$output" == "token ghs_"* ]]
  [ "$first_token" = "$output" ]
}

@test "ignores cached result if available and --force option is supplied" {
  setup_apptokit_env

  run $APPTOKIT installation-token

  first_token="$output"

  if [ ! "$status" -eq 0 ]; then
    echo "$output" >&2
  fi
  [ "$status" -eq 0 ]
  [[ "$output" == "token ghs_"* ]]

  run $APPTOKIT installation-token --force

  if [ ! "$status" -eq 0 ]; then
    echo "$output" >&2
  fi
  [ "$status" -eq 0 ]
  [[ "$output" == "token ghs_"* ]]
  [ "$first_token" != "$output" ]
}

# vim: set ft=bash
