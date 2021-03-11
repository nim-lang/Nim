# utilities used in CI pipelines to avoid duplication.

echo_run () {
  # echo's a command before running it, which helps understanding logs
  echo ""
  echo "$@"
  "$@"
}
