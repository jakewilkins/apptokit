#!/usr/bin/env bats

load test_helper

function teardown {
  $APPTOKIT keycache drop all
}

@test "fetches an installation token" {
  setup_apptokit_env

  run $APPTOKIT installation-token

  [ "$status" -eq 0 ]
  [[ "$output" == "token v1."* ]]
}

@test "uses cached result if available" {
  setup_apptokit_env

  run $APPTOKIT installation-token

  first_token="$output"

  [ "$status" -eq 0 ]
  [[ "$output" == "token v1."* ]]

  run $APPTOKIT installation-token

  [ "$status" -eq 0 ]
  [[ "$output" == "token v1."* ]]
  [ "$first_token" = "$output" ]
}

@test "ignores cached result if available and --force option is supplied" {
  setup_apptokit_env

  run $APPTOKIT installation-token

  first_token="$output"

  [ "$status" -eq 0 ]
  [[ "$output" == "token v1."* ]]

  run $APPTOKIT installation-token --force

  [ "$status" -eq 0 ]
  [[ "$output" == "token v1."* ]]
  [ "$first_token" != "$output" ]
}

# vim: set ft=bash
