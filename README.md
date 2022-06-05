# Test Collector Buildkite Plugin (WIP)

A Buildkite plugin for uploading [JSON](https://buildkite.com/docs/test-analytics/importing-json) or [JUnit](https://buildkite.com/docs/test-analytics/importing-junit-xml) files to [Buildkite Test Analytics](https://buildkite.com/test-analytics) ✨

## 👉 Usage

### Upload a JUnit file

To upload a JSON file to Test Analytics from a build step:

```yaml
steps:
  - label: "🔨 Test"
    command: "make test"
    plugins:
      - buildkite/test-collector#v0.0.1:
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
      - buildkite/test-collector#v0.0.1:
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

* `files` — String — Required — A file path pattern of files to upload to Test Analytics
* `format` — String — Required — Possible values: `"junit"`, `"json"`
* `artifact` — Boolean — Optional — Search for the files as build artifacts. Default value: `false`
* `api-token-env-name` — String — Optional — The name of the environment variable that contains the Buildkite Test Analytics API Token. Default value: `"BUILDKITE_ANALYTICS_API_TOKEN"`

## ⚒ Developing

You can use the [bk cli](https://github.com/buildkite/cli) to run the test pipeline locally, or just the tests using Docker Compose directly:

```bash
docker-compose run --rm tests
```

## 👩‍💻 Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/buildkite-plugins/test-collector-buildkite-plugin

## 📜 License

The package is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
