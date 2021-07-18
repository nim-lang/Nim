discard """
joinable: false
"""

# bug #16949
# bug #15955

when defined case1:
  proc foo(): int {.exportc.} = 10
elif defined case2:
  proc foo(): int {.exportc, dynlib.} = 10
elif defined caseMain:
  proc foo(): int {.importc.}
  doAssert foo() == 10
else:
  import stdtest/specialpaths
  import std/[os, strformat, strutils, compilesettings]
  proc runCmd(cmd: string) =
    doAssert execShellCmd(cmd) == 0, $cmd
  const
    file = currentSourcePath
    nim = getCurrentCompilerExe()
    mode = querySetting(backend)
  proc test(lib, options: string) =
    runCmd fmt"{nim} {mode} -o:{lib} --nomain {options} -f {file}"
    runCmd fmt"{nim} r -b:{mode} --passl:{lib} -d:caseMain -f {file}"

  test(buildDir / DynlibFormat % "D20210205T172720", "--app:lib -d:case2")

  when defined(windows):
    #[
    stdlib_io.nim.c:42:1: error: 'selectany' attribute applies only to initialized variables with external linkage
    2021-02-06T03:12:04.1640582Z  N_LIB_PRIVATE N_NOINLINE(void, callDepthLimitReached__mMRdr4sgmnykA9aWeM9aDZlw)(void);
    ]#
    discard
  else:
    test(buildDir / "libD20210205T172314.a", "--app:staticlib -d:nimLinkerWeakSymbols -d:case1")
