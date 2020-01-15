proc compileOption*(option: string): bool {.
  magic: "CompileOption", noSideEffect.}
  ## Can be used to determine an `on|off` compile-time option. Example:
  ##
  ## .. code-block:: Nim
  ##   when compileOption("floatchecks"):
  ##     echo "compiled with floating point NaN and Inf checks"

proc compileOption*(option, arg: string): bool {.
  magic: "CompileOptionArg", noSideEffect.}
  ## Can be used to determine an enum compile-time option. Example:
  ##
  ## .. code-block:: Nim
  ##   when compileOption("opt", "size") and compileOption("gc", "boehm"):
  ##     echo "compiled with optimization for size and uses Boehm's GC"

const
  notJSnotNims* = not defined(js) and not defined(nimscript)
  hostOS* {.magic: "HostOS".}: string = ""
    ## A string that describes the host operating system.
    ##
    ## Possible values:
    ## `"windows"`, `"macosx"`, `"linux"`, `"netbsd"`, `"freebsd"`,
    ## `"openbsd"`, `"solaris"`, `"aix"`, `"haiku"`, `"standalone"`.
  hasAlloc* = (hostOS != "standalone" or not defined(nogc)) and not defined(nimscript)
  hasThreadSupport* = compileOption("threads") and not defined(nimscript)
  usesDestructors* = defined(gcDestructors) or defined(gcHooks)
