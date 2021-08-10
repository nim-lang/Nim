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

  proc c_getenv(env: cstring): cstring {.
    importc: "getenv", header: "<stdlib.h>".}
  when defined(windows):
    proc c_putenv_s(envname: cstring, envval: cstring): cint {.importc: "_putenv_s", header: "<stdlib.h>".}
    from std/private/win_setenv import setEnvImpl
  else:
    proc c_setenv(envname: cstring, envval: cstring, overwrite: cint): cint {.importc: "setenv", header: "<stdlib.h>".}
  proc c_unsetenv(env: cstring): cint {.importc: "unsetenv", header: "<stdlib.h>".}

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

    let env = c_getenv(key)
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

    return c_getenv(key) != nil

  proc putEnv*(key, val: string) {.tags: [WriteEnvEffect].} =
    ## Sets the value of the `environment variable`:idx: named `key` to `val`.
    ## If an error occurs, `OSError` is raised.
    ##
    ## See also:
    ## * `getEnv proc <#getEnv,string,string>`_
    ## * `existsEnv proc <#existsEnv,string>`_
    ## * `delEnv proc <#delEnv,string>`_
    ## * `envPairs iterator <#envPairs.i>`_
    when defined(windows):
      if key.len == 0 or '=' in key:
        raise newException(OSError, "invalid key, got: " & $(key, val))
      if setEnvImpl(key, val, 1'i32) != 0'i32:
        raiseOSError(osLastError(), $(key, val))
    else:
      if c_setenv(key, val, 1'i32) != 0'i32:
        raiseOSError(osLastError(), $(key, val))

  proc delEnv*(key: string) {.tags: [WriteEnvEffect].} =
    ## Deletes the `environment variable`:idx: named `key`.
    ## If an error occurs, `OSError` is raised.
    ##
    ## See also:ven
    ## * `getEnv proc <#getEnv,string,string>`_
    ## * `existsEnv proc <#existsEnv,string>`_
    ## * `putEnv proc <#putEnv,string,string>`_
    ## * `envPairs iterator <#envPairs.i>`_
    template bail = raiseOSError(osLastError(), key)
    when defined(windows):
      #[ 
      # https://docs.microsoft.com/en-us/cpp/c-runtime-library/reference/putenv-s-wputenv-s?view=msvc-160
      > You can remove a variable from the environment by specifying an empty string (that is, "") for value_string
      note that nil is not legal
      ]#
      if key.len == 0 or '=' in key:
        raise newException(OSError, "invalid key, got: " & key)
      if c_putenv_s(key, "") != 0'i32: bail
    else:
      if c_unsetenv(key) != 0'i32: bail

  when defined(windows):
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
  elif defined(macosx) and not defined(ios) and not defined(emscripten):
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
    when defined(windows):
      block:
        template impl(get_fun, typ, size, zero, free_fun) =
          let env = get_fun()
          var e = env
          if e == nil: break
          while true:
            let eend = strEnd(e)
            let kv = $e
            let p = find(kv, '=')
            yield (substr(kv, 0, p-1), substr(kv, p+1))
            e = cast[typ](cast[ByteAddress](eend)+size)
            if typeof(zero)(eend[1]) == zero: break
          discard free_fun(env)
        when useWinUnicode:
          impl(getEnvironmentStringsW, WideCString, 2, 0, freeEnvironmentStringsW)
        else:
          impl(getEnvironmentStringsA, cstring, 1, '\0', freeEnvironmentStringsA)
    else:
      var i = 0
      when defined(macosx) and not defined(ios) and not defined(emscripten):
        var gEnv = NSGetEnviron()[]
      while gEnv[i] != nil:
        let kv = $gEnv[i]
        inc(i)
        let p = find(kv, '=')
        yield (substr(kv, 0, p-1), substr(kv, p+1))
