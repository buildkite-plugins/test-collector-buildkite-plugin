apply_use_triggered_from() {
  if [[ ${BUILDKITE_PLUGIN_TEST_COLLECTOR_USE_TRIGGERED_FROM:-false} == "false" ]]; then
    # use-triggered-from is not enabled
    return
  fi

  if [[ -z ${BUILDKITE_TRIGGERED_FROM_BUILD_ID:-} ]]; then
    echo "use-triggered-from is enabled, but BUILDKITE_TRIGGERED_FROM_BUILD_ID is not set"
    return
  fi

  # update globals previously defined in hooks/pre-exit
  RUN_ENV_KEY="$BUILDKITE_TRIGGERED_FROM_BUILD_ID"
  RUN_ENV_URL=$(infer_triggered_from_build_url)
  RUN_ENV_NUMBER="$BUILDKITE_TRIGGERED_FROM_BUILD_NUMBER"
  RUN_ENV_JOB_ID=""

  echo "  use-triggered-from: uploads will be associated with $RUN_ENV_URL"
}

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
    echo "warning: missing details to infer triggerer-from URL" >&2
    echo ""
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
