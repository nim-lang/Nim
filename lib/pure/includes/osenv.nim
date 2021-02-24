# Include file that implements 'getEnv' and friends. Do not import it!

when not declared(os) and not declared(ospaths):
  {.error: "This is an include file for os.nim!".}

when defined(nodejs):
  proc getEnv*(key: string, default = ""): string {.tags: [ReadEnvEffect].} =
    var ret: cstring
    let key2 = key.cstring
    {.emit: "`ret` = process.env[`key2`];".}
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
  proc c_putenv(env: cstring): cint {.
    importc: "putenv", header: "<stdlib.h>".}
  proc c_unsetenv(env: cstring): cint {.
    importc: "unsetenv", header: "<stdlib.h>".}

  # Environment handling cannot be put into RTL, because the `envPairs`
  # iterator depends on `environment`.

  var
    envComputed {.threadvar.}: bool
    environment {.threadvar.}: seq[string]

  when defined(nimV2):
    proc unpairedEnvAllocs*(): int =
      result = environment.len
      if result > 0: inc result

  when defined(windows) and not defined(nimscript):
    # because we support Windows GUI applications, things get really
    # messy here...
    when useWinUnicode:
      when defined(cpp):
        proc strEnd(cstr: WideCString, c = 0'i32): WideCString {.
          importcpp: "(NI16*)wcschr((const wchar_t *)#, #)", header: "<string.h>".}
      else:
        proc strEnd(cstr: WideCString, c = 0'i32): WideCString {.
          importc: "wcschr", header: "<string.h>".}
    else:
      proc strEnd(cstr: cstring, c = 0'i32): cstring {.
        importc: "strchr", header: "<string.h>".}

    proc getEnvVarsC() =
      if not envComputed:
        environment = @[]
        when useWinUnicode:
          var
            env = getEnvironmentStringsW()
            e = env
          if e == nil: return # an error occurred
          while true:
            var eend = strEnd(e)
            add(environment, $e)
            e = cast[WideCString](cast[ByteAddress](eend)+2)
            if eend[1].int == 0: break
          discard freeEnvironmentStringsW(env)
        else:
          var
            env = getEnvironmentStringsA()
            e = env
          if e == nil: return # an error occurred
          while true:
            var eend = strEnd(e)
            add(environment, $e)
            e = cast[cstring](cast[ByteAddress](eend)+1)
            if eend[1] == '\0': break
          discard freeEnvironmentStringsA(env)
        envComputed = true

  else:
    const
      useNSGetEnviron = (defined(macosx) and not defined(ios) and not defined(emscripten)) or defined(nimscript)

    when useNSGetEnviron:
      # From the manual:
      # Shared libraries and bundles don't have direct access to environ,
      # which is only available to the loader ld(1) when a complete program
      # is being linked.
      # The environment routines can still be used, but if direct access to
      # environ is needed, the _NSGetEnviron() routine, defined in
      # <crt_externs.h>, can be used to retrieve the address of environ
      # at runtime.
      proc NSGetEnviron(): ptr cstringArray {.
        importc: "_NSGetEnviron", header: "<crt_externs.h>".}
    elif defined(haiku):
      var gEnv {.importc: "environ", header: "<stdlib.h>".}: cstringArray
    else:
      var gEnv {.importc: "environ".}: cstringArray

    proc getEnvVarsC() =
      # retrieves the variables of char** env of C's main proc
      if not envComputed:
        environment = @[]
        when useNSGetEnviron:
          var gEnv = NSGetEnviron()[]
        var i = 0
        while gEnv[i] != nil:
          add environment, $gEnv[i]
          inc(i)
        envComputed = true

  proc findEnvVar(key: string): int =
    getEnvVarsC()
    var temp = key & '='
    for i in 0..high(environment):
      when defined(windows):
        if skipIgnoreCase(environment[i], temp) == len(temp): return i
      else:
        if startsWith(environment[i], temp): return i
    return -1

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
      var i = findEnvVar(key)
      if i >= 0:
        return substr(environment[i], find(environment[i], '=')+1)
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
      if c_getenv(key) != nil: return true
      else: return findEnvVar(key) >= 0

  proc putEnv*(key, val: string) {.tags: [WriteEnvEffect].} =
    ## Sets the value of the `environment variable`:idx: named `key` to `val`.
    ## If an error occurs, `OSError` is raised.
    ##
    ## See also:
    ## * `getEnv proc <#getEnv,string,string>`_
    ## * `existsEnv proc <#existsEnv,string>`_
    ## * `delEnv proc <#delEnv,string>`_
    ## * `envPairs iterator <#envPairs.i>`_

    # Note: by storing the string in the environment sequence,
    # we guarantee that we don't free the memory before the program
    # ends (this is needed for POSIX compliance). It is also needed so that
    # the process itself may access its modified environment variables!
    when nimvm:
      discard "built into the compiler"
    else:
      var indx = findEnvVar(key)
      if indx >= 0:
        environment[indx] = key & '=' & val
      else:
        add environment, (key & '=' & val)
        indx = high(environment)
      when defined(windows) and not defined(nimscript):
        when useWinUnicode:
          var k = newWideCString(key)
          var v = newWideCString(val)
          if setEnvironmentVariableW(k, v) == 0'i32: raiseOSError(osLastError())
        else:
          if setEnvironmentVariableA(key, val) == 0'i32: raiseOSError(osLastError())
      else:
        if c_putenv(environment[indx]) != 0'i32:
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
      var indx = findEnvVar(key)
      if indx < 0: return # Do nothing if the env var is not already set
      when defined(windows) and not defined(nimscript):
        when useWinUnicode:
          var k = newWideCString(key)
          if setEnvironmentVariableW(k, nil) == 0'i32: raiseOSError(osLastError())
        else:
          if setEnvironmentVariableA(key, nil) == 0'i32: raiseOSError(osLastError())
      else:
        if c_unsetenv(key) != 0'i32:
          raiseOSError(osLastError())
      environment.delete(indx)

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
    getEnvVarsC()
    for i in 0..high(environment):
      var p = find(environment[i], '=')
      yield (substr(environment[i], 0, p-1),
             substr(environment[i], p+1))
