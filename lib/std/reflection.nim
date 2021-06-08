##[
This module implements compile time reflection API's.

It is supported in all backends.
Experimental API, subject to change.
]##

func moduleSymbols*(module: NimNode, enablePrivate = false): NimNode {.magic: "ModuleSymbols".} =
  ## Returns a sequence of `module`'s symbols. When `enablePrivate == true`,
  ## private symbols are also returned.
  runnableExamples("-d:foobar"):
    import std/macros
    macro callByName(module: typed, name: static string, args: varargs[untyped]): untyped =
      # finds the 1st symbol with name `name` from `module` and calls it with `args`.
      result = newStmtList()
      for si in moduleSymbols(module):
        if si.strVal == name:
          result.add quote do: `si`(`args`)
    doAssert callByName(system, "defined", foobar)

  runnableExamples:
    import std/[macros, sugar, strutils]
    macro findSymbolNames(module: typed, kinds: static set[NimSymKind]): seq[string] =
      # Returns all the symbol names from `module` of kind in `kinds`.
      result = newLit: collect:
        for si in moduleSymbols(module):
          if si.symKind in kinds: si.strVal
    doAssert "NimMinor" in findSymbolNames(system, {nskConst})

    macro findProcs(module: typed, returnTypeKinds: static set[NimTypeKind]): untyped =
      # returns a listing of `procName: lineInfo` for procs with a given return type kind
      var ret = ""
      for si in moduleSymbols(module):
        if si.symKind in {nskProc}:
          let t = si.getType
          if t[1].typeKind in returnTypeKinds:
            ret.add si.strVal & ": " & si.getImpl.lineInfo & "\n"
      result = newLit ret
    const listing = findProcs(system, {ntyVoid})
    doAssert "addQuoted" in listing
