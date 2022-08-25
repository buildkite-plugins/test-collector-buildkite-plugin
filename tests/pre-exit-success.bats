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

@test "Uploads a file" {
  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit --form data=\"@./tests/fixtures/junit-1.xml\" --form run_env[CI]=buildkite --form run_env[key]=an-id --form run_env[url]=https://url.com/ --form run_env[branch]=a-branch --form run_env[commit_sha]=a-commit --form run_env[number]=123 --form run_env[job_id]=321 --form run_env[message]=\"A message\" --form run_env[collector]=test-collector-buildkite-plugin --form run_env[version]=some-commit-id https://analytics-api.buildkite.com/v1/uploads -H 'Authorization: Token token=\"a-secret-analytics-token\"' : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub git

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "curl success"
}

@test "Uploads multiple file" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_FILES='**/*/junit-*.xml'

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl \
    "-X POST --silent --show-error --max-time 30 --form format=junit --form data=\"@./tests/fixtures/junit-1.xml\" --form run_env[CI]=buildkite --form run_env[key]=an-id --form run_env[url]=https://url.com/ --form run_env[branch]=a-branch --form run_env[commit_sha]=a-commit --form run_env[number]=123 --form run_env[job_id]=321 --form run_env[message]=\"A message\" --form run_env[collector]=test-collector-buildkite-plugin --form run_env[version]=some-commit-id https://analytics-api.buildkite.com/v1/uploads -H 'Authorization: Token token=\"a-secret-analytics-token\"' : echo 'curl success 1'" \
    "-X POST --silent --show-error --max-time 30 --form format=junit --form data=\"@./tests/fixtures/junit-2.xml\" --form run_env[CI]=buildkite --form run_env[key]=an-id --form run_env[url]=https://url.com/ --form run_env[branch]=a-branch --form run_env[commit_sha]=a-commit --form run_env[number]=123 --form run_env[job_id]=321 --form run_env[message]=\"A message\" --form run_env[collector]=test-collector-buildkite-plugin --form run_env[version]=some-commit-id https://analytics-api.buildkite.com/v1/uploads -H 'Authorization: Token token=\"a-secret-analytics-token\"' : echo 'curl success 2'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub git

  assert_success
  assert_output --partial "Uploading './tests/fixtures/junit-1.xml'..."
  assert_output --partial "Uploading './tests/fixtures/junit-2.xml'..."
  assert_output --partial "curl success 1"
  assert_output --partial "curl success 2"
}

@test "Debug true prints the curl info w/o token" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_DEBUG="true"

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit --form data=\"@./tests/fixtures/junit-1.xml\" --form run_env[CI]=buildkite --form run_env[key]=an-id --form run_env[url]=https://url.com/ --form run_env[branch]=a-branch --form run_env[commit_sha]=a-commit --form run_env[number]=123 --form run_env[job_id]=321 --form run_env[message]=\"A message\" --form run_env[collector]=test-collector-buildkite-plugin --form run_env[debug]=true --form run_env[version]=some-commit-id https://analytics-api.buildkite.com/v1/uploads -H 'Authorization: Token token=\"a-secret-analytics-token\"' : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub git

  assert_success
  assert_output --partial "curl -X POST"
  refute_output --partial "a-secret-analytics-token"
}

@test "Debug env var true prints the curl info w/o token" {
  export BUILDKITE_ANALYTICS_DEBUG_ENABLED="true"

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit --form data=\"@./tests/fixtures/junit-1.xml\" --form run_env[CI]=buildkite --form run_env[key]=an-id --form run_env[url]=https://url.com/ --form run_env[branch]=a-branch --form run_env[commit_sha]=a-commit --form run_env[number]=123 --form run_env[job_id]=321 --form run_env[message]=\"A message\" --form run_env[collector]=test-collector-buildkite-plugin --form run_env[debug]=true --form run_env[version]=some-commit-id https://analytics-api.buildkite.com/v1/uploads -H 'Authorization: Token token=\"a-secret-analytics-token\"' : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub git

  assert_success
  assert_output --partial "curl -X POST"
  refute_output --partial "a-secret-analytics-token"
}

@test "Debug false does not print the curl info" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_DEBUG="false"

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit --form data=\"@./tests/fixtures/junit-1.xml\" --form run_env[CI]=buildkite --form run_env[key]=an-id --form run_env[url]=https://url.com/ --form run_env[branch]=a-branch --form run_env[commit_sha]=a-commit --form run_env[number]=123 --form run_env[job_id]=321 --form run_env[message]=\"A message\" --form run_env[collector]=test-collector-buildkite-plugin --form run_env[version]=some-commit-id https://analytics-api.buildkite.com/v1/uploads -H 'Authorization: Token token=\"a-secret-analytics-token\"' : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub git

  assert_success
  refute_output --partial "curl -X POST"
}

@test "Timeout is configurable" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_TIMEOUT='999'

  stub git "rev-parse --short HEAD : echo 'some-commit-id'"
  stub curl "-X POST --silent --show-error --max-time 999 --form format=junit --form data=\"@./tests/fixtures/junit-1.xml\" --form run_env[CI]=buildkite --form run_env[key]=an-id --form run_env[url]=https://url.com/ --form run_env[branch]=a-branch --form run_env[commit_sha]=a-commit --form run_env[number]=123 --form run_env[job_id]=321 --form run_env[message]=\"A message\" --form run_env[collector]=test-collector-buildkite-plugin --form run_env[version]=some-commit-id https://analytics-api.buildkite.com/v1/uploads -H 'Authorization: Token token=\"a-secret-analytics-token\"' : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub git

  assert_success
  assert_output --partial "curl success"
}

@test "Git unavailable sends no plugin version" {
  stub git "rev-parse --short HEAD : echo 'git error' >&2; exit 1"
  stub curl "-X POST --silent --show-error --max-time 30 --form format=junit --form data=\"@./tests/fixtures/junit-1.xml\" --form run_env[CI]=buildkite --form run_env[key]=an-id --form run_env[url]=https://url.com/ --form run_env[branch]=a-branch --form run_env[commit_sha]=a-commit --form run_env[number]=123 --form run_env[job_id]=321 --form run_env[message]=\"A message\" --form run_env[collector]=test-collector-buildkite-plugin https://analytics-api.buildkite.com/v1/uploads -H 'Authorization: Token token=\"a-secret-analytics-token\"' : echo 'curl success'"

  run "$PWD/hooks/pre-exit"

  unstub curl
  unstub git

  assert_success
  assert_output --partial "curl success"
}

@test "skip is configurable" {
  export BUILDKITE_PLUGIN_TEST_COLLECTOR_SKIP='true'

  run "$PWD/hooks/pre-exit"

  assert_success
  assert_output "Skipping upload since 'skip' set to true"
}
