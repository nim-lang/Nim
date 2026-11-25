discard """
  cmd: "nim check --os:linux --cpu:riscv64 --app:lib -d:createNimHcr --threads:off --hints:off $file"
  errormsg: "hot code reloading has no jump table for riscv64 on linux"
  file: "nimhcr.nim"
"""

# The jump table of the HCR runtime is written for x86, x86-64, and arm64.
# Elsewhere the runtime wrote x86 instructions and the program died with
# SIGILL at its first call through the table; it must not compile.

import nimhcr
