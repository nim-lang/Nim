set NIM=nim
set NIM_FLAGS=-d:debug

%NIM% c --outdir:"." %NIM_FLAGS% ../../lib/nimrtl.nim
%NIM% c --outdir:"." %NIM_FLAGS% ../../lib/nimhcr.nim

set HCR_FLAGS=--forceBuild --hotCodeReloading:on --nimcache:nimcache %NIM_FLAGS%

%NIM% %HCR_FLAGS% c nimhcr_integration.nim
nimhcr_integration %NIM% %HCR_FLAGS% c nimhcr_integration.nim
