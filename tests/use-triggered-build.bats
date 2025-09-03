#!/usr/bin/env bats

# To debug stubs, uncomment these lines:
# export CURL_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

setup() {
  load "$BATS_PLUGIN_PATH/load.bash"

  . "lib/shared.bash"

  # Build env
  export BUILDKITE_BRANCH="a-branch"
  export BUILDKITE_BUILD_ID="a-uuid"
  export BUILDKITE_BUILD_NUMBER="123"
  export BUILDKITE_BUILD_URL="https://buildkite.com/buildkite-plugins/test-collector-buildkite-plugin/builds/123"
  export BUILDKITE_COMMIT="a-commit"
  export BUILDKITE_JOB_ID="fc946849-b88b-4c67-9611-a50924a57a3c"
  export BUILDKITE_MESSAGE="A message"
  export BUILDKITE_ORGANIZATION_SLUG="buildkite-plugins"
}

@test "With triggered_from data" {
  export BUILDKITE_TRIGGERED_FROM_BUILD_ID="triggered-from-uuid"
  export BUILDKITE_TRIGGERED_FROM_BUILD_NUMBER="456"
  export BUILDKITE_TRIGGERED_FROM_BUILD_PIPELINE_SLUG="upstream"

  run infer_triggered_from_build_url

  assert_success
  assert_output "https://buildkite.com/buildkite-plugins/upstream/builds/456"
}

@test "Without triggered_from data falls back to current build URL" {
  run infer_triggered_from_build_url

  assert_success
  assert_output "https://buildkite.com/buildkite-plugins/test-collector-buildkite-plugin/builds/123"
}
