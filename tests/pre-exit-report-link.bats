#!/usr/bin/env bats

# To debug stubs, uncomment these lines:
# export CURL_STUB_DEBUG=/dev/tty
# export GIT_STUB_DEBUG=/dev/tty

setup() {
  load "$BATS_PLUGIN_PATH/load.bash"
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_API_TOKEN_ENV_NAME=""

  # Config
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

COMMON_CURL_OPTIONS='--form \* --form \* --form \* --form \* --form \* --form \* --form \* --form \* --form \* --form \*'

@test "Annotates report link with jq" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_ANNOTATE_LINK="true"
  export CURL_RESP_FILE="./tests/fixtures/response.json"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"
  stub buildkite-agent "annotate --style info --context \"test-collector\"  \* : echo 'annotation success'"
  
  run "$PWD/hooks/pre-exit"

  unstub buildkite-agent
  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "Using jq"
  assert_output --partial "annotation success"
}

@test "Annotates report link without jq" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_ANNOTATE_LINK="true"
  export CURL_RESP_FILE="./tests/fixtures/response.json"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"
  stub buildkite-agent "annotate --style info --context \"test-collector\"  \* : echo 'annotation success'"
  stub which "jq : exit 1"
  
  run "$PWD/hooks/pre-exit"

  unstub which
  unstub buildkite-agent
  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "Not using jq"
  assert_output --partial "annotation success"
}

@test "Annotates report link from multiple file and same report URLs" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_ANNOTATE_LINK="true"
  export CURL_RESP_FILE="./tests/fixtures/response.json"

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 1'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 2'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 3'"
  stub buildkite-agent "annotate --style info --context \"test-collector\"  \* : echo 'annotation success'"
  

  run "$PWD/hooks/pre-exit"

  unstub buildkite-agent
  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_output --partial "curl success 1"
  assert_output --partial "curl success 3"
  assert_output --partial "Got 1 report URLs."
  assert_output --partial "annotation success"
}

@test "Annotates report link from multiple file and different report URLs" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_ANNOTATE_LINK="true"
  export CURL_RESP_FILE="./tests/fixtures/response.json"

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 1'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 2'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 3'"
  stub jq \
    "-r '.run_url' \* : echo https://buildkite.com/organizations/example/analytics/suites/collector-test/runs/1" \
    "-r '.run_url' \* : echo https://buildkite.com/organizations/example/analytics/suites/collector-test/runs/2" \
    "-r '.run_url' \* : echo https://buildkite.com/organizations/example/analytics/suites/collector-test/runs/1"
  stub buildkite-agent "annotate --style info --context \"test-collector\"  \* : echo 'annotation success'"
  

  run "$PWD/hooks/pre-exit"

  unstub buildkite-agent
  unstub jq
  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-3.xml'..."
  assert_output --partial "curl success 1"
  assert_output --partial "curl success 3"
  assert_output --partial "Got 2 report URLs."
  assert_output --partial "annotation success"
}
@test "Annotates report link absorbs empty file error" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_ANNOTATE_LINK="true"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"
  stub buildkite-agent "annotate --style info --context \"test-collector\"  \* : echo 'annotation success'"
  
  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "Could not get the tests report URL from response.json. File not found."
}

@test "No annotation when url property on json response is missing" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_ANNOTATE_LINK="true"
  export CURL_RESP_FILE="./tests/fixtures/response_no_url.json"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"
  
  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "'run_url' property not found"
  assert_output --partial "There are no report URLs to annotate"
}
