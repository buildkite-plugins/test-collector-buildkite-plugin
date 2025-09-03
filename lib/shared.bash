# Infer the URL of the build that triggered this one.
# BUILDKITE_BUILD_URL has the scheme and host (generally https://buildkite.com).
# BUILDKITE_ORGANIZATION_SLUG is assumed to be unchanged (no cross-org triggers).
# BUILDKITE_TRIGGERED_FROM_... has other details.
# The /{org}/{pipeline}/builds/{number} path is assumed to be stable (decade+).
infer_triggered_from_build_url() {
  if [[
    -z $BUILDKITE_BUILD_URL ||
    -z $BUILDKITE_ORGANIZATION_SLUG ||
    -z $BUILDKITE_TRIGGERED_FROM_BUILD_PIPELINE_SLUG ||
    -z $BUILDKITE_TRIGGERED_FROM_BUILD_NUMBER
  ]]; then
    # fall back to the current build URL
    echo "$BUILDKITE_BUILD_URL"
    return
  fi

  local scheme=${BUILDKITE_BUILD_URL%%://*}
  local host_onwards=${BUILDKITE_BUILD_URL#*://}
  local host=${host_onwards%%/*}

  printf "%s://%s/%s/%s/builds/%d" \
    "$scheme" \
    "$host" \
    "$BUILDKITE_ORGANIZATION_SLUG" \
    "$BUILDKITE_TRIGGERED_FROM_BUILD_PIPELINE_SLUG" \
    "$BUILDKITE_TRIGGERED_FROM_BUILD_NUMBER"
}
