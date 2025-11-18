##[
Runtime debugging utilities for Nim's OOP features.

This module provides helpers for inspecting and debugging method dispatch,
particularly useful when working with inheritance hierarchies.

**Note on Runtime Type Information:**

With modern memory management (ARC/ORC), runtime type names are not
available by default. To enable them, you have two options:

1. Use ``--mm:refc`` (reference counting GC) with ``-d:nimTypeNames``
2. Use the helper procs in this module which determine types via ``of`` checks

The helpers in this module work with all memory managers.
]##

import std/macros

macro genRuntimeTypeCheck*(baseType: typed, derivedTypes: varargs[typed]): untyped =
  ## Generates a helper proc to get runtime type names for a type hierarchy.
  ##
  ## This macro creates a ``runtimeTypeName`` proc that checks against
  ## all provided derived types using the ``of`` operator.
  ##
  ## **Example:**
  ##
  ## .. code-block:: nim
  ##   type
  ##     Animal = ref object of RootObj
  ##     Dog = ref object of Animal
  ##     Cat = ref object of Animal
  ##
  ##   genRuntimeTypeCheck(Animal, Dog, Cat)
  ##
  ##   let animal: Animal = Dog()
  ##   echo runtimeTypeName(animal)  # Prints "Dog"
  result = newStmtList()

  # Build if-elif chain checking from most derived to least derived
  var ifStmt = newNimNode(nnkIfStmt)

  # Add derived types first (most specific to least specific)
  for i in countdown(derivedTypes.len - 1, 0):
    let dt = derivedTypes[i]
    let typeName = $dt
    let condition = quote do:
      obj of `dt`
    let returnStmt = quote do:
      return `typeName`
    ifStmt.add(newTree(nnkElifBranch, condition, returnStmt))

  # Add base type check last
  let baseTypeName = $baseType
  let baseCondition = quote do:
    obj of `baseType`
  let baseReturn = quote do:
    return `baseTypeName`
  ifStmt.add(newTree(nnkElifBranch, baseCondition, baseReturn))

  # Fallback - return compile-time type
  let fallbackReturn = quote do:
    return $typeof(obj)
  let elseBlock = newTree(nnkElse, fallbackReturn)
  ifStmt.add(elseBlock)

  # Create the proc
  let objParam = newIdentNode("obj")
  let procDef = newProc(
    name = newIdentNode("runtimeTypeName"),
    params = [newIdentNode("string"), newIdentDefs(objParam, baseType)],
    body = ifStmt,
    procType = nnkProcDef
  )
  procDef[0] = nnkPostfix.newTree(newIdentNode("*"), newIdentNode("runtimeTypeName"))

  result.add(procDef)

proc debugMethodDispatch*[T](obj: T, methodName: string, typeName: string) {.inline.} =
  ## Prints debug information about method dispatch.
  ##
  ## Shows both compile-time and runtime type information.
  ##
  ## **Example:**
  ##
  ## .. code-block:: nim
  ##   type Animal = ref object of RootObj
  ##   type Dog = ref object of Animal
  ##
  ##   genRuntimeTypeCheck(Animal, Dog)
  ##
  ##   method makeSound(a: Animal) {.base.} =
  ##     debugMethodDispatch(a, "makeSound", runtimeTypeName(a))
  ##     echo "Animal sound"
  ##
  ##   let animal: Animal = Dog()
  ##   animal.makeSound()
  ##   # Prints: [Method Dispatch] makeSound on Dog (compile-time type: Animal)
  echo "[Method Dispatch] ", methodName, " on ", typeName,
       " (compile-time type: ", $typeof(obj), ")"
