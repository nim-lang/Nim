#[
edit this as needed for debugging

]#
import std/macros

const withDebugutils* = defined(nimWithDebugUtils)
const withDebugutilsTimn* = defined(timn_with_compilerutils)

macro defineNoop*(body): untyped =
  result = newStmtList()
  for ai in body:
    var name: NimNode
    var body2: NimNode
    case ai.kind
    of nnkIdent:
      name = ai
      body2 = quote do: discard
    else:
      echo ai.repr
      echo ai.treeRepr
      doAssert ai.len == 2
      name = ai[0]
      body2 = ai[1]
    doAssert name.kind == nnkIdent
    result.add quote do:
      template `name`*(args: varargs[untyped]): `untyped` = `body2`

when withDebugutilsTimn:
  import timn/compilerutils/nimc_interface
  export nimc_interface

from ./options import ConfigRef

type DebugCfg = ref object
  nimWithDebugUtilsRT: bool
  config: ConfigRef

let debugCfg = DebugCfg()

proc ndebugSetConfigExt*(conf: ConfigRef) =
  #[
  nimWithDebugUtilsRT: settable at nim RT (ie, no need to recompile nim for that)
  nimWithDebugUtils: settable at nim CT
  ]#
  debugCfg.config = conf

  # debugCfg.nimWithDebugUtilsRT = conf.isDefined("nimWithDebugUtilsRT")
  # if debugCfg.nimWithDebugUtilsRT:
  #   debugCfg.config = conf

  when withDebugutilsTimn:
    timn_setConfigExt(conf)

template debugGetConfig*(): untyped =
  debugCfg.config

# timnEchoEnabled
template ndebugEchoEnabled*(): bool =
  debugCfg.nimWithDebugUtilsRT = debugGetConfig.isDefined("nimWithDebugUtilsRT") # IMPROVE; compute once
  var ret = debugCfg.nimWithDebugUtilsRT and debugGetConfig.isDefined("timn_enable_echo0b")
  ret
