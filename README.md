# Test Collector Buildkite Plugin [![Build status](https://badge.buildkite.com/e77fce33cffd9045543fdba23c51a6aec8e8b6161fa4c136a3.svg)](https://buildkite.com/buildkite/plugins-test-collector)

A Buildkite plugin for uploading [JSON](https://buildkite.com/docs/test-analytics/importing-json) or [JUnit](https://buildkite.com/docs/test-analytics/importing-junit-xml) files to [Buildkite Test Analytics](https://buildkite.com/test-analytics) ✨

## Options

These are all the options available to configure this plugin's behaviour.

### Required

#### `files` (string or array of strings)

One or more patterns of files to upload to Test Analytics, relative to the root of the searching path (`./` by default). May contain `*` to match any number of characters of any type (unlike shell expansions, it will match `/` and `.` if necessary). Can be either a single pattern in a string or any number of them in an array.

#### `format` (string)

Format of the file.

Only the following values are allowed: `junit`, `json`

### Optional

#### `api-token-env-name` (string)

Name of the environment variable that contains the Test Analytics API token.

Default value: `BUILDKITE_ANALYTICS_TOKEN`

#### `api-url` (string)

Full URL for the API to upload to. Defaults to `https://analytics-api.buildkite.com/v1/uploads`

#### `base-path` (string)

Where to search for files to upload. Defaults to the working directory `.`

#### `branches` (string)

String containing a regex to only do an upload in branches that match it (using the case-insensitive bash `=~` operator against the `BUILDKITE_BRANCH` environment variable).

For example:
* `prod` will match any branch name that **contains the substring** `prod`
* `^stage-` will match all branches that start with `stage-`
* `-ISSUE-[0-9]*$` will match branches that end with `ISSUE-X` (where X is any number)

Important: you may have to be careful to escape special characters like `$` during pipeline upload

#### `debug` (boolean)

Print debug information to the build output.

Default value: `false`.

Can also be enabled with the environment variable `BUILDKITE_ANALYTICS_DEBUG_ENABLED`.

#### `exclude-branches` (string)

String containing a regex avoid doing an upload in branches that match it (using the case-insensitive bash `=~` operator against the `BUILDKITE_BRANCH` environment variable ).

For example:
* `prod` will exclude any branch name that **contains the substring** `prod`
* `^stage-` will exclude all branches that start with `stage-`
* `-SECURITY-[0-9]*$` will exclude branches that end with `SECURITY-X` (where X is any number)

Important:
* you may have to be careful to escape special characters like `$` during pipeline upload
* exclusion of branches is done after the inclusion (through the [`branches` option](#branches-string))

#### `follow-symlinks` (boolean)

By default the plugin will not follow symlinked folders, set this option to `true` to do so. This will add the `-L` option to the `find` command used to get the files to upload.

#### `timeout`(number)

Maximum number of seconds to wait for each file to upload before timing out.

Default value: `30`

#### `annotation-link`(boolean)

Adds an annotation to the build run with a link to the uploaded report.

Default value: `false`

## Examples

### Upload a JUnit file

To upload a JUnit file to Test Analytics from a build step:

```yaml
steps:
  - label: "🔨 Test"
    command: "make test"
    plugins:
      - test-collector#v1.7.0:
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
      - test-collector#v1.7.0:
          files:
            - "test-data-*.json"
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
      - test-collector#v1.7.0:
          files: "tests-*.xml"
          format: "junit"
```

### Branch filtering

Only upload on the branches that end with `-qa`

```yaml
steps:
  - label: "🔨 Test"
    command: "make test"
    plugins:
      - test-collector#v1.7.0:
          files: "test-data-*.json"
          format: "json"
          branches: "-qa$"
```

Do not upload on the branch that is exactly named `legacy`:

```yaml
steps:
  - label: "🔨 Test"
    command: "make test"
    plugins:
      - test-collector#v1.7.0:
          files: "test-data-*.json"
          format: "json"
          exclude-branches: "^legacy$"
```

Only upload on branches that start with `stage-` but do not contain `hotfix`

```yaml
steps:
  - label: "🔨 Test"
    command: "make test"
    plugins:
      - test-collector#v1.7.0:
          files: "test-data-*.json"
          format: "json"
          branches: "^stage-"
          exclude-branches: "hotfix"
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
