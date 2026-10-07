# Utilities used in CI pipelines and tooling to avoid duplication.
# Avoid top-level statements.
# Prefer nim scripts whenever possible.
# functions starting with `_` are considered internal, less stable.

echo_run () {
  # echo's a command before running it, which helps understanding logs
  echo ""
  echo "cmd: $@" # in azure we could also use this: echo '##[section]"$@"'
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

nimInternalInstallDepsWindows(){
  echo_run mkdir -p dist || return
  echo_run curl --fail --location --retry 3 --connect-timeout 30 --max-time 300 \
    https://nim-lang.org/download/mingw64.7z -o dist/mingw64.7z || return
  echo_run curl --fail --location --retry 3 --connect-timeout 30 --max-time 300 \
    https://nim-lang.org/download/dlls.zip -o dist/dlls.zip || return
  echo_run 7z x -y dist/mingw64.7z -odist || return
  echo_run 7z x -y dist/dlls.zip -obin
}

nimInternalBuildKochAndRunCI(){
  echo_run nim c koch || return
  if ! echo_run ./koch runCI; then
    echo_run echo "runCI failed"
    echo_run nim r tools/ci_testresults.nim
    return 1
  fi
}

nimDefineVars(){
  . config/build_config.txt || return
  nim_csources=bin/nim_csources_$nim_csourcesHash
}

_nimNumCpu(){
  # linux: $(nproc)
  # FreeBSD | macOS: $(sysctl -n hw.ncpu)
  # OpenBSD: $(sysctl -n hw.ncpuonline)
  # windows: $NUMBER_OF_PROCESSORS ?
  if env | grep -q '^NIMCORES='; then
    echo $NIMCORES
  else
    echo $(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || 1)
  fi
}

_nimBuildCsourcesIfNeeded(){
  # if some systems cannot use make or gmake, we could add support for calling `build.sh`
  # but this is slower (not parallel jobs) and would require making build.sh
  # understand the arguments passed to the makefile (e.g. `CC=gcc ucpu=amd64 uos=darwin`),
  # instead of `--cpu amd64 --os darwin`.
  unamestr=$(uname)
  # uname values: https://en.wikipedia.org/wiki/Uname
  if [ "$unamestr" = 'FreeBSD' ]; then
    makeX=gmake
  elif [ "$unamestr" = 'OpenBSD' ]; then
    makeX=gmake
  elif [ "$unamestr" = 'NetBSD' ]; then
    makeX=gmake
  elif [ "$unamestr" = 'CROSSOS' ]; then
    makeX=gmake
  elif [ "$unamestr" = 'SunOS' ]; then
    makeX=gmake
  else
    makeX=make
  fi
  nCPU=$(_nimNumCpu)
  echo_run which $makeX || return
  # parallel jobs (5X faster on 16 cores: 10s instead of 50s)
  echo_run $makeX -C "$nim_csourcesDir" -j $((nCPU + 2)) -l $nCPU "$@" || return
}

_nimCsourcesIsRepo(){
  # Git must not discover the enclosing Nim checkout for an unpacked archive.
  (
    cd "$nim_csourcesDir" || exit
    test -e .git || exit 1
    root=$(git rev-parse --show-toplevel 2>/dev/null) || exit
    test "$(cd "$root" && pwd -P)" = "$(pwd -P)"
  )
}

_nimFetchCsourcesPin(){
  # Called only for a newly created repository or an explicitly strict CI build.
  (
    cd "$nim_csourcesDir" || exit
    if ! git cat-file -e "$nim_csourcesHash^{commit}" 2>/dev/null; then
      if ! echo_run git fetch -q --depth 1 "$nim_csourcesUrl" "$nim_csourcesHash"; then
        # Older Git/servers may reject an unadvertised SHA. Fetch branch history
        # instead; never replace the configured pin with the branch head.
        echo_run git fetch -q "$nim_csourcesUrl" "$nim_csourcesBranch" || exit
        if test -f .git/shallow; then
          echo_run git fetch -q --unshallow "$nim_csourcesUrl" "$nim_csourcesBranch" || exit
        fi
        git cat-file -e "$nim_csourcesHash^{commit}" || exit
      fi
    fi
    echo_run git checkout -q "$nim_csourcesHash" || exit
  )
}

nimCiSystemInfo(){
  nimDefineVars
  echo_run eval echo '$'nim_csources
  echo_run pwd
  echo_run date
  echo_run uname -a
  echo_run git log --no-merges -1 --pretty=oneline
  echo_run eval echo '$'PATH
  echo_run gcc -v
  echo_run node -v
  echo_run make -v
}

nimCsourcesHash(){
  nimDefineVars
  echo $nim_csourcesHash
}

nimBuildCsourcesIfNeeded(){
  # goal: allow cachine each tagged version independently
  # to avoid rebuilding, so that tools like `git bisect`
  # can grab a cached past version without rebuilding.
  nimDefineVars || return
  (
    set -e
    # avoid polluting caller scope with internal variable definitions.
    cacheable=1
    if test -d "$nim_csourcesDir"; then
      if test "${NIM_CSOURCES_STRICT:-0}" = 1; then
        _nimCsourcesIsRepo || { echo "Not a csources Git repository: $nim_csourcesDir" >&2; exit 1; }
        (
          cd "$nim_csourcesDir" || exit
          # csources make leaves untracked .o files; reject source edits, not
          # normal build output. Checkout still protects conflicting files.
          status=$(git status --porcelain --untracked-files=no) || exit
          test -z "$status" || { echo "Refusing to change dirty csources" >&2; exit 1; }
        ) || exit
      else
        # Local builds preserve archive contents and a developer's chosen checkout.
        # Their compiler must not be published under the configured pin's key.
        cacheable=0
      fi
    fi
    if test "$cacheable" = 1 && test -f "$nim_csources"; then
      echo "$nim_csources exists."
    else
      if test -d "$nim_csourcesDir"; then
        echo "$nim_csourcesDir exists."
      else
        echo_run git init -q "$nim_csourcesDir" || exit
      fi
      if test "$cacheable" = 1; then
        _nimCsourcesIsRepo || exit
        _nimFetchCsourcesPin || exit
      fi
      _nimBuildCsourcesIfNeeded "$@" || exit
      if test "$cacheable" = 1; then
        echo_run cp bin/nim "$nim_csources" || exit
      fi
    fi

    if test "$cacheable" = 1; then
      echo_run rm -f bin/nim || exit
      # fixes bug #17913, but it's unclear why it's needed, maybe specific to MacOS Big Sur 11.3 on M1 arch?
      echo_run cp "$nim_csources" bin/nim || exit
    fi
    echo_run bin/nim -v
  )
}
