#!/usr/bin/env bats

# To debug stubs, uncomment these lines:
# export CURL_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

CURL_DEFAULT_STUB='\* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \*'

setup() {
  load "$BATS_PLUGIN_PATH/load.bash"
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_API_TOKEN_ENV_NAME=""

  # Mandatory Config
  export BUILDKITE_ANALYTICS_TOKEN='a-secret-analytics-token'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-1.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FORMAT='junit'
  # Build env
  export BUILDKITE_BUILD_ID="an-id"
  export BUILDKITE_BUILD_URL="https://url.com/"
  export BUILDKITE_BRANCH="a-branch"
  export BUILDKITE_COMMIT="a-commit"
  export BUILDKITE_BUILD_NUMBER="123"
  export BUILDKITE_JOB_ID="321"
  export BUILDKITE_MESSAGE="A message"
}

@test "exclude specific matches string" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_EXCLUDE_BRANCHES='an'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Branch a-branch matches exclude selector"
  assert_output --partial "Skipping it."
}

@test "exclude matches string exactly" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_EXCLUDE_BRANCHES='a-branch'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Branch a-branch matches exclude selector"
  assert_output --partial "Skipping it."
}

@test "exclude does not match" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_EXCLUDE_BRANCHES='x'

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "${CURL_DEFAULT_STUB} : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  refute_output --partial "Branch a-branch matches exclude selector"
  refute_output --partial "Skipping it."

  unstub curl
  unstub git
}

@test "exclude matches prefix" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_EXCLUDE_BRANCHES='^a-br'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Branch a-branch matches exclude selector"
  assert_output --partial "Skipping it."
}

@test "exclude matches suffix" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_EXCLUDE_BRANCHES='anch$'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Branch a-branch matches exclude selector"
  assert_output --partial "Skipping it."
}

@test "exclude match regex" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_EXCLUDE_BRANCHES='^.*-b[ra]*n.*'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Branch a-branch matches exclude selector"
  assert_output --partial "Skipping it."
}

@test "exclude does not match regex" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_EXCLUDE_BRANCHES='^.*-b[er]*n.*'

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "${CURL_DEFAULT_STUB} : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  refute_output --partial "Branch a-branch matches exclude selector"
  refute_output --partial "Skipping it."
}