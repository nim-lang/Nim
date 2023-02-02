#
#
#            Nim's Runtime Library
#        (c) Copyright 2022 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#


## The `std/oserrors` module implements OS error reporting.

type
  OSErrorCode* = distinct int32 ## Specifies an OS Error Code.

when not defined(nimscript):
  when defined(windows):
    import winlean
    when defined(nimPreviewSlimSystem):
      import std/widestrs
  else:
    var errno {.importc, header: "<errno.h>".}: cint

    proc c_strerror(errnum: cint): cstring {.
      importc: "strerror", header: "<string.h>".}

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
  ## See also:
  ## * `raiseOSError proc`_
  ## * `osLastError proc`_
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
      var msgbuf: WideCString
      if formatMessageW(0x00000100 or 0x00001000 or 0x00000200,
                      nil, errorCode.int32, 0, addr(msgbuf), 0, nil) != 0'i32:
        result = $msgbuf
        if msgbuf != nil: localFree(cast[pointer](msgbuf))
  else:
    if errorCode != OSErrorCode(0'i32):
      result = $c_strerror(errorCode.int32)

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
  result = (ref OSError)(errorCode: errorCode.int32, msg: osErrorMsg(errorCode))
  if additionalInfo.len > 0:
    if result.msg.len > 0 and result.msg[^1] != '\n': result.msg.add '\n'
    result.msg.add "Additional info: "
    result.msg.add additionalInfo
      # don't add trailing `.` etc, which negatively impacts "jump to file" in IDEs.
  if result.msg == "":
    result.msg = "unknown OS error"

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
  when defined(nimscript):
    discard
  elif defined(windows):
    result = cast[OSErrorCode](getLastError())
  else:
    result = OSErrorCode(errno)
{.pop.}
