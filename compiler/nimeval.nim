#
#
#           The Nimrod Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## exposes the Nimrod VM to clients.

import
  ast, modules, passes, passaux, condsyms,
  options, nimconf, lists, sem, semdata, llstream, vm

proc execute*(program: string) =
  passes.gIncludeFile = includeModule
  passes.gImportModule = importModule
  initDefines()
  LoadConfigs(DefaultConfig)

  initDefines()
  DefineSymbol("nimrodvm")
  when hasFFI: DefineSymbol("nimffi")
  registerPass(verbosePass)
  registerPass(semPass)
  registerPass(vmPass)

  appendStr(searchPaths, options.libpath)
  compileSystemModule()
  var m = makeStdinModule()
  incl(m.flags, sfMainModule)
  processModule(m, LLStreamOpen(program), nil)
