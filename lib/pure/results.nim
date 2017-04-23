import typetraits, strutils

type
  Result*[T] = object
    ## Either a value or an error.
    case isSuccess*: bool:
    of true:
      value*: T
    of false:
      error*: ref Exception
      backtrace*: BacktraceFrame

  BacktraceFrame* = ref object
    ## This objects represents
    filename: string
    line: int
    procname: string
    next: BacktraceFrame

proc isError*[T](r: Result[T]): bool =
  ## Does ``r`` contain error?
  return not r.isSuccess

proc just*[T](r: T): Result[T] =
  ## Return successful Result[T] that contains value ``r``.
  when T is void:
    Result[T](isSuccess: true)
  else:
    Result[T](isSuccess: true, value: r)

proc just*(): Result[void] =
  ## Return successful Result[void] that contains nothing.
  Result[void](isSuccess: true)

proc fillExceptionName[Exc: ref Exception](exc: Exc) =
  ## This normally filled by ``raise``, but most exceptions in ``Result`` are not from ``raise``.
  when not (Exc is ref Exception):
    if exc.name == nil:
      exc.name = name(type(exc))

proc error*[T; Exc: ref Exception](typename: typedesc[T], theError: Exc): Result[T] =
  ## Return Result[T] that contains error ``theError``.
  assert theError != nil
  fillExceptionName(theError)
  Result[T](isSuccess: false, error: theError)

proc error*[T; Exc: ref Exception](typename: typedesc[T], theError: Exc, backtrace: BacktraceFrame): Result[T] =
  ## Return Result[T] that contains error ``theError`` and backtrace ``backtrace``.
  assert theError != nil
  fillExceptionName(theError)
  Result[T](isSuccess: false, error: theError, backtrace: backtrace)

proc error*[T](typename: typedesc[T], theError: string): Result[T] =
  ## Return Result[T] that contains ``Exception`` with message ``theError``.
  assert theError != nil
  Result[T](isSuccess: false, error: newException(Exception, theError))

proc get*[T](r: Result[T]): T =
  ## Return value contained in ``r``. If ``r`` contains error, raise it.
  if r.isSuccess:
    when T is not void:
      return r.value
  else:
    raise r.error

proc `$`*[T](r: Result[T]): string =
  if r.isSuccess:
    when compiles($r.value):
      return "just(" & $(r.value) & ")"
    else:
      return "just(...)"
  else:
    let err = r.error
    return "error(" & (if err == nil or err.msg == nil: "nil" else: err.msg) & ")"

template currentFrameBacktrace*(depth = 0, nextFrame = nil): BacktraceFrame =
  ## Returns single backtrace frame containg information about current ``proc``.
  ##
  ## Set ``depth`` to the number of nested templates to skip before looking for line information.
  let frame = getFrame()
  let info = instantiationInfo(-depth - 2)
  BacktraceFrame(filename: info.filename, line: info.line, procname: $frame.procname, next: nextFrame)

proc flatten*[T](r: Result[Result[T]]) =
  ## Flatten Result[Result[T]] into Result[T]
  if r.isSuccess:
    return r.get
  else:
    return error(T, r.error, r.backtrace)

template catchError*(e: untyped): untyped =
  ## Converts exceptions from `e` into error(...) and other results into just(e).
  try:
    just(e)
  except:
    error(type(e), getCurrentException(), currentFrameBacktrace())

# Printing backtrace

proc formatBacktrace*(trace: BacktraceFrame): string =
  ## Return multiline representation of ``trace``.
  if trace == nil:
    return ""
  let fn = "$1($2)" % [trace.filename.split("/")[^1], $trace.line]
  let line = fn & repeat(' ', max(24 - fn.len, 0)) & " " & (trace.procname)
  line & "\n" & formatBacktrace(trace.next)

proc printError*(res: Result) =
  ## Print error contained in Result ``res``.
  if res.isSuccess:
    stderr.writeLine "(no error)"
    return

  if res.error != nil:
    stderr.writeLine res.error.getStackTrace

  if res.backtrace != nil:
    stderr.writeLine "Backtrace:"
    stderr.writeLine formatBacktrace(res.backtrace)

  if res.error == nil:
    stderr.writeLine "Error: (nil)"
  else:
    stderr.writeLine "Error: " & (if res.error.msg == nil: "nil" else: $res.error.msg) & " [" & (if res.error.name != nil: $res.error.name else: "Exception") & "]"
