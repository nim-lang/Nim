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
    build = buildDir / "tclib_shared"
  proc run(cmd: string) =
    doAssert execShellCmd(cmd) == 0, cmd
  createDir(build)
  # build the shared library
  let lib = build / (DynlibFormat % "sampleclib")
  run fmt"{nim} c --app:lib --nimcache:{build} -o:{lib} {libSrc}"
  # build the consumer, linking the shared lib via the {.clib.} pragma; an
  # rpath lets it find the lib at run time (on Windows the dll is found in the
  # executable's own directory, so no rpath is needed)
  when defined(windows):
    let rpath = ""
  elif defined(macosx):
    let rpath = fmt"--passL:-rpath,{build}"
  else:
    let rpath = fmt"--passL:-Wl,-rpath,{build}"
  let consumer = build / "consumer".addFileExt(ExeExt)
  run fmt"{nim} c -d:consumer --clibdir:{build} {rpath} --nimcache:{build} -o:{consumer} {file}"
  doAssert execShellCmd($consumer) == 0
