discard """
  cmd: "nim check --os:linux --cpu:arm64 --app:lib -d:createNimHcr --threads:off -u:musl --hints:off $file"
  errormsg: "hot code reloading has no jump table for arm64 on linux; with musl, pass -d:musl"
  file: "nimhcr.nim"
"""

# The jump table of the HCR runtime is written for x86, x86-64, and arm64 on
# macOS and musl. Elsewhere the runtime wrote x86 instructions and the program
# died with SIGILL at its first call through the table; it must not compile.
# Nim does not detect musl by itself, so this is also what Alpine on arm64
# reports without -d:musl. -u:musl keeps this the glibc case even when a
# config defines musl, as the Alpine CI does in config/nim.cfg.

import nimhcr
