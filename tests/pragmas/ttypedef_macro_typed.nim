discard """
  nimout: '''
TypeSection
  TypeDef
    PragmaExpr
      Sym "X"
      Pragma
    Empty
    ObjectTy
      Empty
      Empty
      Empty
'''
"""

import macros

{.experimental: "typedTypeMacroPragma".}

block: # changelog entry
  macro foo(def: typed) =
    assert def.kind == nnkTypeSection # previously nnkTypeDef
    assert def.len == 1
    assert def[0].kind == nnkTypeDef
    result = def
    
  type Obj {.foo.} = object
    x, y: int

  let obj = Obj(x: 1, y: 2)

block: # issue #18864
  macro test(n: typed): untyped =
    echo n.treeRepr
    result = n

  type
    X {.test.} = object
  var x = X()

block: # issue #15334
  macro entity(entityType: typed) =
    result = entityType
    
  type
    RootEntity = ref object of RootObj
    Player {.entity.} = ref object of RootEntity
      x, y: int
  var foo = Player()
