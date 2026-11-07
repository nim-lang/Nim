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
  let constants = newConstContext(conf)
  let simple = fixture("simple", """
const
  enabled* {.booldefine: "guard.enabled".} = true
  disabled {.booldefine.} = false
  selected = enabled
  grouped = (selected)
  backend {.strdefine.} = "foo"
  count {.intdefine.} = 3
""")
  for name in ["enabled", "selected", "grouped"]:
    let value = constants.getConstValue(simple, name)
    doAssert value.kind == ckBool and value.boolVal
  doAssert not constants.getConstValue(simple, "disabled").boolVal
  for name in ["backend", "count"]:
    doAssert constants.getConstValue(simple, name).kind == ckUnknown

  block overrides:
    let overridden = newConfigRef()
    overridden.symbols.defineSymbol("guard.enabled", "off")
    overridden.symbols.defineSymbol("disabled")
    let context = newConstContext(overridden)
    doAssert not context.getConstValue(simple, "enabled").boolVal
    doAssert not context.getConstValue(simple, "selected").boolVal
    doAssert context.getConstValue(simple, "disabled").boolVal
    overridden.symbols.defineSymbol("guard.enabled", "invalid bool")
    doAssert newConstContext(overridden).getConstValue(simple, "enabled").kind == ckUnknown

  block aliases_and_cycles:
    let source = fixture("aliases", """
const featureEnabled = true
const selected = feature_enabled
const cyclicA = cyclicB
const cyclicB = cyclicA
""")
    doAssert constants.getConstValue(source, "selected").boolVal
    doAssert constants.getConstValue(source, "cyclicA").kind == ckUnknown

  block expressions_are_unknown:
    let source = fixture("expressions", """
const
  conjunction = true and false
  disjunction = true or false
  negation = not false
  equality = 1 == 1
  ordering = 1 < 2
  combined = "foo" & "bar"
  feature = defined(example)
  threaded = compileOption("threads")
  chosen = when true: true else: false
  conditional = if true: true else: false
  converted = bool(1)
  width = sizeof(pointer)
  typed: bool = true
  computed {.booldefine.} = not false
""")
    conf.symbols.defineSymbol("computed", "on")
    for name in ["conjunction", "disjunction", "negation", "equality", "ordering",
                 "combined", "feature", "threaded", "chosen", "conditional",
                 "converted", "width", "typed", "computed"]:
      doAssert constants.getConstValue(source, name).kind == ckUnknown, name

  block generic_parameters_shadow_module_constants:
    let source = fixture("shadowing", """
const enabled = true
template choose(enabled: untyped) =
  when enabled:
    import something
""")
    doAssert constants.getConstValue(source, "enabled").kind == ckUnknown

  block conditional_declarations:
    let source = fixture("conditional", """
const enabled = true
when enabled:
  const direct = false
else:
  const direct = true
when defined(example):
  const computed = true
else:
  const computed = false
""")
    doAssert not constants.getConstValue(source, "direct").boolVal
    doAssert constants.getConstValue(source, "computed").kind == ckUnknown

  block imported_operators_do_not_affect_direct_values:
    discard fixture("operators", "proc `not`*(a: bool): bool = true\n")
    let source = fixture("imported", """
import operators
const enabled {.booldefine.} = false
const computed = not enabled
""")
    doAssert not constants.getConstValue(source, "enabled").boolVal
    doAssert constants.getConstValue(source, "computed").kind == ckUnknown

  block includes_share_constant_scope:
    discard fixture("settings", "const enabled = true\n")
    let source = fixture("included", "include \"settings\"\nconst selected = enabled\n")
    doAssert constants.getConstValue(source, "selected").boolVal

  block parsing_is_conservative:
    let source = fixture("invalid", "const enabled = (\n")
    let errors = conf.errorCounter
    doAssert constants.getConstValue(source, "enabled").kind == ckUnknown
    doAssert conf.errorCounter == errors
finally:
  removeDir(dir)
