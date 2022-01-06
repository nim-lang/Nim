#[
Copyright (c) Facebook, Inc. and its affiliates.
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Adapted `setenv` from https://github.com/facebook/folly/blob/master/folly/portability/Stdlib.cpp
translated from C to nim.
]#

#[
Introduced in https://github.com/facebook/folly/commit/5d8ca09a3f96afefb44e35808f03651a096ab9c7

TODO:
check errno_t vs cint
]#

when not defined(windows): discard
else:
  type wchar_t  {.importc: "wchar_t".} = int16

  proc setEnvironmentVariableA*(lpName, lpValue: cstring): int32 {.
    stdcall, dynlib: "kernel32", importc: "SetEnvironmentVariableA", sideEffect.}
    # same as winlean.setEnvironmentVariableA

  proc c_getenv(env: cstring): cstring {.importc: "getenv", header: "<stdlib.h>".}
  proc c_putenv(envstring: cstring): cint {.importc: "_putenv", header: "<stdlib.h>".}
  proc c_wgetenv(varname: ptr wchar_t): ptr wchar_t {.importc: "_wgetenv", header: "<stdlib.h>".}

  var errno {.importc, header: "<errno.h>".}: cint
  var gWenviron {.importc: "_wenviron".}: ptr ptr wchar_t
    # xxx `ptr UncheckedArray[WideCString]` did not work

  proc mbstowcs(wcstr: ptr wchar_t, mbstr: cstring, count: csize_t): csize_t {.importc: "mbstowcs", header: "<stdlib.h>".}
    # xxx cint vs errno_t?

  proc setEnvImpl*(name: string, value: string, overwrite: cint): cint =
    const EINVAL = cint(22)
    if overwrite == 0 and c_getenv(cstring(name)) != nil: return 0
    if value != "":
      let envstring = name & "=" & value
      let e = c_putenv(cstring(envstring))
      if e != 0:
        errno = EINVAL
        return -1
      return 0
    #[
    We are trying to set the value to an empty string, but `_putenv` deletes
    entries if the value is an empty string, and just calling
    SetEnvironmentVariableA doesn't update `_environ`,
    so we have to do these terrible things.
    ]#
    let envstring = name & "=  "
    if c_putenv(cstring(envstring)) != 0:
      errno = EINVAL
      return -1
    # Here lies the documentation we blatently ignore to make this work.
    var s = c_getenv(cstring(name))
    s[0] = '\0'
    #[
    This would result in a double null termination, which normally signifies the
    end of the environment variable list, so we stick a completely empty
    environment variable into the list instead.
    ]#
    s = c_getenv(cstring(name))
    s[1] = '='
    #[
    If gWenviron is null, the wide environment has not been initialized
    yet, and we don't need to try to update it. We have to do this otherwise
    we'd be forcing the initialization and maintenance of the wide environment
    even though it's never actually used in most programs.
    ]#
    if gWenviron != nil:
      # var buf: array[MAX_ENV + 1, WideCString]
      let requiredSize = mbstowcs(nil, cstring(name), 0).int
      var buf = newSeq[Utf16Char](requiredSize + 1)
      let buf2 = cast[ptr wchar_t](buf[0].addr)
      if mbstowcs(buf2, cstring(name), csize_t(requiredSize + 1)) == csize_t(high(uint)):
        errno = EINVAL
        return -1
      var ptrToEnv = cast[WideCString](c_wgetenv(buf2))
      ptrToEnv[0] = '\0'.Utf16Char
      ptrToEnv = cast[WideCString](c_wgetenv(buf2))
      ptrToEnv[1] = '='.Utf16Char

    # And now, we have to update the outer environment to have a proper empty value.
    if setEnvironmentVariableA(cstring(name), cstring(value)) == 0:
      errno = EINVAL
      return -1
    return 0
