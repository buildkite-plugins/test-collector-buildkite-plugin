#!/usr/bin/env bats

setup() {
  load "$BATS_PLUGIN_PATH/load.bash"
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_API_TOKEN_ENV_NAME=""
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
  assert_output --partial "Missing file format 'format'. Possible values: 'junit', 'xml'"
}

@test "Errors if no file is found" {
  export BUILDKITE_ANALYTICS_TOKEN='abc'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='file.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FORMAT='junit'
  run "$PWD/hooks/pre-exit"

  assert_failure
  assert_output --partial "No files found matching 'file.xml'"
}

@test "Uploads a file" {
  # Config
  export BUILDKITE_ANALYTICS_TOKEN='abc'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-1.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FORMAT='junit'
  # Expected build env vars
  export BUILDKITE_BUILD_ID="an-id"
  export BUILDKITE_BUILD_URL="https://url.com/"
  export BUILDKITE_BRANCH="a-branch"
  export BUILDKITE_COMMIT="a-commit"
  export BUILDKITE_BUILD_NUMBER="123"
  export BUILDKITE_JOB_ID="321"
  export BUILDKITE_MESSAGE="A message"

  # TODO: stub curl

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  refute_output --partial '"message"' # JSON error message
}

@test "Uploads multiple file" {
  # Config
  export BUILDKITE_ANALYTICS_TOKEN='abc'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FORMAT='junit'
  # Expected build env vars
  export BUILDKITE_BUILD_ID="an-id"
  export BUILDKITE_BUILD_URL="https://url.com/"
  export BUILDKITE_BRANCH="a-branch"
  export BUILDKITE_COMMIT="a-commit"
  export BUILDKITE_BUILD_NUMBER="123"
  export BUILDKITE_JOB_ID="321"
  export BUILDKITE_MESSAGE="A message"

  # TODO: stub curl

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  refute_output --partial '"message"' # JSON error message
}

# TODO: Test debug
# TODO: Test timeout
# TODO: Test plugin version w/ and w/o git available