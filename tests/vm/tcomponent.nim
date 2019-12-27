discard """
  output: '''`:)` @ 0,0
FOO: blah'''
"""

#
# magic.nim
#

# bug #3729

import macros, sequtils, tables
import strutils
import sugar, meta

type
  Component = object
    fields: FieldSeq
    field_index: seq[string]
    procs: ProcSeq
    procs_index: seq[string]

  Registry = object
    field_index: seq[string]
    procs_index: seq[string]
    components: Table[string, Component]
    builtin: Component

proc newRegistry(): Registry =
  result.field_index = @[]
  result.procs_index = @[]
  result.components = initTable[string, Component]()

var registry {.compileTime.} = newRegistry()

proc validateComponent(r: var Registry, name: string, c: Component) =
  if r.components.hasKey(name):
    let msg = "`component` macro cannot consume duplicated identifier: " & name
    raise newException(ValueError, msg)

  for field_name in c.field_index:
    if r.field_index.contains(field_name):
      let msg = "`component` macro cannot delcare duplicated field: " & field_name
      raise newException(ValueError, msg)
    r.field_index.add(field_name)

  for proc_name in c.procs_index:
    if r.procs_index.contains(proc_name):
      let msg = "`component` macro cannot delcare duplicated proc: " & proc_name
      raise newException(ValueError, msg)
    r.procs_index.add(proc_name)

proc addComponent(r: var Registry, name: string, c: Component) =
  r.validateComponent(name, c)
  r.components.add(name, c)

proc parse_component(body: NimNode): Component =
  result.field_index = @[]
  result.procs_index = @[]
  for node in body:
    case node.kind:
      of nnkVarSection:
        result.fields = newFieldSeq(node)
        for field in result.fields:
          result.field_index.add(field.identifier.name)
      of nnkMethodDef, nnkProcDef:
        let new_proc = meta.newProc(node)
        result.procs = result.procs & @[new_proc]
        for procdef in result.procs:
          result.procs_index.add(procdef.identifier.name)
      else: discard

macro component*(name, body: untyped): typed =
  let component = parse_component(body)
  registry.addComponent($name, component)
  parseStmt("discard")

macro component_builtins(body: untyped): typed =
  let builtin = parse_component(body)
  registry.field_index = builtin.field_index
  registry.procs_index = builtin.procs_index
  registry.builtin = builtin

proc bind_methods*(component: var Component, identifier: Ident): seq[NimNode] =
  result = @[]
  for procdef in component.procs.mitems:
    let this_field = newField(newIdent("this"), identifier)
    procdef.params.insert(this_field, 0)
    result.add(procdef.render())

macro bind_components*(type_name, component_names: untyped): typed =
  result = newStmtList()
  let identifier = newIdent(type_name)
  let components = newBracket(component_names)
  var entity_type = newTypeDef(identifier, true, "object", "RootObj")
  entity_type.fields = registry.builtin.fields
  for component_name, component in registry.components:
    if components.contains(newIdent(component_name)):
      entity_type.fields = entity_type.fields & component.fields
  # TODO why doesn't the following snippet work instead of the one above?
  # for name in components:
  #   echo "Registering $1 to $2" % [name.name, identifier.name]
  #   let component = registry.components[name.name]
  #   entity_type.fields = entity_type.fields & component.fields
  let type_section: TypeDefSeq = @[entity_type]
  result.add type_section.render
  var builtin = registry.builtin
  let builtin_methods = bind_methods(builtin, identifier)
  for builtin_proc in builtin_methods:
    result.add(builtin_proc)
  echo "SIGSEV here"
  for component in registry.components.mvalues():
    for method_proc in bind_methods(component, identifier):
      result.add(method_proc)

component_builtins:
  proc foo(msg: string) =
    echo "FOO: $1" % msg

component position:
  var x*, y*: int

component name:
  var name*: string
  proc render*(x, y: int) = echo "`$1` @ $2,$3" % [this.name, $x, $y]

bind_components(Entity, [position, name])

var e = new(Entity)
e.name = ":)"
e.render(e.x, e.y)
e.foo("blah")
