#!/usr/bin/env bats

# To debug stubs, uncomment these lines:
#export CURL_STUB_DEBUG=/dev/tty
#export GIT_STUB_DEBUG=/dev/tty

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
  export BUILDKITE_LABEL="A test step"
  export BUILDKITE_JOB_ID="321"
  export BUILDKITE_MESSAGE="A message"
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_ANNOTATION_LINK="true"
  export CURL_RESP_FILE="./tests/fixtures/response.json"
}

COMMON_CURL_OPTIONS='--form \* --form \* --form \* --form \* --form \* --form \* --form \* --form \* --form \* --form \*'

@test "Annotates report link with jq" {
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"
  stub buildkite-agent "annotate --style info --context \"test-collector\" --append : echo 'annotation success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "Using jq"
  assert_output --partial "annotation success"

  unstub buildkite-agent
  unstub curl
}

@test "Annotates report link without jq" {
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"
  stub buildkite-agent "annotate --style info --context \"test-collector\" --append : echo 'annotation success'"
  stub which "jq : exit 1"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "jq not installed, attempting to parse with sed"
  assert_output --partial "annotation success"

  unstub which
  unstub buildkite-agent
  unstub curl
}

@test "Annotates report link from multiple file and same report URLs" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 1'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 2'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 3'"
  stub buildkite-agent "annotate --style info --context \"test-collector\" --append : echo 'annotation success'"


  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_output --partial "curl success 1"
  assert_output --partial "curl success 2"
  assert_output --partial "curl success 3"
  assert_output --partial "Got 1 report URLs."
  assert_output --partial "annotation success"

  unstub buildkite-agent
  unstub curl
}

@test "Annotates report link from multiple file and different report URLs" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 1'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 2'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success 3'"
  stub jq \
    "-r '.run_url' \* : echo https://buildkite.com/organizations/example/analytics/suites/collector-test/runs/1" \
    "-r '.run_url' \* : echo https://buildkite.com/organizations/example/analytics/suites/collector-test/runs/2" \
    "-r '.run_url' \* : echo https://buildkite.com/organizations/example/analytics/suites/collector-test/runs/1"
  stub buildkite-agent "annotate --style info --context \"test-collector\" --append : echo 'annotation success' with stdin:; cat"


  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-3.xml'..."
  assert_output --partial "curl success 1"
  assert_output --partial "curl success 2"
  assert_output --partial "curl success 3"
  assert_output --partial "Got 2 report URLs."
  assert_output --partial "- [Report #1](https://buildkite.com/organizations/example/analytics/suites/collector-test/runs/1)"
  assert_output --partial "- [Report #2](https://buildkite.com/organizations/example/analytics/suites/collector-test/runs/2)"
  refute_output --partial "- [Report #3]"

  unstub buildkite-agent
  unstub jq
  unstub curl
}

@test "Annotates report link absorbs empty file error" {
  export CURL_RESP_FILE="response.json"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"
  stub buildkite-agent "annotate --style info --context \"test-collector\" --append : echo 'annotation success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "Could not get the tests report URL from response.json. File not found."

  unstub curl
}

@test "No annotation when url property on json response is missing" {
  export CURL_RESP_FILE="./tests/fixtures/response_no_url.json"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "jq parsing failed with the message: "
  assert_output --partial "Contents of ./tests/fixtures/response_no_url.json:"
  assert_output --partial "There are no report URLs to annotate"

  unstub curl
}

@test "No annotation when 'run_url' property is missing in JSON response" {
  export CURL_RESP_FILE="./tests/fixtures/response_missing_url.json"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "jq parsing failed with the message:"
  assert_output --partial "Contents of ./tests/fixtures/response_missing_url.json:"
  assert_output --partial "There are no report URLs to annotate"

  unstub curl
}

@test "No annotation when 'run_url' is null in JSON response" {
  export CURL_RESP_FILE="./tests/fixtures/response_null_url.json"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "jq parsing failed with the message: null"
  assert_output --partial "Contents of ./tests/fixtures/response_null_url.json:"
  assert_output --partial "There are no report URLs to annotate"

  unstub curl
}

@test "Fallback to sed when jq is missing" {
  stub which "jq : exit 1"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* \* \* -H \* : echo 'curl success'"
  stub buildkite-agent "annotate --style info --context \"test-collector\" --append : echo 'annotation success'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "jq not installed, attempting to parse with sed"
  assert_output --partial "curl success"
  assert_output --partial "annotation success"

  unstub which
  unstub curl
}

