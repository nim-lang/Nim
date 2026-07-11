import std/[json, macros]

template dynlibmeta(value: static[string]) {.pragma.}

proc abiType(n: NimNode): tuple[nimName, cName: string] =
  if n.kind == nnkEmpty:
    return ("", "void")
  if n.kind != nnkSym:
    error("dynexport only supports C scalar types and pointer", n)
  case n.strVal
  of "cchar": ("cchar", "char")
  of "cschar": ("cschar", "signed char")
  of "cshort": ("cshort", "short")
  of "cint": ("cint", "int")
  of "clong": ("clong", "long")
  of "clonglong": ("clonglong", "long long")
  of "cuchar": ("cuchar", "unsigned char")
  of "cushort": ("cushort", "unsigned short")
  of "cuint": ("cuint", "unsigned int")
  of "culong": ("culong", "unsigned long")
  of "culonglong": ("culonglong", "unsigned long long")
  of "cfloat": ("cfloat", "float")
  of "cdouble": ("cdouble", "double")
  of "csize_t": ("csize_t", "size_t")
  of "pointer": ("pointer", "void *")
  else:
    error("unsupported dynexport ABI type: " & n.strVal, n)

proc exportMetadata(n: NimNode; externalName: string): string =
  let returnType = abiType(n.params[0])
  var params = newJArray()
  for i in 1 ..< n.params.len:
    let identDefs = n.params[i]
    let paramType = abiType(identDefs[^2])
    for j in 0 ..< identDefs.len - 2:
      params.add %*{
        "name": identDefs[j].strVal,
        "nimType": paramType.nimName,
        "cType": paramType.cName
      }
  result = "nimdynmeta:" & $(%*{
    "version": 1,
    "nimName": n.name.strVal,
    "externalName": externalName,
    "returnNimType": returnType.nimName,
    "returnCType": returnType.cName,
    "params": params
  })

macro dynexport*(n: typed): untyped =
  ## Experimental annotation: export a concrete routine under a stable,
  ## collision-resistant name that an IC artifact consumer can discover.
  expectKind n, {nnkProcDef, nnkFuncDef}
  if n[2].kind != nnkEmpty:
    error("dynexport requires a concrete, non-generic routine", n[2])
  let externalName = "nimdyn_" & signatureHash(n.name)
  let metadata = exportMetadata(n, externalName)

  result = copyNimTree(n)
  result.name = ident(n.name.strVal)
  if result.pragma.kind == nnkEmpty:
    result.pragma = newNimNode(nnkPragma)
  result.pragma.add newCall(bindSym"dynlibmeta", newLit(metadata))
  result.pragma.add newTree(nnkExprColonExpr, ident"exportc", newLit(externalName))
  result.pragma.add ident"dynlib"
