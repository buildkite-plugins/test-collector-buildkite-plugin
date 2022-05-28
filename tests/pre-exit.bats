#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

# setup() {
# }

@test "Run with BUILDKITE_COMMAND" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES="moo-*.xml"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Hello world"
}
