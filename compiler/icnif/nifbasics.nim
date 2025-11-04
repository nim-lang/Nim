import std/[tables]
import ".." / [ast, lineinfos, msgs, options]
import "../../dist/nimony/src/gear2" / modnames

proc modname(moduleToNifSuffix: var Table[FileIndex, string]; module: PSym; conf: ConfigRef): string =
  assert module.kind == skModule
  let idx: FileIndex = module.position.FileIndex
  # copied from ../nifgen.nim
  result = moduleToNifSuffix.getOrDefault(idx)
  if result.len == 0:
    let fp = toFullPath(conf, idx)
    result = moduleSuffix(fp, cast[seq[string]](conf.searchPaths))
    moduleToNifSuffix[idx] = result
    #echo result, " -> ", fp

proc toNifSym*(sym: PSym; moduleToNifSuffix: var Table[FileIndex, string]; conf: ConfigRef): string =
  let module = sym.originatingModule

  result = sym.name.s & '.' & $sym.disamb & '.' & modname(moduleToNifSuffix, module, conf)
