when not defined(case_custom):
  import strutils, strformat, os
  for a in "caseExpr caseSymbol casePaths caseRename caseFrom caseMultiNil".split:
    let path = currentSourcePath
    let cmd = fmt"nim c -r -d:{a} -d:case_custom {path}"
    doAssert execShellCmd(cmd) == 0, cmd
else:
  from macros import importInterp
  when defined(caseExpr):
    importInterp("std/" & "strutils")
    static: doAssert declared strutils

  when defined(caseSymbol):
    const path = "std/" & "strutils"
    importInterp path
    static: doAssert declared strutils

  when defined(casePaths):
    const path = ["os", "strutils"]
    importInterp path
    static:
      doAssert declared os
      doAssert declared strutils

  when defined(caseRename):
    importInterp("std/" & "strutils", strutils_temp)
    static: doAssert declared strutils_temp
    doAssert strutils_temp.splitLines("a") == @["a"] # sanity check

  when defined(caseFrom):
    importInterp "std/os": [ExeExt, DirSep]
    static:
      doAssert declared ExeExt
      doAssert declared DirSep
      doAssert not declared AltSep
      doAssert declared os.AltSep

  when defined(caseMultiNil):
    importInterp ["os", "strutils"]: nil
    static:
      doAssert not declared ExeExt
      doAssert declared os.ExeExt

  when defined(caseMegatestLike):
    # not enabling this one to avoid slowdowns, just for illustration.
    import sequtils, os, strformat
    const nimLibPure = fmt"{currentSourcePath}".parentDir
    const paths = block:
      var ret: seq[string]
      for kind, path in walkDir(nimLibPure):
        if kind != pcFile: continue
        if ret.len > 10: break
        ret.add path
      ret
    importInterp paths: nil
