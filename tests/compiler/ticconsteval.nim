discard """
  joinable: false
"""

import std/[assertions, os, tempfiles]
import compiler/[icconsteval, options, condsyms]

let dir = createTempDir("nim_ic_consteval_", "")

proc fixture(name, source: string): string =
  result = dir / name.addFileExt("nim")
  writeFile(result, source)

try:
  let conf = newConfigRef()
  conf.cmd = cmdIc
  conf.symbols.defineSymbol("features.example.enabled")
  let constants = newConstContext(conf)
  let simple = fixture("simple", """
const
  backend* = "foo"
  empty = ""
  count* {.intdefine.} = 3
  enabled* {.booldefine.} = true
  selected = backend == "foo" and count >= 3
  mode* {.strdefine: "custom.mode".} = "plain"
  hasFeature = defined(features.example.enabled)
  chosen = when defined(features.example.enabled): "yes" else: "no"
  combined = backend & "bar"
when defined(features.example.enabled):
  const conditional = 42
else:
  const conditional = 0
""")
  doAssert constants.getConstValue(simple, "backend").strVal == "foo"
  doAssert constants.getConstValue(simple, "empty").strVal == ""
  doAssert constants.getConstValue(simple, "count").intVal == 3
  doAssert constants.getConstValue(simple, "enabled").boolVal
  doAssert constants.getConstValue(simple, "selected").boolVal
  doAssert constants.getConstValue(simple, "mode").strVal == "plain"
  doAssert constants.getConstValue(simple, "hasFeature").boolVal
  doAssert constants.getConstValue(simple, "chosen").strVal == "yes"
  doAssert constants.getConstValue(simple, "combined").strVal == "foobar"
  doAssert constants.getConstValue(simple, "conditional").intVal == 42

  block overrides:
    let overridden = newConfigRef()
    overridden.symbols.defineSymbol("custom.mode", "")
    overridden.symbols.defineSymbol("count", "7")
    overridden.symbols.defineSymbol("enabled", "off")
    let context = newConstContext(overridden)
    doAssert context.getConstValue(simple, "mode").strVal == ""
    doAssert context.getConstValue(simple, "count").intVal == 7
    doAssert not context.getConstValue(simple, "enabled").boolVal
    overridden.symbols.defineSymbol("count", "not an integer")
    doAssert newConstContext(overridden).getConstValue(simple, "count").kind == ckUnknown

  block aliases_and_styles:
    let source = fixture("aliases", """
const backendMode = "foo"
const selected = backend_mode == "foo"
const cyclicA = cyclicB
const cyclicB = cyclicA
""")
    doAssert constants.getConstValue(source, "selected").boolVal
    doAssert constants.getConstValue(source, "cyclicA").kind == ckUnknown

  block unsupported_calls_are_not_executed:
    let source = fixture("calls", """
proc choose(): string = "foo"
const selected = choose()
const width = sizeof(pointer)
const computed = 1 + 2
""")
    for name in ["selected", "width", "computed"]:
      doAssert constants.getConstValue(source, name).kind == ckUnknown

  block generic_parameters_shadow_module_constants:
    let source = fixture("shadowing", """
const backend = "foo"
template choose(backend: untyped) =
  when backend == "bar":
    import something
""")
    doAssert constants.getConstValue(source, "backend").kind == ckUnknown

  block conditional_declarations_need_known_guards:
    let source = fixture("conditional", """
when compiles(something()):
  const backend = "foo"
else:
  const backend = "bar"
""")
    doAssert constants.getConstValue(source, "backend").kind == ckUnknown

  block operator_overloads_need_sem:
    let source = fixture("operators", """
proc `==`(a, b: string): bool = false
const selected = "foo" == "foo"
""")
    doAssert constants.getConstValue(source, "selected").kind == ckUnknown
    let imported = fixture("importedoperators", """
import operators
const selected = "foo" == "foo"
const enabled {.booldefine.} = true
""")
    doAssert constants.getConstValue(imported, "selected").kind == ckUnknown
    doAssert constants.getConstValue(imported, "enabled").boolVal

  block includes_share_constant_scope:
    discard fixture("settings", "const mode = \"foo\"\n")
    let source = fixture("included", "include \"settings\"\nconst selected = mode == \"foo\"\n")
    doAssert constants.getConstValue(source, "selected").boolVal

  block parsing_is_conservative:
    let source = fixture("invalid", "const mode = (\n")
    let errors = conf.errorCounter
    doAssert constants.getConstValue(source, "mode").kind == ckUnknown
    doAssert conf.errorCounter == errors

  block comparisons:
    doAssert compareConsts(stringConst(""), stringConst(""), "==").boolVal
    doAssert compareConsts(intConst(2), intConst(3), "<").boolVal
    doAssert compareConsts(boolConst(false), boolConst(true), "!=").boolVal
    doAssert compareConsts(stringConst("2"), intConst(2), "==").kind == ckUnknown
finally:
  removeDir(dir)
