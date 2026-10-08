discard """
  joinable: false
"""

import std/[os, osproc, strutils, tempfiles]

# Test the compiler running this test, not a VM rebuilt from compiler sources.
const nim = getCurrentCompilerExe()

proc main() =
  let dir = createTempDir("nim_vm_26273_", "")
  try:
    let source = dir / "loop.nim"
    writeFile(source, """
const iterations {.intdefine.} = 32
static:
  var total = 0
  for i in 0 ..< iterations:
    for value in @[newString(65536)]:
      total += value.len
  doAssert total == iterations * 65536
""")

    proc occupiedMemory(iterations: int): int =
      let compiled = execCmdEx(quoteShellCommand([
        nim, "c", "--compileOnly", "--hints:on", "--hint:GCStats:on",
        "--nimcache:" & dir / "nimcache",
        "-d:iterations=" & $iterations, source]))
      doAssert compiled.exitCode == 0, compiled.output
      for line in compiled.output.splitLines:
        const prefix = "[GC] occupied memory: "
        if line.startsWith(prefix):
          return parseInt(line[prefix.len .. ^1])
      doAssert false, "Missing compiler memory statistics:\n" & compiled.output

    # Each leaked string adds 64 KiB. The old VM retains about 30 MiB more
    # in the longer run; allow 8 MiB for allocator/GC bookkeeping differences.
    let shortRun = occupiedMemory(32)
    let longRun = occupiedMemory(512)
    doAssert longRun - shortRun < 8 * 1024 * 1024,
      "Compile-time loop retained " & $(longRun - shortRun) & " extra bytes"
  finally:
    removeDir(dir)

main()
