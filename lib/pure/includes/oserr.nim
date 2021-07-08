# Include file that implements 'osErrorMsg' and friends. Do not import it!

when not declared(os) and not declared(ospaths):
  {.error: "This is an include file for os.nim!".}

when not defined(nimscript):
  var errno {.importc, header: "<errno.h>".}: cint

  proc c_strerror(errnum: cint): cstring {.
    importc: "strerror", header: "<string.h>".}

  when defined(windows):
    import winlean

proc `==`*(err1, err2: OSErrorCode): bool {.borrow.}
proc `$`*(err: OSErrorCode): string {.borrow.}

proc osErrorMsg*(errorCode: OSErrorCode): string =
  ## Converts an OS error code into a human readable string.
  ##
  ## The error code can be retrieved using the `osLastError proc <#osLastError>`_.
  ##
  ## If conversion fails, or `errorCode` is `0` then `""` will be
  ## returned.
  ##
  ## On Windows, the `-d:useWinAnsi` compilation flag can be used to
  ## make this procedure use the non-unicode Win API calls to retrieve the
  ## message.
  ##
  ## See also:
  ## * `raiseOSError proc <#raiseOSError,OSErrorCode,string>`_
  ## * `osLastError proc <#osLastError>`_
  runnableExamples:
    when defined(linux):
      assert osErrorMsg(OSErrorCode(0)) == ""
      assert osErrorMsg(OSErrorCode(1)) == "Operation not permitted"
      assert osErrorMsg(OSErrorCode(2)) == "No such file or directory"

  result = ""
  when defined(nimscript):
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
      result = $c_strerror(errorCode.int32)

proc newOSError*(
  errorCode: OSErrorCode, additionalInfo = ""
): owned(ref OSError) {.noinline.} =
  ## Creates a new `OSError exception <system.html#OSError>`_.
  ##
  ## The `errorCode` will determine the
  ## message, `osErrorMsg proc <#osErrorMsg,OSErrorCode>`_ will be used
  ## to get this message.
  ##
  ## The error code can be retrieved using the `osLastError proc
  ## <#osLastError>`_.
  ##
  ## If the error code is `0` or an error message could not be retrieved,
  ## the message `unknown OS error` will be used.
  ##
  ## See also:
  ## * `osErrorMsg proc <#osErrorMsg,OSErrorCode>`_
  ## * `osLastError proc <#osLastError>`_
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
  ## Read the description of the `newOSError proc <#newOSError,OSErrorCode,string>`_ to learn
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
  ## * `osErrorMsg proc <#osErrorMsg,OSErrorCode>`_
  ## * `raiseOSError proc <#raiseOSError,OSErrorCode,string>`_
  when defined(nimscript):
    discard
  elif defined(windows):
    result = cast[OSErrorCode](getLastError())
  else:
    result = OSErrorCode(errno)
{.pop.}
