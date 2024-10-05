# v2.x.x - yyyy-mm-dd


## Changes affecting backward compatibility


## Standard library additions and changes


## Language changes

- With the experimental option `--experimental:typedTypeMacroPragma`,
  macro pragmas in type definitions now receive a unary `nnkTypeSection` as
  the argument instead of `nnkTypeDef`, which means `typed` arguments are now
  possible for these macros.

  ```nim
  {.experimental: "typedTypeMacroPragma".}

  import macros

  macro foo(def: typed) =
    assert def.kind == nnkTypeSection # previously nnkTypeDef
    assert def.len == 1
    assert def[0].kind == nnkTypeDef
    result = def
    
  type Obj {.foo.} = object
    x, y: int

  let obj = Obj(x: 1, y: 2)
  ```

  To keep compatibility, macros can be updated to accept either one of
  `nnkTypeDef` or `nnkTypeSection` as input.


## Compiler changes


## Tool changes


