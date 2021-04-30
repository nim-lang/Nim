#! /bin/sh

# build development version of the compiler; can be rerun safely.
# arguments can be passed, e.g. `--os freebsd`

set -u # error on undefined variables
set -e # exit on first error

echo_run(){
  echo "$*"
  "$@"
}

[ -d csources ] || echo_run git clone -q --depth 1 https://github.com/nim-lang/csources_v1.git csources

nim_csources=bin/nim_csources

build_nim_csources_via_script(){
  echo_run cd csources
  echo_run sh build.sh "$@"
}

build_nim_csources(){
  # avoid changing dir in case of failure
  (
    if [ $# -ne 0 ]; then
      # some args were passed (e.g.: `--cpu i386`), need to call build.sh
      build_nim_csources_via_script "$@"
    else
      # no args, use multiple Make jobs (5X faster on 16 cores: 10s instead of 50s)
      makeX=make
      unamestr=$(uname)
      if [ "$unamestr" = 'FreeBSD' ]; then
        makeX=gmake
      fi
      nCPU=$(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || 1)
      which $makeX && echo_run $makeX -C csources -j $((nCPU + 2)) -l $nCPU || build_nim_csources_via_script
    fi
  )
  # keep $nim_csources in case needed to investigate bootstrap issues
  # without having to rebuild from csources
  echo_run cp bin/nim $nim_csources
}

[ -f $nim_csources ] || echo_run build_nim_csources $@

# Note: if fails, may need to `cd csources && git pull`
echo_run bin/nim c --skipUserCfg --skipParentCfg koch

echo_run ./koch boot -d:release --skipUserCfg --skipParentCfg
echo_run ./koch tools --skipUserCfg --skipParentCfg # Compile Nimble and other tools.

