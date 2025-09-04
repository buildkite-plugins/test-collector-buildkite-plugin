#!/usr/bin/env bats

# To debug stubs, uncomment these lines:
# export CURL_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

setup() {
  load "$BATS_PLUGIN_PATH/load.bash"

  # run --separate-stderr requires bats 1.5.0 and produces a warning without this declaration
  bats_require_minimum_version 1.5.0

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

@test "Without triggered_from data produces empty string" {
  run --separate-stderr infer_triggered_from_build_url

  assert_success
  output=$stdout assert_output ""
  output=$stderr assert_output "warning: missing details to infer triggerer-from URL"
}
