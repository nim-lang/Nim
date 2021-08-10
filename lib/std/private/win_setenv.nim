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
  proc setEnvironmentVariableA*(lpName, lpValue: cstring): int32 {.
    stdcall, dynlib: "kernel32", importc: "SetEnvironmentVariableA", sideEffect.}
    # same as winlean.setEnvironmentVariableA

  proc c_getenv(env: cstring): cstring {.importc: "getenv", header: "<stdlib.h>".}
  proc c_putenv_s(envname: cstring, envval: cstring): cint {.importc: "_putenv_s", header: "<stdlib.h>".}
  proc c_wgetenv(varname: WideCString): WideCString {.importc: "_wgetenv", header: "<stdlib.h>".}

  var errno {.importc, header: "<errno.h>".}: cint
  type wchar_t  {.importc: "wchar_t".} = int16
  var gWenviron {.importc:"_wenviron".}: ptr ptr wchar_t
    # xxx `ptr UncheckedArray[WideCString]` did not work

  proc mbstowcs_s(pReturnValue: ptr csize_t, wcstr: WideCString, sizeInWords: csize_t, mbstr: cstring, count: csize_t): cint {.importc: "mbstowcs_s", header: "<stdlib.h>".}
    # xxx cint vs errno_t?

  proc setEnvImpl*(name: cstring, value: cstring, overwrite: cint): cint =
    const EINVAL = cint(22)
    const MAX_ENV = 32767
      # xxx get it from: `var MAX_ENV {.importc: "_MAX_ENV", header:"<stdlib.h>".}: cint`
    if overwrite == 0 and c_getenv(name) != nil: return 0
    if value[0] != '\0':
      let e = c_putenv_s(name, value)
      if e != 0:
        errno = e
        return -1
      return 0
    #[
    We are trying to set the value to an empty string, but `_putenv_s` deletes
    entries if the value is an empty string, and just calling
    SetEnvironmentVariableA doesn't update `_environ`,
    so we have to do these terrible things.
    ]#
    if c_putenv_s(name, "  ") != 0:
      errno = EINVAL
      return -1
    # Here lies the documentation we blatently ignore to make this work.
    var s = c_getenv(name)
    s[0] = '\0'
    #[
    This would result in a double null termination, which normally signifies the
    end of the environment variable list, so we stick a completely empty
    environment variable into the list instead.
    ]#
    s[1] = '='
    #[
    If gWenviron is null, the wide environment has not been initialized
    yet, and we don't need to try to update it. We have to do this otherwise
    we'd be forcing the initialization and maintenance of the wide environment
    even though it's never actually used in most programs.
    ]#
    if gWenviron != nil:
      # var buf: array[MAX_ENV + 1, WideCString]
      var buf: array[MAX_ENV + 1, Utf16Char]
      let buf2 = cast[WideCString](buf[0].addr)
      var len: csize_t
      if mbstowcs_s(len.addr, buf2, buf.len.csize_t, name, MAX_ENV) != 0:
        errno = EINVAL
        return -1
      c_wgetenv(buf2)[0] = '\0'.Utf16Char
      c_wgetenv(buf2)[1] = '='.Utf16Char

    # And now, we have to update the outer environment to have a proper empty value.
    if setEnvironmentVariableA(name, value) == 0:
      errno = EINVAL
      return -1
    return 0
