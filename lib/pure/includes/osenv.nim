# Include file that implements 'getEnv' and friends. Do not import it!

when not declared(os) and not declared(ospaths):
  {.error: "This is an include file for os.nim!".}

when defined(nodejs):
  proc getEnv*(key: string, default = ""): string {.tags: [ReadEnvEffect].} =
    var ret = default.cstring
    let key2 = key.cstring
    {.emit: "const value = process.env[`key2`];".}
    {.emit: "if (value !== undefined) { `ret` = value };".}
    result = $ret

  proc existsEnv*(key: string): bool {.tags: [ReadEnvEffect].} =
    var key2 = key.cstring
    var ret: bool
    {.emit: "`ret` = `key2` in process.env;".}
    result = ret

  proc putEnv*(key, val: string) {.tags: [WriteEnvEffect].} =
    var key2 = key.cstring
    var val2 = val.cstring
    {.emit: "process.env[`key2`] = `val2`;".}

  proc delEnv*(key: string) {.tags: [WriteEnvEffect].} =
    var key2 = key.cstring
    {.emit: "delete process.env[`key2`];".}

  iterator envPairs*(): tuple[key, value: string] {.tags: [ReadEnvEffect].} =
    var num: int
    var keys: RootObj
    {.emit: "`keys` = Object.keys(process.env); `num` = `keys`.length;".}
    for i in 0..<num:
      var key, value: cstring
      {.emit: "`key` = `keys`[`i`]; `value` = process.env[`key`];".}
      yield ($key, $value)

# commented because it must keep working with js+VM
# elif defined(js):
#   {.error: "requires -d:nodejs".}

else:
  when defined(windows):
    from parseutils import skipIgnoreCase

  proc c_getenv(env: cstring): cstring {.
    importc: "getenv", header: "<stdlib.h>".}
  when defined(vcc):
    proc c_putenv_s(envname: cstring, envval: cstring): cint {.importc: "_putenv_s", header: "<stdlib.h>".}
  else:
    proc c_setenv(envname: cstring, envval: cstring, overwrite: cint): cint {.importc: "setenv", header: "<stdlib.h>".}
  proc c_unsetenv(env: cstring): cint {.
    importc: "unsetenv", header: "<stdlib.h>".}

  proc getEnv*(key: string, default = ""): string {.tags: [ReadEnvEffect].} =
    ## Returns the value of the `environment variable`:idx: named `key`.
    ##
    ## If the variable does not exist, `""` is returned. To distinguish
    ## whether a variable exists or it's value is just `""`, call
    ## `existsEnv(key) proc <#existsEnv,string>`_.
    ##
    ## See also:
    ## * `existsEnv proc <#existsEnv,string>`_
    ## * `putEnv proc <#putEnv,string,string>`_
    ## * `delEnv proc <#delEnv,string>`_
    ## * `envPairs iterator <#envPairs.i>`_
    runnableExamples:
      assert getEnv("unknownEnv") == ""
      assert getEnv("unknownEnv", "doesn't exist") == "doesn't exist"

    when nimvm:
      discard "built into the compiler"
    else:
      var env = c_getenv(key)
      if env == nil: return default
      result = $env

  proc existsEnv*(key: string): bool {.tags: [ReadEnvEffect].} =
    ## Checks whether the environment variable named `key` exists.
    ## Returns true if it exists, false otherwise.
    ##
    ## See also:
    ## * `getEnv proc <#getEnv,string,string>`_
    ## * `putEnv proc <#putEnv,string,string>`_
    ## * `delEnv proc <#delEnv,string>`_
    ## * `envPairs iterator <#envPairs.i>`_
    runnableExamples:
      assert not existsEnv("unknownEnv")

    when nimvm:
      discard "built into the compiler"
    else:
      return c_getenv(key) != nil

  proc putEnv*(key, val: string) {.tags: [
      WriteEnvEffect].} =
    ## Sets the value of the `environment variable`:idx: named `key` to `val`.
    ## If an error occurs, `OSError` is raised.
    ##
    ## See also:
    ## * `getEnv proc <#getEnv,string,string>`_
    ## * `existsEnv proc <#existsEnv,string>`_
    ## * `delEnv proc <#delEnv,string>`_
    ## * `envPairs iterator <#envPairs.i>`_
    when nimvm:
      discard "built into the compiler"
    else:
      when defined(windows) and not defined(nimscript):
        when useWinUnicode:
          var k = newWideCString(key)
          var v = newWideCString(val)
          if setEnvironmentVariableW(k, v) == 0'i32: raiseOSError(osLastError())
        else:
          if setEnvironmentVariableA(key, val) == 0'i32:
            raiseOSError(osLastError())
      elif defined(vcc):
        if c_putenv_s(key, val) != 0'i32:
          raiseOSError(osLastError())
      else:
        if c_setenv(key, val, 1'i32) != 0'i32:
          raiseOSError(osLastError())

  proc delEnv*(key: string) {.tags: [WriteEnvEffect].} =
    ## Deletes the `environment variable`:idx: named `key`.
    ## If an error occurs, `OSError` is raised.
    ##
    ## See also:ven
    ## * `getEnv proc <#getEnv,string,string>`_
    ## * `existsEnv proc <#existsEnv,string>`_
    ## * `putEnv proc <#putEnv,string,string>`_
    ## * `envPairs iterator <#envPairs.i>`_
    when nimvm:
      discard "built into the compiler"
    else:
      when defined(windows) and not defined(nimscript):
        when useWinUnicode:
          var k = newWideCString(key)
          if setEnvironmentVariableW(k, nil) == 0'i32:
            raiseOSError(osLastError())
        else:
          if setEnvironmentVariableA(key, nil) == 0'i32:
            raiseOSError(osLastError())
      else:
        if c_unsetenv(key) != 0'i32:
          raiseOSError(osLastError())

  when defined(windows) and not defined(nimscript):
    when useWinUnicode:
      when defined(cpp):
        proc strEnd(cstr: WideCString, c = 0'i32): WideCString {.importcpp: "(NI16*)wcschr((const wchar_t *)#, #)",
            header: "<string.h>".}
      else:
        proc strEnd(cstr: WideCString, c = 0'i32): WideCString {.importc: "wcschr",
            header: "<string.h>".}
    else:
      proc strEnd(cstr: cstring, c = 0'i32): cstring {.importc: "strchr",
          header: "<string.h>".}
  elif (defined(macosx) and not defined(ios) and not defined(emscripten)) or
      defined(nimscript):
    # From the manual:
    # Shared libraries and bundles don't have direct access to environ,
    # which is only available to the loader ld(1) when a complete program
    # is being linked.
    # The environment routines can still be used, but if direct access to
    # environ is needed, the _NSGetEnviron() routine, defined in
    # <crt_externs.h>, can be used to retrieve the address of environ
    # at runtime.
    proc NSGetEnviron(): ptr cstringArray {.importc: "_NSGetEnviron",
        header: "<crt_externs.h>".}
    var gEnv = NSGetEnviron()[]
  elif defined(haiku):
    var gEnv {.importc: "environ", header: "<stdlib.h>".}: cstringArray
  else:
    var gEnv {.importc: "environ".}: cstringArray

  iterator envPairs*(): tuple[key, value: string] {.tags: [ReadEnvEffect].} =
    ## Iterate over all `environments variables`:idx:.
    ##
    ## In the first component of the tuple is the name of the current variable stored,
    ## in the second its value.
    ##
    ## See also:
    ## * `getEnv proc <#getEnv,string,string>`_
    ## * `existsEnv proc <#existsEnv,string>`_
    ## * `putEnv proc <#putEnv,string,string>`_
    ## * `delEnv proc <#delEnv,string>`_
    when defined(windows) and not defined(nimscript):
      block:
        when useWinUnicode:
          var env = getEnvironmentStringsW()
          var e = env
          if e == nil: break
          while true:
            var eend = strEnd(e)
            let kv = $e
            var p = find(kv, '=')
            yield (substr(kv, 0, p-1), substr(kv, p+1))
            e = cast[WideCString](cast[ByteAddress](eend)+2)
            if eend[1].int == 0: break
          discard freeEnvironmentStringsW(env)
        else:
          var env = getEnvironmentStringsA()
          var e = env
          if e == nil: break
          while true:
            var eend = strEnd(e)
            let kv = $e
            var p = find(kv, '=')
            yield (substr(kv, 0, p-1), substr(kv, p+1))
            e = cast[cstring](cast[ByteAddress](eend)+1)
            if eend[1] == '\0': break
          discard freeEnvironmentStringsA(env)
    else:
      var i = 0
      while gEnv[i] != nil:
        let kv = $gEnv[i]
        inc(i)
        var p = find(kv, '=')
        yield (substr(kv, 0, p-1), substr(kv, p+1))
