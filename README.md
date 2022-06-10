# Test Collector Buildkite Plugin

A Buildkite plugin for uploading [JSON](https://buildkite.com/docs/test-analytics/importing-json) or [JUnit](https://buildkite.com/docs/test-analytics/importing-junit-xml) files to [Buildkite Test Analytics](https://buildkite.com/test-analytics) ✨

## Example

### Upload a JUnit file

To upload a JSON file to Test Analytics from a build step:

```yaml
steps:
  - label: "🔨 Test"
    command: "make test"
    plugins:
      - test-collector#v1.0.0:
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
      - test-collector#v1.0.0:
          files: "test-data-*.json"
          format: "json"
```

<!-- ### Upload a build artifact

You can also upload build artifact that was generated in a previous step:

```yaml
steps:
  # Run tests and upload 
  - label: "🔨 Test"
    command: "make test --junit=tests-N.xml"
    artifact_paths: "tests-*.xml"

  - wait

  - label: "🔍 Upload tests"
    plugins:
      - buildkite/test-collector#main:
          files: "tests-*.xml"
          format: "junit"
          artifact: true
``` -->

## Properties

* `files` — Required — String — Pattern of files to upload to Test Analytics
* `format` — Required — String — Format of the file. Possible values: `"junit"`, `"json"`
* `api-token-env-name` — Optional — String — Name of the environment variable that contains the Test Analytics API token. Default value: `"BUILDKITE_ANALYTICS_TOKEN"`
* `timeout` — Optional — Number — Maximum number of seconds to wait for each file to upload before timing out. Default value: `30`
* `debug` — Optional — Boolean — Print debug information to the build output. Default value: `false`. Can also be enabled with the environment variable `BUILDKITE_ANALYTICS_DEBUG_ENABLED`.

<!-- * `artifact` — Optional — Boolean — Search for the files as build artifacts. Default value: `false` -->

## ⚒ Developing

You can use the [bk cli](https://github.com/buildkite/cli) to run the whole pipeline locally, or just the tests using Docker Compose directly:

```bash
docker-compose run --rm tests
```

## 👩‍💻 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buildkite-plugins/test-collector-buildkite-plugin

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
