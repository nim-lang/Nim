## Exception and effect types used in Nim code.

type
  TimeEffect* = object of RootEffect   ## Time effect.
  IOEffect* = object of RootEffect     ## IO effect.
  ReadIOEffect* = object of IOEffect   ## Effect describing a read IO operation.
  WriteIOEffect* = object of IOEffect  ## Effect describing a write IO operation.
  ExecIOEffect* = object of IOEffect   ## Effect describing an executing IO operation.

type
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

when not defined(nimPreviewSlimSystem):
  type
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
