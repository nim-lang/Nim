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
        if b == "js":
          # xxx bug: pending #13115
          # remove special case once nodejs updated >= 12.16.2
          # refs https://github.com/nim-lang/Nim/pull/16167#issuecomment-738270751
          continue

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
