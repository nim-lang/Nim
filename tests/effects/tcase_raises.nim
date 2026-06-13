from std/os import osLastError, osErrorMsg, OSErrorCode, raiseOSError,
                   newOSError, `==`

{.push raises: [].}

const
  EPERM* = OSErrorCode(1)
  ECONNABORTED* = OSErrorCode(53)
  ETIMEDOUT* = OSErrorCode(60)
  ENOTCONN* = OSErrorCode(107)
  EMFILE* = OSErrorCode(24)
  ENFILE* = OSErrorCode(23)
  ENOBUFS* = OSErrorCode(55)
  ENOMEM* = OSErrorCode(12)

type
  AsyncError* = object of CatchableError
  TransportErrorBase* = object of AsyncError
  TransportOsError* = object of TransportErrorBase
    code*: OSErrorCode
  TransportTooManyError* = object of TransportErrorBase
  TransportAbortedError* = object of TransportErrorBase

template getConnectionAbortedError*(
           code: OSErrorCode
         ): ref TransportAbortedError =
  let msg =
    case code
    of OSErrorCode(0), ECONNABORTED:
      "[ECONNABORTED] Connection has been aborted before being accepted"
    of EPERM:
      "[EPERM] Firewall rules forbid connection"
    of ETIMEDOUT:
      "[ETIMEDOUT] Operation has been timed out"
    of ENOTCONN:
      "[ENOTCONN] Transport endpoint is not connected"
    else:
      "[" & $int(code) & "] Connection has been aborted"
  newException(TransportAbortedError, msg)

template getTransportTooManyError*(
           code = OSErrorCode(0)
         ): ref TransportTooManyError =
  let msg =
    case code
    of OSErrorCode(0):
      "Too many open transports"
    of EMFILE:
      "[EMFILE] Too many open files in the process"
    of ENFILE:
      "[ENFILE] Too many open files in system"
    of ENOBUFS:
      "[ENOBUFS] No buffer space available"
    of ENOMEM:
      "[ENOMEM] Not enough memory availble"
    else:
      "[" & $int(code) & "] Too many open transports"
  newException(TransportTooManyError, msg)

template getTransportError*(ecode: OSErrorCode): untyped =
  case ecode
  of ECONNABORTED, EPERM, ETIMEDOUT, ENOTCONN:
    getConnectionAbortedError(ecode)
  of EMFILE, ENFILE, ENOBUFS, ENOMEM:
    getTransportTooManyError(ecode)
  else:
    (ref TransportOsError)(code: ecode,
                           msg: "(" & $int(ecode) & ") " & osErrorMsg(ecode))

proc raiseTransportError*(err: OSErrorCode) {.
     raises: [TransportAbortedError, TransportTooManyError, TransportOsError],
     noreturn.} =
  ## Raises transport specific OS error.
  raise getTransportError(err)