#! /bin/sh

# build development version of the compiler; can be rerun safely and will pickup
# any modification in config/build_config.txt
# arguments can be passed, eg `--os freebsd`
#
# Usage:
# sh build_all.sh # builds all
# NIMBUILD_ACTION=action_build_koch sh build_all.sh # just builds everything up to koch


set -u # error on undefined variables
set -e # exit on first error

echo_run(){
  echo "$*"
  "$@"
}

echo_run . config/build_config.txt

nim_csources=bin/nim_csources2

fetch_nim_csources(){
  (
    [ -d csources ] || echo_run $nim_csources2_clone_cmd
    echo_run cd csources
    echo_run git remote set-url origin $nim_csources2url
    echo_run git fetch -q --depth 1 origin tag $nim_csources2_tag
    echo_run git checkout $nim_csources2_tag
    echo_run git reset --hard $nim_csources2_tag
  )
}

build_nim_csources_via_script(){
  echo_run cd csources
  echo_run sh build.sh "$@"
}

build_nim_csources(){
  # avoid changing dir in case of failure
  (
    [ -f bin/nim ] && echo_run rm bin/nim # otherwise wrongly says: `bin/nim' is up to date.
    # it's cheap to redo the linking step anyway
    if [ $# -ne 0 ]; then
      # some args were passed (eg: `--cpu i386`), need to call build.sh
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
  echo_run bin/nim -v
  # keep $nim_csources in case needed to investigate bootstrap issues
  # without having to rebuild from csources
  echo_run cp bin/nim $nim_csources
}

## stable API below here
action_fetch_csources(){
  echo_run fetch_nim_csources
}

action_build_csources(){
  action_fetch_csources
  echo_run build_nim_csources
}

action_build_koch(){
  action_build_csources
  # always bootstrap from $nim_csources for reproducibility, in case this is rerun
  echo_run $nim_csources c --skipUserCfg --skipParentCfg --hints:off koch
}

action_build_all(){
  action_build_koch
  # re-running without modifications takes 2 seconds up to this line
  echo_run ./koch boot -d:release --skipUserCfg --skipParentCfg --hints:off
  echo_run ./koch tools --skipUserCfg --skipParentCfg --hints:off # Compile Nimble and other tools.
}

echo "NIMBUILD_ACTION: ${NIMBUILD_ACTION}"

if [ -z "${NIMBUILD_ACTION}" ]; then
  action_build_all # backward compatibility: same as action_build_all
elif [ "${NIMBUILD_ACTION}" = "action_definitions" ]; then
  echo "bash functions defined" # useful if we source this, then we can call individual functions
elif [ "${NIMBUILD_ACTION}" = "action_fetch_csources" ]; then
  action_fetch_csources
elif [ "${NIMBUILD_ACTION}" = "action_build_csources" ]; then
  echo_run fetch_nim_csources
elif [ "${NIMBUILD_ACTION}" = "action_build_koch" ]; then
  action_build_koch
elif [ "${NIMBUILD_ACTION}" = "action_build_all" ]; then
  action_build_all
else
  echo "unrecognized NIMBUILD_ACTION: $NIMBUILD_ACTION"
  exit 1
fi
