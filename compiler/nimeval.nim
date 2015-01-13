#
#
#           The Nim Compiler
#        (c) Copyright 2013 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## exposes the Nim VM to clients.

import
  ast, modules, passes, passaux, condsyms, 
  options, nimconf, lists, sem, semdata, llstream, vm

proc execute*(program: string) =
  passes.gIncludeFile = includeModule
  passes.gImportModule = importModule
  initDefines()
  loadConfigs(DefaultConfig)

  initDefines()
  defineSymbol("nimrodvm")
  when hasFFI: defineSymbol("nimffi")
  registerPass(verbosePass)
  registerPass(semPass)
  registerPass(evalPass)

  appendStr(searchPaths, options.libpath)
  compileSystemModule()
  var m = makeStdinModule()
  incl(m.flags, sfMainModule)
  processModule(m, llStreamOpen(program), nil)
