#!/bin/bash

set -e

rm -rf nimcache

NIM_FLAGS=${*:- -d:debug}
NIM=nim

$NIM c --outdir:"." $NIM_FLAGS ../../lib/nimrtl.nim
$NIM c --outdir:"." $NIM_FLAGS ../../lib/nimhcr.nim

echo ===== Compiling HCR Integration Test =====
HCR_FLAGS="--forceBuild --hotCodeReloading:on --nimcache:nimcache $NIM_FLAGS"
$NIM $HCR_FLAGS c nimhcr_integration.nim
export LD_LIBRARY_PATH=$(pwd):$LD_LIBRARY_PATH
./nimhcr_integration $NIM $HCR_FLAGS c nimhcr_integration.nim
