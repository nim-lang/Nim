# Include file that implements 'osErrorMsg' and friends. Do not import it!

when not declared(os) and not declared(ospaths):
  {.error: "This is an include file for os.nim!".}

when not weirdTarget:
  var errno {.importc, header: "<errno.h>".}: cint

  when defined(windows):
    import winlean
  else:
    # `strerror` is not necessarily thread-safe. Use `strerror_r` instead.
    #
    # glibc: https://linux.die.net/man/3/strerror_r
    # The XSI-compliant version of strerror_r() is provided if:
    # (_POSIX_C_SOURCE >= 200112L || _XOPEN_SOURCE >= 600) && ! _GNU_SOURCE
    # Otherwise, the GNU-specific version is provided.
    # Note: -D_GNU_SOURCE=0 also defines the GNU-specific version (docs issue)
    {.emit: """
    #include <errno.h>
    #include <string.h>
    #if !defined(__GLIBC__) || \
        (((defined(_POSIX_C_SOURCE) && (_POSIX_C_SOURCE - 0) >= 200112L) || \
        (defined(_XOPEN_SOURCE) && (_XOPEN_SOURCE - 0) >= 600)) && \
        !defined(_GNU_SOURCE))
      int strerror_r(int errnum, char *buf, size_t buflen); /* XSI-compliant */
      #define strerror_r_posix strerror_r
    #else
      char *strerror_r(int errnum, char *buf, size_t buflen); /* GNU-specific */
      static int strerror_r_posix(int errnum, char *buf, size_t buflen) {
        char *desc = strerror_r(errnum, buf, buflen);
        if (desc == buf) return EINVAL; // `buf` is only used on unknown errors.
        if (!buflen) return ERANGE;
        size_t len = strnlen(desc, buflen - 1);
        (void) memcpy(buf, desc, len);
        buf[len] = '\0';
        if (desc[len]) return ERANGE;
        return 0;
      }
    #endif
    """.}

    proc c_strerror_r_posix(
      errnum: cint, buf: cstring, buflen: csize_t
    ): cint {.importc: "strerror_r_posix", nodecl.}

proc `==`*(err1, err2: OSErrorCode): bool {.borrow.}
proc `$`*(err: OSErrorCode): string {.borrow.}

proc osErrorMsg*(errorCode: OSErrorCode): string =
  ## Converts an OS error code into a human readable string.
  ##
  ## The error code can be retrieved using the `osLastError proc`_.
  ##
  ## If conversion fails, or `errorCode` is `0` then `""` will be
  ## returned.
  ##
  ## On Windows, the `-d:useWinAnsi` compilation flag can be used to
  ## make this procedure use the non-unicode Win API calls to retrieve the
  ## message.
  ##
  ## See also:
  ## * `raiseOSError proc`_
  ## * `osLastError proc`_
  runnableExamples:
    when defined(linux) or defined(macosx):
      assert osErrorMsg(OSErrorCode(0)) == ""
      assert osErrorMsg(OSErrorCode(1)) == "Operation not permitted"
      assert osErrorMsg(OSErrorCode(2)) == "No such file or directory"

  result = ""
  when weirdTarget:
    discard
  elif defined(windows):
    if errorCode != OSErrorCode(0'i32):
      when useWinUnicode:
        var msgbuf: WideCString
        if formatMessageW(0x00000100 or 0x00001000 or 0x00000200,
                        nil, errorCode.int32, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(cast[pointer](msgbuf))
      else:
        var msgbuf: cstring
        if formatMessageA(0x00000100 or 0x00001000 or 0x00000200,
                        nil, errorCode.int32, 0, addr(msgbuf), 0, nil) != 0'i32:
          result = $msgbuf
          if msgbuf != nil: localFree(msgbuf)
  else:
    if errorCode != OSErrorCode(0'i32):
      var buf {.noinit.}: array[256, cchar]
      let ret = c_strerror_r_posix(errorCode.int32, addr(buf), len(buf).csize_t)
      if ret == 0:
        result = $addr(buf)
      elif ret == EINVAL:
        result = "Unknown error " & $errorCode
      elif ret == ERANGE:
        result = "Long error description " & $errorCode
      else:
        result = "Unexpected " & $ret & " error " & $errorCode

proc newOSError*(
  errorCode: OSErrorCode, additionalInfo = ""
): owned(ref OSError) {.noinline.} =
  ## Creates a new `OSError exception <system.html#OSError>`_.
  ##
  ## The `errorCode` will determine the
  ## message, `osErrorMsg proc`_ will be used
  ## to get this message.
  ##
  ## The error code can be retrieved using the `osLastError proc`_.
  ##
  ## If the error code is `0` or an error message could not be retrieved,
  ## the message `unknown OS error` will be used.
  ##
  ## See also:
  ## * `osErrorMsg proc`_
  ## * `osLastError proc`_
  var e: owned(ref OSError); new(e)
  e.errorCode = errorCode.int32
  e.msg = osErrorMsg(errorCode)
  if additionalInfo.len > 0:
    if e.msg.len > 0 and e.msg[^1] != '\n': e.msg.add '\n'
    e.msg.add "Additional info: "
    e.msg.add additionalInfo
      # don't add trailing `.` etc, which negatively impacts "jump to file" in IDEs.
  if e.msg == "":
    e.msg = "unknown OS error"
  return e

proc raiseOSError*(errorCode: OSErrorCode, additionalInfo = "") {.noinline.} =
  ## Raises an `OSError exception <system.html#OSError>`_.
  ##
  ## Read the description of the `newOSError proc`_ to learn
  ## how the exception object is created.
  raise newOSError(errorCode, additionalInfo)

{.push stackTrace:off.}
proc osLastError*(): OSErrorCode {.sideEffect.} =
  ## Retrieves the last operating system error code.
  ##
  ## This procedure is useful in the event when an OS call fails. In that case
  ## this procedure will return the error code describing the reason why the
  ## OS call failed. The `OSErrorMsg` procedure can then be used to convert
  ## this code into a string.
  ##
  ## .. warning:: The behaviour of this procedure varies between Windows and POSIX systems.
  ##   On Windows some OS calls can reset the error code to `0` causing this
  ##   procedure to return `0`. It is therefore advised to call this procedure
  ##   immediately after an OS call fails. On POSIX systems this is not a problem.
  ##
  ## See also:
  ## * `osErrorMsg proc`_
  ## * `raiseOSError proc`_
  when weirdTarget:
    discard
  elif defined(windows):
    result = cast[OSErrorCode](getLastError())
  else:
    result = OSErrorCode(errno)
{.pop.}
