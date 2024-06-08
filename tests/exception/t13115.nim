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
      # save CI time by avoiding mostly redundant combinations as far as this bug is concerned
      var opts = case b
        of "c": @["", "-d:nim_t13115_static", "-d:danger", "-d:debug"]
        of "js": @["", "-d:nim_t13115_static"]
        else: @[""]

      for opt in opts:
        let cmd = fmt"{nim} r -b:{b} -d:nim_t13115 {opt} --hints:off {file}"
        let (outp, exitCode) = execCmdEx(cmd)
        when defined windows:
          # `\0` not preserved on windows
          doAssert "` and works fine!" in outp, cmd & "\n" & msg
        else:
          doAssert msg in outp, cmd & "\n" & msg
        doAssert exitCode == 1
  main()
