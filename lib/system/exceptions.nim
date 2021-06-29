const NimStackTraceMsgs =
  when defined(nimHasStacktraceMsgs): compileOption("stacktraceMsgs")
  else: false

type
  RootEffect* {.compilerproc.} = object of RootObj ## \
    ## Base effect class.
    ##
    ## Each effect should inherit from `RootEffect` unless you know what
    ## you're doing.
  TimeEffect* = object of RootEffect   ## Time effect.
  IOEffect* = object of RootEffect     ## IO effect.
  ReadIOEffect* = object of IOEffect   ## Effect describing a read IO operation.
  WriteIOEffect* = object of IOEffect  ## Effect describing a write IO operation.
  ExecIOEffect* = object of IOEffect   ## Effect describing an executing IO operation.

  StackTraceEntry* = object ## In debug mode exceptions store the stack trace that led
                            ## to them. A `StackTraceEntry` is a single entry of the
                            ## stack trace.
    procname*: cstring      ## Name of the proc that is currently executing.
    line*: int              ## Line number of the proc that is currently executing.
    filename*: cstring      ## Filename of the proc that is currently executing.
    when NimStackTraceMsgs:
      frameMsg*: string     ## When a stacktrace is generated in a given frame and
                            ## rendered at a later time, we should ensure the stacktrace
                            ## data isn't invalidated; any pointer into PFrame is
                            ## subject to being invalidated so shouldn't be stored.
    when defined(nimStackTraceOverride):
      programCounter*: uint ## Program counter - will be used to get the rest of the info,
                            ## when `$` is called on this type. We can't use
                            ## "cuintptr_t" in here.
      procnameStr*, filenameStr*: string ## GC-ed alternatives to "procname" and "filename"

  Exception* {.compilerproc, magic: "Exception".} = object of RootObj ## \
    ## Base exception class.
    ##
    ## Each exception has to inherit from `Exception`. See the full `exception
    ## hierarchy <manual.html#exception-handling-exception-hierarchy>`_.
    parent*: ref Exception ## Parent exception (can be used as a stack).
    name*: cstring         ## The exception's name is its Nim identifier.
                           ## This field is filled automatically in the
                           ## `raise` statement.
    msg* {.exportc: "message".}: string ## The exception's message. Not
                                        ## providing an exception message
                                        ## is bad style.
    when defined(js):
      trace: string
    else:
      trace: seq[StackTraceEntry]
    up: ref Exception # used for stacking exceptions. Not exported!

  Defect* = object of Exception ## \
    ## Abstract base class for all exceptions that Nim's runtime raises
    ## but that are strictly uncatchable as they can also be mapped to
    ## a `quit` / `trap` / `exit` operation.

  CatchableError* = object of Exception ## \
    ## Abstract class for all exceptions that are catchable.
  IOError* = object of CatchableError ## \
    ## Raised if an IO error occurred.
  EOFError* = object of IOError ## \
    ## Raised if an IO "end of file" error occurred.
  OSError* = object of CatchableError ## \
    ## Raised if an operating system service failed.
    errorCode*: int32 ## OS-defined error code describing this error.
  LibraryError* = object of OSError ## \
    ## Raised if a dynamic library could not be loaded.
  ResourceExhaustedError* = object of CatchableError ## \
    ## Raised if a resource request could not be fulfilled.
  ArithmeticDefect* = object of Defect ## \
    ## Raised if any kind of arithmetic error occurred.
  DivByZeroDefect* = object of ArithmeticDefect ## \
    ## Raised for runtime integer divide-by-zero errors.

  OverflowDefect* = object of ArithmeticDefect ## \
    ## Raised for runtime integer overflows.
    ##
    ## This happens for calculations whose results are too large to fit in the
    ## provided bits.
  AccessViolationDefect* = object of Defect ## \
    ## Raised for invalid memory access errors
  AssertionDefect* = object of Defect ## \
    ## Raised when assertion is proved wrong.
    ##
    ## Usually the result of using the `assert() template
    ## <assertions.html#assert.t,untyped,string>`_.
  ValueError* = object of CatchableError ## \
    ## Raised for string and object conversion errors.
  KeyError* = object of ValueError ## \
    ## Raised if a key cannot be found in a table.
    ##
    ## Mostly used by the `tables <tables.html>`_ module, it can also be raised
    ## by other collection modules like `sets <sets.html>`_ or `strtabs
    ## <strtabs.html>`_.
  OutOfMemDefect* = object of Defect ## \
    ## Raised for unsuccessful attempts to allocate memory.
  IndexDefect* = object of Defect ## \
    ## Raised if an array index is out of bounds.

  FieldDefect* = object of Defect ## \
    ## Raised if a record field is not accessible because its discriminant's
    ## value does not fit.
  RangeDefect* = object of Defect ## \
    ## Raised if a range check error occurred.
  StackOverflowDefect* = object of Defect ## \
    ## Raised if the hardware stack used for subroutine calls overflowed.
  ReraiseDefect* = object of Defect ## \
    ## Raised if there is no exception to reraise.
  ObjectAssignmentDefect* = object of Defect ## \
    ## Raised if an object gets assigned to its parent's object.
  ObjectConversionDefect* = object of Defect ## \
    ## Raised if an object is converted to an incompatible object type.
    ## You can use `of` operator to check if conversion will succeed.
  FloatingPointDefect* = object of Defect ## \
    ## Base class for floating point exceptions.
  FloatInvalidOpDefect* = object of FloatingPointDefect ## \
    ## Raised by invalid operations according to IEEE.
    ##
    ## Raised by `0.0/0.0`, for example.
  FloatDivByZeroDefect* = object of FloatingPointDefect ## \
    ## Raised by division by zero.
    ##
    ## Divisor is zero and dividend is a finite nonzero number.
  FloatOverflowDefect* = object of FloatingPointDefect ## \
    ## Raised for overflows.
    ##
    ## The operation produced a result that exceeds the range of the exponent.
  FloatUnderflowDefect* = object of FloatingPointDefect ## \
    ## Raised for underflows.
    ##
    ## The operation produced a result that is too small to be represented as a
    ## normal number.
  FloatInexactDefect* = object of FloatingPointDefect ## \
    ## Raised for inexact results.
    ##
    ## The operation produced a result that cannot be represented with infinite
    ## precision -- for example: `2.0 / 3.0, log(1.1)`
    ##
    ## **Note**: Nim currently does not detect these!
  DeadThreadDefect* = object of Defect ## \
    ## Raised if it is attempted to send a message to a dead thread.
  NilAccessDefect* = object of Defect ## \
    ## Raised on dereferences of `nil` pointers.
    ##
    ## This is only raised if the `segfaults module <segfaults.html>`_ was imported!

  ArithmeticError* {.deprecated: "See corresponding Defect".} = ArithmeticDefect
  DivByZeroError* {.deprecated: "See corresponding Defect".} = DivByZeroDefect
  OverflowError* {.deprecated: "See corresponding Defect".} = OverflowDefect
  AccessViolationError* {.deprecated: "See corresponding Defect".} = AccessViolationDefect
  AssertionError* {.deprecated: "See corresponding Defect".} = AssertionDefect
  OutOfMemError* {.deprecated: "See corresponding Defect".} = OutOfMemDefect
  IndexError* {.deprecated: "See corresponding Defect".} = IndexDefect

  FieldError* {.deprecated: "See corresponding Defect".} = FieldDefect
  RangeError* {.deprecated: "See corresponding Defect".} = RangeDefect
  StackOverflowError* {.deprecated: "See corresponding Defect".} = StackOverflowDefect
  ReraiseError* {.deprecated: "See corresponding Defect".} = ReraiseDefect
  ObjectAssignmentError* {.deprecated: "See corresponding Defect".} = ObjectAssignmentDefect
  ObjectConversionError* {.deprecated: "See corresponding Defect".} = ObjectConversionDefect
  FloatingPointError* {.deprecated: "See corresponding Defect".} = FloatingPointDefect
  FloatInvalidOpError* {.deprecated: "See corresponding Defect".} = FloatInvalidOpDefect
  FloatDivByZeroError* {.deprecated: "See corresponding Defect".} = FloatDivByZeroDefect
  FloatOverflowError* {.deprecated: "See corresponding Defect".} = FloatOverflowDefect
  FloatUnderflowError* {.deprecated: "See corresponding Defect".} = FloatUnderflowDefect
  FloatInexactError* {.deprecated: "See corresponding Defect".} = FloatInexactDefect
  DeadThreadError* {.deprecated: "See corresponding Defect".} = DeadThreadDefect
  NilAccessError* {.deprecated: "See corresponding Defect".} = NilAccessDefect
