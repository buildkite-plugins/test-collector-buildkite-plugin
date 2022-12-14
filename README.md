# Test Collector Buildkite Plugin [![Build status](https://badge.buildkite.com/e77fce33cffd9045543fdba23c51a6aec8e8b6161fa4c136a3.svg)](https://buildkite.com/buildkite/plugins-test-collector)

A Buildkite plugin for uploading [JSON](https://buildkite.com/docs/test-analytics/importing-json) or [JUnit](https://buildkite.com/docs/test-analytics/importing-junit-xml) files to [Buildkite Test Analytics](https://buildkite.com/test-analytics) ✨

## Options

These are all the options available to configure this plugin's behaviour.

### Required

#### `files` (string)

Pattern of files to upload to Test Analytics, relative to the checkout path (`./` will be added to it). May contain `*` to match any number of characters of any type (unlike shell expansions, it will match `/` and `.` if necessary)

#### `format` (string)

Format of the file.

Only the following values are allowed: `junit`, `json`

### Optional

#### `api-token-env-name` (string)

Name of the environment variable that contains the Test Analytics API token.

Default value: `BUILDKITE_ANALYTICS_TOKEN`

#### `debug` (boolean)

Print debug information to the build output.

Default value: `false`.

Can also be enabled with the environment variable `BUILDKITE_ANALYTICS_DEBUG_ENABLED`.

#### `timeout`(number)

Maximum number of seconds to wait for each file to upload before timing out.

Default value: `30`

## Examples

### Upload a JUnit file

To upload a JSON file to Test Analytics from a build step:

```yaml
steps:
  - label: "🔨 Test"
    command: "make test"
    plugins:
      - test-collector#v1.2.0:
          files: "test/junit-*.xml"
          format: "junit"
```

### Upload a JSON file

To upload a JSON file to Test Analytics from a build step:

```yaml
steps:
  - label: "🔨 Test"
    command: "make test"
    plugins:
      - test-collector#v1.2.0:
          files: "test-data-*.json"
          format: "json"
```

### Using build artifacts

You can also use build artifacts generated in a previous step:

```yaml
steps:
  # Run tests and upload 
  - label: "🔨 Test"
    command: "make test --junit=tests-N.xml"
    artifact_paths: "tests-*.xml"

  - wait

  - label: "🔍 Test Analytics"
    command: buildkite-agent artifact download tests-*.xml
    plugins:
      - test-collector#v1.2.0:
          files: "tests-*.xml"
          format: "junit"
```

## ⚒ Developing

You can use the [bk cli](https://github.com/buildkite/cli) to run the whole pipeline locally, or just the tests using Docker Compose directly:

```bash
docker-compose run --rm tests
```

## 👩‍💻 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buildkite-plugins/test-collector-buildkite-plugin

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
