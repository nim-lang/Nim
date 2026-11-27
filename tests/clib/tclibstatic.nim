discard """
  joinable: "false"
"""

when defined(consumer):
  proc sampleclibAdd(a, b: int): int {.cdecl, importc: "sampleclib_add", clib: "sampleclib".}
  doAssert sampleclibAdd(1, 2) == 3
  doAssert sampleclibAdd(10, 20) == 30
else:
  import stdtest/specialpaths
  import std/[os, osproc, strformat, strutils]
  const
    file = currentSourcePath()
    nim = getCurrentCompilerExe()
  let
    libSrc = file.parentDir() / "sampleclib.nim"
    build = buildDir / "tclib_static"
  proc run(cmd: string) =
    doAssert execShellCmd(cmd) == 0, cmd
  createDir(build)
  # build the static library; ``--nomain`` keeps the lib's ``main``/``PreMain``
  # entry points out of the archive so they don't clash with the consumer's
  when defined(windows):
    let lib = build / "sampleclib.lib"
  else:
    let lib = build / "libsampleclib.a"
  run fmt"{nim} c --app:staticlib --nomain --nimmainprefix:sample --nimcache:{build} -o:{lib} {libSrc}"
  # build the consumer, linking the static lib via the {.clib.} pragma
  let consumer = build / "consumer".addFileExt(ExeExt)
  run fmt"{nim} c -d:consumer --clibdir:{build} --nimcache:{build} -o:{consumer} {file}"
  doAssert execShellCmd($consumer) == 0
