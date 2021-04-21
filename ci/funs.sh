# utilities used in CI pipelines to avoid duplication.
# Avoid top-level statements.

echo_run () {
  # echo's a command before running it, which helps understanding logs
  echo ""
  echo "$@"
  "$@"
}

nimGetLastCommit() {
  git log --no-merges -1 --pretty=format:"%s"
}

nimIsCiSkip(){
  # D20210329T004830:here refs https://github.com/microsoft/azure-pipelines-agent/issues/2944
  # `--no-merges` is needed to avoid merge commits which occur for PR's.
  # $(Build.SourceVersionMessage) is not helpful
  # nor is `github.event.head_commit.message` for github actions.
  # Note: `[skip ci]` is now handled automatically for github actions, see https://github.blog/changelog/2021-02-08-github-actions-skip-pull-request-and-push-workflows-with-skip-ci/
  commitMsg=$(nimGetLastCommit)
  echo commitMsg: "$commitMsg"
  if [[ $commitMsg == *"[skip ci]"* ]]; then
    echo "skipci: true"
    return 0
  else
    echo "skipci: false"
    return 1
  fi
}
