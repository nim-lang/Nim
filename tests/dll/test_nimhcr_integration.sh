#!/bin/bash

set -e

rm -rf nimcache

NIM=nimd
NIM_FLAGS="--forceBuild --hotCodeReloading:on -d:debug --debugInfo --nimcache:nimcache $*"

$NIM c --outdir:"." ../../lib/nimrtl.nim
$NIM c --outdir:"." ../../lib/nimhcr.nim

echo ===== Compiling HCR Integration Test =====
$NIM $NIM_FLAGS c nimhcr_integration.nim

export LD_LIBRARY_PATH=$(pwd):$LD_LIBRARY_PATH
./nimhcr_integration $NIM $NIM_FLAGS c nimhcr_integration.nim
