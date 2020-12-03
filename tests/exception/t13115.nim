const msg = "This char is `" & '\0' & "` and works fine!"

when defined nim_t13115:
  # bug #13115
  template fn =
    raise newException(Exception, msg)
  when defined nim_t13115_static:
    static: fn()
  fn()
else:
  import std/[osproc,strformat,os,strutils]
  proc main =
    const nim = getCurrentCompilerExe()
    const file = currentSourcePath
    for b in "c js cpp".split:
      when defined(openbsd):
        if b == "js": continue # xxx bug: pending #13115
      for opt in ["-d:nim_t13115_static", ""]:
        let cmd = fmt"{nim} r -b:{b} -d:nim_t13115 {opt} --hints:off {file}"
        let (outp, exitCode) = execCmdEx(cmd)
        doAssert msg in outp, cmd & "\n" & msg
        doAssert exitCode == 1
  main()
