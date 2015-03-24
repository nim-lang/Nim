#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Floating-point environment. Handling of floating-point rounding and
## exceptions (overflow, division by zero, etc.).

{.deadCodeElim:on.}

when defined(Posix) and not defined(haiku):
  {.passl: "-lm".}

var
  FE_DIVBYZERO* {.importc, header: "<fenv.h>".}: cint
    ## division by zero
  FE_INEXACT* {.importc, header: "<fenv.h>".}: cint
    ## inexact result
  FE_INVALID* {.importc, header: "<fenv.h>".}: cint
    ## invalid operation
  FE_OVERFLOW* {.importc, header: "<fenv.h>".}: cint
    ## result not representable due to overflow
  FE_UNDERFLOW* {.importc, header: "<fenv.h>".}: cint
    ## result not representable due to underflow
  FE_ALL_EXCEPT* {.importc, header: "<fenv.h>".}: cint
    ## bitwise OR of all supported exceptions
  FE_DOWNWARD* {.importc, header: "<fenv.h>".}: cint
    ## round toward -Inf
  FE_TONEAREST* {.importc, header: "<fenv.h>".}: cint
    ## round to nearest
  FE_TOWARDZERO* {.importc, header: "<fenv.h>".}: cint
    ## round toward 0
  FE_UPWARD* {.importc, header: "<fenv.h>".}: cint
    ## round toward +Inf
  FE_DFL_ENV* {.importc, header: "<fenv.h>".}: cint
    ## macro of type pointer to fenv_t to be used as the argument
    ## to functions taking an argument of type fenv_t; in this
    ## case the default environment will be used

type
  Tfenv* {.importc: "fenv_t", header: "<fenv.h>", final, pure.} =
    object ## Represents the entire floating-point environment. The
           ## floating-point environment refers collectively to any
           ## floating-point status flags and control modes supported
           ## by the implementation.
  Tfexcept* {.importc: "fexcept_t", header: "<fenv.h>", final, pure.} =
    object ## Represents the floating-point status flags collectively,
           ## including any status the implementation associates with the
           ## flags. A floating-point status flag is a system variable
           ## whose value is set (but never cleared) when a floating-point
           ## exception is raised, which occurs as a side effect of
           ## exceptional floating-point arithmetic to provide auxiliary
           ## information. A floating-point control mode is a system variable
           ## whose value may be set by the user to affect the subsequent
           ## behavior of floating-point arithmetic.

proc feclearexcept*(excepts: cint): cint {.importc, header: "<fenv.h>".}
  ## Clear the supported exceptions represented by `excepts`.

proc fegetexceptflag*(flagp: ptr Tfexcept, excepts: cint): cint {.
  importc, header: "<fenv.h>".}
  ## Store implementation-defined representation of the exception flags
  ## indicated by `excepts` in the object pointed to by `flagp`.

proc feraiseexcept*(excepts: cint): cint {.importc, header: "<fenv.h>".}
  ## Raise the supported exceptions represented by `excepts`.

proc fesetexceptflag*(flagp: ptr Tfexcept, excepts: cint): cint {.
  importc, header: "<fenv.h>".}
  ## Set complete status for exceptions indicated by `excepts` according to
  ## the representation in the object pointed to by `flagp`.

proc fetestexcept*(excepts: cint): cint {.importc, header: "<fenv.h>".}
  ## Determine which of subset of the exceptions specified by `excepts` are
  ## currently set.

proc fegetround*(): cint {.importc, header: "<fenv.h>".}
  ## Get current rounding direction.

proc fesetround*(roundingDirection: cint): cint {.importc, header: "<fenv.h>".}
  ## Establish the rounding direction represented by `roundingDirection`.

proc fegetenv*(envp: ptr Tfenv): cint {.importc, header: "<fenv.h>".}
  ## Store the current floating-point environment in the object pointed
  ## to by `envp`.

proc feholdexcept*(envp: ptr Tfenv): cint {.importc, header: "<fenv.h>".}
  ## Save the current environment in the object pointed to by `envp`, clear
  ## exception flags and install a non-stop mode (if available) for all
  ## exceptions.

proc fesetenv*(a1: ptr Tfenv): cint {.importc, header: "<fenv.h>".}
  ## Establish the floating-point environment represented by the object
  ## pointed to by `envp`.

proc feupdateenv*(envp: ptr Tfenv): cint {.importc, header: "<fenv.h>".}
  ## Save current exceptions in temporary storage, install environment
  ## represented by object pointed to by `envp` and raise exceptions
  ## according to saved exceptions.

var FP_RADIX_INTERNAL {. importc: "FLT_RADIX" header: "<float.h>" .} : int

template fpRadix* : int = FP_RADIX_INTERNAL
  ## The (integer) value of the radix used to represent any floating
  ## point type on the architecture used to build the program.

var FLT_MANT_DIG {. importc: "FLT_MANT_DIG" header: "<float.h>" .} : int
var FLT_DIG {. importc: "FLT_DIG" header: "<float.h>" .} : int
var FLT_MIN_EXP {. importc: "FLT_MIN_EXP" header: "<float.h>" .} : int
var FLT_MAX_EXP {. importc: "FLT_MAX_EXP" header: "<float.h>" .} : int
var FLT_MIN_10_EXP {. importc: "FLT_MIN_10_EXP" header: "<float.h>" .} : int
var FLT_MAX_10_EXP {. importc: "FLT_MAX_10_EXP" header: "<float.h>" .} : int
var FLT_MIN {. importc: "FLT_MIN" header: "<float.h>" .} : cfloat
var FLT_MAX {. importc: "FLT_MAX" header: "<float.h>" .} : cfloat
var FLT_EPSILON {. importc: "FLT_EPSILON" header: "<float.h>" .} : cfloat

var DBL_MANT_DIG {. importc: "DBL_MANT_DIG" header: "<float.h>" .} : int
var DBL_DIG {. importc: "DBL_DIG" header: "<float.h>" .} : int
var DBL_MIN_EXP {. importc: "DBL_MIN_EXP" header: "<float.h>" .} : int
var DBL_MAX_EXP {. importc: "DBL_MAX_EXP" header: "<float.h>" .} : int
var DBL_MIN_10_EXP {. importc: "DBL_MIN_10_EXP" header: "<float.h>" .} : int
var DBL_MAX_10_EXP {. importc: "DBL_MAX_10_EXP" header: "<float.h>" .} : int
var DBL_MIN {. importc: "DBL_MIN" header: "<float.h>" .} : cdouble
var DBL_MAX {. importc: "DBL_MAX" header: "<float.h>" .} : cdouble
var DBL_EPSILON {. importc: "DBL_EPSILON" header: "<float.h>" .} : cdouble

template mantissaDigits*(T : typedesc[float32]) : int = FLT_MANT_DIG
  ## Number of digits (in base ``floatingPointRadix``) in the mantissa
  ## of 32-bit floating-point numbers.
template digits*(T : typedesc[float32]) : int = FLT_DIG
  ## Number of decimal digits that can be represented in a
  ## 32-bit floating-point type without losing precision.
template minExponent*(T : typedesc[float32]) : int = FLT_MIN_EXP
  ## Minimum (negative) exponent for 32-bit floating-point numbers.
template maxExponent*(T : typedesc[float32]) : int = FLT_MAX_EXP
  ## Maximum (positive) exponent for 32-bit floating-point numbers.
template min10Exponent*(T : typedesc[float32]) : int = FLT_MIN_10_EXP
  ## Minimum (negative) exponent in base 10 for 32-bit floating-point
  ## numbers.
template max10Exponent*(T : typedesc[float32]) : int = FLT_MAX_10_EXP
  ## Maximum (positive) exponent in base 10 for 32-bit floating-point
  ## numbers.
template minimumPositiveValue*(T : typedesc[float32]) : float32 = FLT_MIN
  ## The smallest positive (nonzero) number that can be represented in a
  ## 32-bit floating-point type.
template maximumPositiveValue*(T : typedesc[float32]) : float32 = FLT_MAX
  ## The largest positive number that can be represented in a 32-bit
  ## floating-point type.
template epsilon*(T : typedesc[float32]): float32 = FLT_EPSILON
  ## The difference between 1.0 and the smallest number greater than
  ## 1.0 that can be represented in a 32-bit floating-point type.

template mantissaDigits*(T : typedesc[float64]) : int = DBL_MANT_DIG
  ## Number of digits (in base ``floatingPointRadix``) in the mantissa
  ## of 64-bit floating-point numbers.
template digits*(T : typedesc[float64]) : int = DBL_DIG
  ## Number of decimal digits that can be represented in a
  ## 64-bit floating-point type without losing precision.
template minExponent*(T : typedesc[float64]) : int = DBL_MIN_EXP
  ## Minimum (negative) exponent for 64-bit floating-point numbers.
template maxExponent*(T : typedesc[float64]) : int = DBL_MAX_EXP
  ## Maximum (positive) exponent for 64-bit floating-point numbers.
template min10Exponent*(T : typedesc[float64]) : int = DBL_MIN_10_EXP
  ## Minimum (negative) exponent in base 10 for 64-bit floating-point
  ## numbers.
template max10Exponent*(T : typedesc[float64]) : int = DBL_MAX_10_EXP
  ## Maximum (positive) exponent in base 10 for 64-bit floating-point
  ## numbers.
template minimumPositiveValue*(T : typedesc[float64]) : float64 = DBL_MIN
  ## The smallest positive (nonzero) number that can be represented in a
  ## 64-bit floating-point type.
template maximumPositiveValue*(T : typedesc[float64]) : float64 = DBL_MAX
  ## The largest positive number that can be represented in a 64-bit
  ## floating-point type.
template epsilon*(T : typedesc[float64]): float64 = DBL_EPSILON
  ## The difference between 1.0 and the smallest number greater than
  ## 1.0 that can be represented in a 64-bit floating-point type.
