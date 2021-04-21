#! /bin/sh

# build development version of the compiler; can be rerun safely.
# arguments can be passed, e.g. `--os freebsd`

set -u # error on undefined variables
set -e # exit on first error

. ci/funs.sh

nimBuildCsourcesIfNeeded
  
# Note: if fails, may need to update csources manually
echo_run bin/nim c --skipUserCfg --skipParentCfg koch

echo_run ./koch boot -d:release --skipUserCfg --skipParentCfg
echo_run ./koch tools --skipUserCfg --skipParentCfg # Compile Nimble and other tools.
