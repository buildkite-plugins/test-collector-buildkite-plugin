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

@test "Uploads a file" {
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
}

@test "Uploads multiple file" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success 1'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success 2'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success 3'"

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-3.xml'..."
  assert_output --partial "curl success 1"
  assert_output --partial "curl success 2"
  assert_output --partial "curl success 3"
}

@test "Uploads multiple files concurrently does not break basic functionality" {
   # would love to test functionality but can not do so due to limitations on bats-mock :(
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_UPLOAD_CONCURRENCY='3'

  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo \"curl success \${10}\""

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-3.xml'..."
  assert_equal "$(echo "$output" | grep -c "curl success")" "3"
}

@test "Concurrency waits when the queue is full" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_UPLOAD_CONCURRENCY='2'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_DEBUG='true'

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} --form \* \* -H \* : sleep 3; echo \"curl success \${10}\"" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} --form \* \* -H \* : echo \"curl success \${10}\""

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_output --partial "Waiting for uploads to finish..."
  assert_output --partial "Uploading './tests/fixtures/junit-3.xml'..."
  assert_equal "$(echo "$output" | grep -c "curl success")" "3"
}

@test "Single file pattern through array" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES_0='**/*/junit-1.xml'
  unset BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success 1'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  refute_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_output --partial "curl success 1"

  unstub curl
}

@test "Multiple file pattern through array" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES_0="*/fixtures/*-1.xml"
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES_1="*/fixtures/*-2.xml"
  unset BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success 1'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success 2'"

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_output --partial "curl success 1"
  assert_output --partial "curl success 2"

  unstub curl
}

@test "Debug true prints the curl info w/o token" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_DEBUG="true"

  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} --form \* \* -H \* : echo \"curl success with \${30}\""

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "curl success"
  assert_output --partial "curl -X POST"
  refute_output --partial "a-secret-analytics-token"
}

@test "Debug env var true prints the curl info w/o token" {
  export BUILDKITE_ANALYTICS_DEBUG_ENABLED="true"

  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} --form \* \* -H \* : echo \"curl success with  with \${30}\""

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "curl -X POST"
  refute_output --partial "a-secret-analytics-token"
}

@test "Debug false does not print the curl info" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_DEBUG="false"

  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  refute_output --partial "curl -X POST"
}

@test "Timeout is configurable" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_TIMEOUT='999'

  stub curl "-X POST --silent --show-error --max-time 999 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "curl success"
}

@test "Concurrency gracefully handles command-group timeout" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_UPLOAD_CONCURRENCY='2'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_TIMEOUT='3'

  stub curl "if [ \${10} != 'data=@\"./tests/fixtures/junit-3.xml\"' ]; then echo sleeping for \${10}; sleep 10 & wait \$!; else echo curl success \${10}; fi"

  run "$PWD/hooks/pre-exit"

  unstub curl
  
  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_equal "$(echo "$output" | grep -c "has been running for more than")" "2"
  assert_output --partial "Uploading './tests/fixtures/junit-3.xml'..."
  assert_equal "$(echo "$output" | grep -c "curl success")" "1"
}

@test "Git available sends plugin version" {
  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} --form \* \* -H \* : echo \"curl success with \${30}\""

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub git

  assert_success
  assert_output --partial "curl success"
  assert_output --partial "run_env[version]=some-commit-id"
}

@test "Follow links option enabled adds find option" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FOLLOW_SYMLINKS='true'

  stub find "-L . -path \* : echo './tests/fixtures/junit-1.xml'"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub find

  assert_success
  assert_output --partial "curl success"
}

@test "Follow links option disabled does not add find option" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FOLLOW_SYMLINKS='false'

  stub find ". -path \* : echo './tests/fixtures/junit-1.xml'"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub find

  assert_success
  assert_output --partial "curl success"
}

@test "API can change" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_API_URL='https://test-api.example.com/v2'

  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo \"curl success against \${29}\""

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
  assert_output --partial "against https://test-api.example.com/v2"

  unstub curl
}

@test "Base path can be changed" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_BASE_PATH='/test'

  stub find "/test -path /test/\*\*/\*/junit-1.xml : echo '/test/tests/fixtures/junit-1.xml'"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success'"

  run "${PWD}/hooks/pre-exit"

  unstub curl
  unstub find

  assert_success
  assert_output --partial "curl success"
}

@test "Absorb curl failures" {
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : exit 10"

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Error uploading, will continue"
}

@test "Concurrency gracefully handles failure" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_UPLOAD_CONCURRENCY='2'

  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : exit 10" \
    "-X POST --silent --show-error --max-time 30 --form format=junit ${COMMON_CURL_OPTIONS} \* -H \* : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_equal "$(echo "$output" | grep -c "Error uploading, will continue")" "2"
  assert_output --partial "Uploading './tests/fixtures/junit-3.xml'..."
  assert_equal "$(echo "$output" | grep -c "curl success")" "1"
}
