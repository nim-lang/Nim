##[
Utilities to help with debugging nim compiler.

Experimental API, subject to change.
]##

#[
## example
useful debugging flags:
--stacktrace -d:debug -d:nimDebugUtils
 nim c -o:bin/nim_temp --stacktrace -d:debug -d:nimDebugUtils compiler/nim

## future work
* expose and improve astalgo.debug, replacing it by std/prettyprints,
  refs https://github.com/nim-lang/RFCs/issues/385
]#

import options
import std/wrapnils
export wrapnils
  # allows using things like: `?.n.sym.typ.len`

import std/stackframes
export stackframes
  # allows using things like: `setFrameMsg c.config$n.info & " " & $n.kind`
  # which doesn't log, but augments stacktrace with side channel information

var conf0: ConfigRef

proc onNewConfigRef*(conf: ConfigRef) {.inline.} =
  ## Caches `conf`, which can be retrieved with `getConfigRef`.
  ## This avoids having to forward `conf` all the way down the call chain to
  ## procs that need it during a debugging session.
  conf0 = conf

proc getConfigRef*(): ConfigRef =
  ## nil, if -d:nimDebugUtils wasn't specified
  result = conf0

proc isCompilerDebug*(): bool =
  ##[
  Provides a simple way for user code to enable/disable logging in the compiler
  in a granular way. This can then be used in the compiler as follows:
  ```nim
  if isCompilerDebug():
    echo ?.n.sym.typ.len
  ```
  ]##
  runnableExamples:
    proc main =
      echo 2
      {.define(nimCompilerDebug).}
      echo 3.5 # code section in which `isCompilerDebug` will be true
      {.undef(nimCompilerDebug).}
      echo 'x'
  conf0.isDefined("nimCompilerDebug")
