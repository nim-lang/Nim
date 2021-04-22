#! /bin/sh

# build development version of the compiler; can be rerun safely.
# arguments can be passed, e.g.:
# CC=gcc ucpu=amd64 uos=darwin
#
# when `NIM_CSOURCES_USE_BUILD=1` environment is set, it will build csourcesAny with `build.sh`
# instead, and the arguments are:
# --cpu amd64 --os darwin (also honors some environment variables, e.g. `CC`)

set -u # error on undefined variables
set -e # exit on first error

. ci/funs.sh

nimBuildCsourcesIfNeeded "$@"
  
# Note: if fails, may need to update csourcesAny manually
echo_run bin/nim c --skipUserCfg --skipParentCfg koch

echo_run ./koch boot -d:release --skipUserCfg --skipParentCfg
echo_run ./koch tools --skipUserCfg --skipParentCfg # Compile Nimble and other tools.
