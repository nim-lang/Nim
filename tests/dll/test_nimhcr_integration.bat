set NIM=nim
set NIM_FLAGS=-d:debug --genRedist

%NIM% c --outdir:"." %NIM_FLAGS% nimrtl.nim
%NIM% c --outdir:"." %NIM_FLAGS% nimhcr.nim

set HCR_FLAGS=--forceBuild --hotCodeReloading:on --nimcache:nimcache %NIM_FLAGS%

%NIM% %HCR_FLAGS% c nimhcr_integration.nim
nimhcr_integration %NIM% %HCR_FLAGS% c nimhcr_integration.nim
