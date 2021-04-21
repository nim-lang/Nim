# utilities used in CI pipelines to avoid duplication.
# Avoid top-level statements.

echo_run () {
  # echo's a command before running it, which helps understanding logs
  echo ""
  echo "$@"
  "$@"
}

set_skipci_azure () {
  # D20210329T004830:here refs https://github.com/microsoft/azure-pipelines-agent/issues/2944
  # `--no-merges` is needed to avoid merge commits which occur for PR's.
  # $(Build.SourceVersionMessage) is not helpful
  # nor is `github.event.head_commit.message` for github actions.
  commitMsg=$(git log --no-merges -1 --pretty=format:"%s")
  echo commitMsg: $commitMsg
  if [[ $commitMsg == *"[skip ci]"* ]]; then
    echo "skipci: true"
    echo '##vso[task.setvariable variable=skipci]true' # sets `skipci` to true
  else
    echo "skipci: false"
  fi
}
