import ast, options, lineinfos, pathutils, msgs, modulegraphs, packages

proc skipCodegen*(config: ConfigRef; n: PNode): bool {.inline.} =
  # can be used by codegen passes to determine whether they should do
  # something with `n`. Currently, this ignores `n` and uses the global
  # error count instead.
  result = config.errorCounter > 0

proc resolveMod*(conf: ConfigRef; module, relativeTo: string): FileIndex =
  let fullPath = findModule(conf, module, relativeTo)
  if fullPath.isEmpty:
    result = InvalidFileIdx
  else:
    result = fileInfoIdx(conf, fullPath)

proc prepareConfigNotes*(graph: ModuleGraph; module: PSym) =
  # don't be verbose unless the module belongs to the main package:
  if graph.config.belongsToProjectPackage(module):
    graph.config.notes = graph.config.mainPackageNotes
  else:
    if graph.config.mainPackageNotes == {}: graph.config.mainPackageNotes = graph.config.notes
    graph.config.notes = graph.config.foreignPackageNotes

proc moduleHasChanged*(graph: ModuleGraph; module: PSym): bool {.inline.} =
  result = true
  #module.id >= 0 or isDefined(graph.config, "nimBackendAssumesChange")
