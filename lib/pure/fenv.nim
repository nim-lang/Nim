#
#
#            Nim's Runtime Library
#        (c) Copyright 2014 Andreas Rumpf
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
