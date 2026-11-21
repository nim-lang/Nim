discard """
  joinable: false
"""

import std/[assertions, os, osproc, strutils, tempfiles]

let dir = createTempDir("nim_ic_batch_ownership_", "")
try:
  writeFile(dir / "genericdecl.nim", """
proc identity*[T](value: T): T = value
""")
  writeFile(dir / "instancehome.nim", """
import genericdecl
proc answer*(): int = identity(42)
""")
  let source = dir / "main.nim"
  writeFile(source, "import instancehome\necho answer()\n")
  let binary = dir / "prog".addFileExt(ExeExt)
  # Put the generic's declaration and its instance's home in the same worker.
  # The instance must be routed to its persisted home, where it is seeded.
  for backend in ["c", "cpp"]:
    proc build(expected: string) =
      let built = execCmdEx(quoteShellCommand([getCurrentCompilerExe(), backend,
        "--ic:on", "--hints:off", "--warnings:off", "--parallelBuild:2",
        "-d:icBatchSize:1024", "--nimcache:" & dir / backend,
        "--out:" & binary, source]))
      doAssert built.exitCode == 0, built.output
      let executed = execCmdEx(quoteShell(binary))
      doAssert executed.exitCode == 0 and executed.output.strip == expected, executed.output
    writeFile(dir / "genericdecl.nim", "proc identity*[T](value: T): T = value\n")
    build("42")
    build("42")
    writeFile(dir / "genericdecl.nim", "proc identity*[T](value: T): T = value + 1\n")
    build("43")
finally:
  removeDir(dir)
