#
# meta.nim
#

import tables
import macros

type
  NodeSeq* = seq[NimNode]
  Ident* = tuple[name: string, exported: bool]
  Bracket* = seq[Ident]
  Field* = tuple[identifier: Ident, type_name: string, default: string]
  FieldSeq* = seq[Field]
  TypeDef* = object
    identifier*: Ident
    fields*: FieldSeq
    is_ref*: bool
    object_type*: string
    base_type*: string
  TypeDefSeq* = seq[TypeDef]
  Proc* = tuple[identifier: Ident, params: FieldSeq,
                returns: Ident, generics: FieldSeq, body: NimNode]
  ProcSeq* = seq[Proc]

# Ident procs
proc newIdent*(name: string, exported = false): Ident =
  result.name = name
  result.exported = exported

proc newIdent*(node: NimNode): Ident =
  case node.kind:
    of nnkPostfix:
      result = newIdent(node[1])
      result.exported = true
    of nnkIdent, nnkSym:
      result.name = $(node)
    else:
      let msg = "newIdent cannot initialize from node kind: " & $(node.kind)
      raise newException(ValueError, msg)

proc render*(i: Ident): NimNode {.compileTime.} =
  if i.name == "":
    return newNimNode(nnkEmpty)

  if i.exported:
    result = newNimNode(nnkPostfix)
    result.add(ident "*")
    result.add(ident i.name)
  else:
    result = ident i.name

proc `$`*(identifier: Ident): string = identifier.name

converter toString*(x: Ident): string = x.name

proc newBracket*(node: NimNode): Bracket =
  result = @[]
  case node.kind:
    of nnkBracket:
      for child in node:
        if child.kind != nnkIdent:
          let msg = "Bracket members can only be nnkIdent not kind: " & $(node.kind)
          raise newException(ValueError, msg)
        result.add(newIdent(child))
    else:
      let msg = "newBracket must initialize from node kind nnkBracket not: " & $(node.kind)
      raise newException(ValueError, msg)

# Field procs
proc newField*(identifier: Ident, type_name: string, default: string = ""): Field =
  result.identifier = identifier
  result.type_name = type_name
  result.default = default

proc newField*(node: NimNode): Field =
  case node.kind:
    of nnkIdentDefs:
      if node.len > 3:
        let msg = "newField cannot initialize from nnkIdentDefs with multiple names"
        raise newException(ValueError, msg)
      result.identifier = newIdent(node[0])
      result.type_name = $(node[1])
      case node[2].kind:
        of nnkIdent:
          result.default = $(node[2])
        else:
          result.default = ""
    else:
      let msg = "newField cannot initialize from node kind: " & $(node.kind)
      raise newException(ValueError, msg)

# FieldSeq procs
proc newFieldSeq*(node: NimNode): FieldSeq =
  result = @[]
  case node.kind:
    of nnkIdentDefs:
      let
        type_name = $(node[node.len - 2])
        default_node = node[node.len - 1]
      var default: string
      case default_node.kind:
        of nnkIdent:
          default = $(default_node)
        else:
          default = ""
      for i in 0..node.len - 3:
        let name = newIdent(node[i])
        result.add(newField(name, type_name, default))
    of nnkRecList, nnkVarSection, nnkGenericParams:
      for child in node:
        result = result & newFieldSeq(child)
    else:
      let msg = "newFieldSeq cannot initialize from node kind: " & $(node.kind)
      raise newException(ValueError, msg)

proc render*(f: Field): NimNode {.compileTime.} =
  let identifier = f.identifier.render()
  let type_name = if f.type_name != "": ident(f.type_name) else: newEmptyNode()
  let default = if f.default != "": ident(f.default) else: newEmptyNode()
  newIdentDefs(identifier, type_name, default)

proc render*(fs: FieldSeq): NimNode {.compileTime.} =
  result = newNimNode(nnkRecList)
  for field in fs:
    result.add(field.render())

# TypeDef procs
proc newTypeDef*(identifier: Ident, is_ref = false,
                object_type = "object",
                base_type: string = ""): TypeDef {.compileTime.} =
  result.identifier = identifier
  result.fields = @[]
  result.is_ref = is_ref
  result.object_type = "object"
  result.base_type = base_type

proc newTypeDef*(node: NimNode): TypeDef {.compileTime.} =
  case node.kind:
    of nnkTypeDef:
      result.identifier = newIdent($(node[0]))
      var object_node: NimNode
      case node[2].kind:
        of nnkRefTy:
          object_node = node[2][0]
          result.is_ref = true
        of nnkObjectTy:
          object_node = node[2]
          result.is_ref = false
        else:
          let msg = "newTypeDef could not parse RefTy/ObjectTy, found: " & $(node[2].kind)
          raise newException(ValueError, msg)
      case object_node[1].kind:
        of nnkOfInherit:
          result.base_type = $(object_node[1][0])
        else:
          result.base_type = "object"
      result.fields = newFieldSeq(object_node[2])
    else:
      let msg = "newTypeDef cannot initialize from node kind: " & $(node.kind)
      raise newException(ValueError, msg)

proc render*(typedef: TypeDef): NimNode {.compileTime.} =
  result = newNimNode(nnkTypeDef)
  result.add(typedef.identifier.render)
  result.add(newEmptyNode())
  let object_node = newNimNode(nnkObjectTy)
  object_node.add(newEmptyNode())
  if typedef.base_type == "":
    object_node.add(newEmptyNode())
  else:
    var base_type = newNimNode(nnkOfInherit)
    base_type.add(ident(typedef.base_type))
    object_node.add(base_type)
  let fields = typedef.fields.render()
  object_node.add(fields)
  if typedef.is_ref:
    let ref_node = newNimNode(nnkRefTy)
    ref_node.add(object_node)
    result.add(ref_node)
  else:
    result.add(object_node)

proc newTypeDefSeq*(node: NimNode): TypeDefSeq =
  result = @[]
  case node.kind:
    of nnkTypeSection:
      for child in node:
        result.add(newTypeDef(child))
    else:
      let msg = "newTypeSection could not parse TypeDef, found: " & $(node.kind)
      raise newException(ValueError, msg)

proc render*(typeseq: TypeDefSeq): NimNode {.compileTime.} =
  result = newNimNode(nnkTypeSection)
  for typedef in typeseq:
    result.add(typedef.render())

proc newProc*(identifier: Ident, params: FieldSeq = @[],
              returns: Ident, generics: FieldSeq = @[]): Proc =
  result.identifier = identifier
  result.params = params
  result.returns = returns
  result.generics = generics

proc newProc*(node: NimNode): Proc =
  case node.kind:
    of nnkProcDef, nnkMethodDef:
      result.identifier = newIdent(node[0])
      case node[2].kind:
        of nnkGenericParams:
          result.generics = newFieldSeq(node[2])
        else: result.generics = @[]
      let formal_params = node[3]
      case formal_params[0].kind:
        of nnkIdent:
          result.returns = newIdent(formal_params[0])
        else: discard
      result.params = @[]
      for i in 1..formal_params.len - 1:
        let param = formal_params[i]
        for field in newFieldSeq(param):
          result.params.add(field)
      result.body = node[6]
    else:
      let msg = "newProc cannot initialize from node kind: " & $(node.kind)
      raise newException(ValueError, msg)

proc render*(procdef: Proc): NimNode {.compileTime.} =
  result = newNimNode(nnkProcDef)
  result.add(procdef.identifier.render())
  result.add(newEmptyNode())
  result.add(newEmptyNode())
  let formal_params = newNimNode(nnkFormalParams)
  formal_params.add(procdef.returns.render())
  for param in procdef.params:
    formal_params.add(param.render())
  result.add(formal_params)
  result.add(newEmptyNode())
  result.add(newEmptyNode())
  result.add(procdef.body)
