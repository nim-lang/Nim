# Utilities used in CI pipelines and tooling to avoid duplication.
# Avoid top-level statements.
# Prefer nim scripts whenever possible.
# functions starting with `_` are considered internal, less stable.

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

nimDefineVars(){
  nim_csourcesDir=csources_v1 # where we clone
  nim_csourcesUrl=https://github.com/nim-lang/csources_v1.git
  nim_csourcesHash=a8a5241f9475099c823cfe1a5e0ca4022ac201ff
  nim_csources=bin/nim_csources_$nim_csourcesHash
}

_nimNumCpu(){
  # linux: $(nproc)
  # FreeBSD | macOS: $(sysctl -n hw.ncpu)
  # OpenBSD: $(sysctl -n hw.ncpuonline)
  # windows: $NUMBER_OF_PROCESSORS ?
  echo $(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || 1)
}

_nimBuildCsourcesIfNeeded(){
  if [ "${NIM_CSOURCES_USE_BUILD:-0}" == "1" ]; then
    # call build.sh; slower and should be less useful
    # allows passing args (e.g.: `--cpu i386`),
    # but note that `make` also allows args (e.g. `CC`, `ucpu`).
    (
      # `()` avoid changing dir in case of failure
      echo_run cd $nim_csourcesDir
      echo_run sh build.sh "$@"
    )
  else # use `make`, allowing parallel jobs (5X faster on 16 cores: 10s instead of 50s)
    unamestr=$(uname)
    # uname values: https://en.wikipedia.org/wiki/Uname
    if [ "$unamestr" = 'FreeBSD' ]; then
      makeX=gmake
    elif [ "$unamestr" = 'OpenBSD' ]; then
      makeX=gmake
    else
      makeX=make
    fi
    nCPU=$(_nimNumCpu)
    echo_run which $makeX
    echo_run $makeX -C $nim_csourcesDir -j $((nCPU + 2)) -l $nCPU "$@"
  fi
  # keep $nim_csources in case needed to investigate bootstrap issues
  # without having to rebuild
  echo_run cp bin/nim $nim_csources
}

nimCsourcesHash(){
  nimDefineVars
  echo $nim_csourcesHash
}

nimBuildCsourcesIfNeeded(){
  # goal: allow cachine each tagged version independently
  # to avoid rebuilding, so that tools like `git bisect`
  # can grab a cached past version without rebuilding.
  nimDefineVars
  if test -f "$nim_csources"; then
    echo "$nim_csources exists."
  else
    if test -d "$nim_csourcesDir"; then
      echo "$nim_csourcesDir exists."
    else
      # depth 1: adjust as needed in case useful for `git bisect`
      echo_run git clone -q --depth 1 $nim_csourcesUrl "$nim_csourcesDir"
      echo_run git -C "$nim_csourcesDir" checkout $nim_csourcesHash
    fi
    _nimBuildCsourcesIfNeeded "$@"
  fi

  echo_run cp $nim_csources bin/nim
  echo_run $nim_csources -v
}
