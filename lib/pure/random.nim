#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

##   Constructive mathematics is naturally typed. -- Simon Thompson
##
## Basic random number routines for Nim.
## This module is available for the `JavaScript target
## <backends.html#the-javascript-target>`_.

include "system/inclrtl"

{.push debugger:off .} # the user does not want to trace a part
                       # of the standard library!

{.push checks:off, line_dir:off, stack_trace:off.}

when not defined(js) and not defined(nimscript):
  import times

proc random*(max: int): int {.benign.}
  ## Returns a random number in the range 0..max-1. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount.

proc random*(max: float): float {.benign.}
  ## Returns a random number in the range 0..<max. The sequence of
  ## random number is always the same, unless `randomize` is called
  ## which initializes the random number generator with a "random"
  ## number, i.e. a tickcount. This has a 16-bit resolution on windows
  ## and a 48-bit resolution on other platforms.

when not defined(nimscript):
  proc randomize*() {.benign.}
    ## Initializes the random number generator with a "random"
    ## number, i.e. a tickcount. Note: Does nothing for the JavaScript target,
    ## as JavaScript does not support this. Nor does it work for NimScript.

proc randomize*(seed: int) {.benign.}
  ## Initializes the random number generator with a specific seed.
  ## Note: Does nothing for the JavaScript target,
  ## as JavaScript does not support this.

{.push noSideEffect.}
when not defined(JS):
  # C procs:
  when defined(vcc) and false:
    # The "secure" random, available from Windows XP
    # https://msdn.microsoft.com/en-us/library/sxtz2fa8.aspx
    # Present in some variants of MinGW but not enough to justify
    # `when defined(windows)` yet
    proc rand_s(val: var cuint) {.importc: "rand_s", header: "<stdlib.h>".}
    # To behave like the normal version
    proc rand(): cuint = rand_s(result)
  else:
    proc srand(seed: cint) {.importc: "srand", header: "<stdlib.h>".}
    proc rand(): cint {.importc: "rand", header: "<stdlib.h>".}

  when not defined(windows):
    proc srand48(seed: clong) {.importc: "srand48", header: "<stdlib.h>".}
    proc drand48(): float {.importc: "drand48", header: "<stdlib.h>".}
    proc random(max: float): float =
      result = drand48() * max
  else:
    when defined(vcc): # Windows with Visual C
      proc random(max: float): float =
        # we are hardcoding this because
        # importc-ing macros is extremely problematic
        # and because the value is publicly documented
        # on MSDN and very unlikely to change
        # See https://msdn.microsoft.com/en-us/library/296az74e.aspx
        const rand_max = 4294967295 # UINT_MAX
        result = (float(rand()) / float(rand_max)) * max
      proc randomize() = discard
      proc randomize(seed: int) = discard
    else: # Windows with another compiler
      proc random(max: float): float =
        # we are hardcoding this because
        # importc-ing macros is extremely problematic
        # and because the value is publicly documented
        # on MSDN and very unlikely to change
        const rand_max = 32767
        result = (float(rand()) / float(rand_max)) * max

  when not defined(vcc): # the above code for vcc uses `discard` instead
    # this is either not Windows or is Windows without vcc
    when not defined(nimscript):
      proc randomize() =
        randomize(cast[int](epochTime()))
    proc randomize(seed: int) =
      srand(cint(seed)) # rand_s doesn't use srand
      when declared(srand48): srand48(seed)

  proc random(max: int): int =
    result = int(rand()) mod max
else:
  proc mathrandom(): float {.importc: "Math.random", nodecl.}
  proc random(max: int): int =
    result = int(floor(mathrandom() * float(max)))
  proc random(max: float): float =
    result = float(mathrandom() * float(max))
  proc randomize() = discard
  proc randomize(seed: int) = discard

{.pop.}

proc random*[T](x: Slice[T]): T =
  ## For a slice `a .. b` returns a value in the range `a .. b-1`.
  result = random(x.b - x.a) + x.a

proc random*[T](a: openArray[T]): T =
  ## returns a random element from the openarray `a`.
  result = a[random(a.low..a.len)]

{.pop.}
{.pop.}

when isMainModule and not defined(JS):
  block: # random tests
    proc gettime(dummy: ptr cint): cint {.importc: "time", header: "<time.h>".}
    # Verifies random seed initialization.
    let seed = gettime(nil)
    randomize(seed)
    const SIZE = 10
    var buf : array[0..SIZE, int]
    # Fill the buffer with random values
    for i in 0..SIZE-1:
      buf[i] = random(high(int))
    # Check that the second random calls are the same for each position.
    randomize(seed)
    for i in 0..SIZE-1:
      assert buf[i] == random(high(int)), "non deterministic random seeding"

    when not defined(testing):
      echo "random values equal after reseeding"
