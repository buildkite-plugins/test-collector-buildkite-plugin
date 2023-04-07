#!/usr/bin/env bats

# To debug stubs, uncomment these lines:
# export CURL_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

CURL_DEFAULT_STUB='\* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \* \*'

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

@test "branches string specific, do nothing" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_BRANCHES='no-branch'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Branch a-branch does not match selector"
  assert_output --partial "Skipping it."
}

@test "branches does not match, do nothing" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_BRANCHES='no-.*'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Branch a-branch does not match selector"
  assert_output --partial "Skipping it."
}

@test "branches match exactly" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_BRANCHES='a-branch'

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "${CURL_DEFAULT_STUB} : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  refute_output --partial "Branch a-branch does not match selector"
  refute_output --partial "Skipping it."

  unstub curl
  unstub git
}

@test "branches match prefix" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_BRANCHES='^a-br'

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "${CURL_DEFAULT_STUB} : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  refute_output --partial "Branch a-branch does not match selector"
  refute_output --partial "Skipping it."

  unstub curl
  unstub git
}

@test "branches match suffix" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_BRANCHES='anch$'

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "${CURL_DEFAULT_STUB} : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  refute_output --partial "Branch a-branch does not match selector"
  refute_output --partial "Skipping it."

  unstub curl
  unstub git
}

@test "branches match regex" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_BRANCHES='^.*-b[ra]*n.*'

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "${CURL_DEFAULT_STUB} : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  refute_output --partial "Branch a-branch does not match selector"
  refute_output --partial "Skipping it."

  unstub curl
  unstub git
}

@test "branches does not match regex, do nothing" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_BRANCHES='^.*-b[er]*n.*'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Branch a-branch does not match selector"
  assert_output --partial "Skipping it."
}