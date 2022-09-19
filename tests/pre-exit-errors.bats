#!/usr/bin/env bats

setup() {
  load "$BATS_PLUGIN_PATH/load.bash"
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_API_TOKEN_ENV_NAME=""
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_HOOK="pre-exit"
}

@test "Errors with no token set" {
  run "$PWD/hooks/pre-exit"

  assert_failure
  assert_output --partial "Missing BUILDKITE_ANALYTICS_TOKEN environment variable"
}

@test "Errors with no token set w/ custom env name" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_API_TOKEN_ENV_NAME="CUSTOM_TOKEN_ENV_NAME"
  run "$PWD/hooks/pre-exit"

  assert_failure
  assert_output --partial "Missing CUSTOM_TOKEN_ENV_NAME environment variable"
}

@test "Errors with no 'files' set" {
  export BUILDKITE_ANALYTICS_TOKEN='abc'
  run "$PWD/hooks/pre-exit"

  assert_failure
  assert_output --partial "Missing file upload pattern 'files', e.g. 'junit-*.xml'"
}

@test "Errors with no 'format' set" {
  export BUILDKITE_ANALYTICS_TOKEN='abc'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='file.xml'
  run "$PWD/hooks/pre-exit"

  assert_failure
  assert_output --partial "Missing file format 'format'. Possible values: 'junit', 'json'"
}

@test "Errors if no file is found" {
  export BUILDKITE_ANALYTICS_TOKEN='abc'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='file.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FORMAT='junit'
  run "$PWD/hooks/pre-exit"

  assert_failure
  assert_output --partial "No files found matching 'file.xml'"
}
