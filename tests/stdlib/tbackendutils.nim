discard """
  joinable: false
"""

import experimental/backendutils
import macros, strutils, os
import unittest

macro test(body: untyped): untyped =
  result = newStmtList()
  for T in body:
    result.add quote do:
      let s1 = `T`.sizeof
      let s2 = `T`.c_sizeof
      if s1 != s2:
        echo "$1 $2 => sizeof: $3 vs c_sizeof: $4" % [$astToStr(`T`), c_astToStr(`T`), $s1, $s2]

type FooEmpty = object
const N = 10
type FooEmptyArr = array[N, FooEmpty]
type Bar = object
  x: FooEmpty
  y: cint

type BarTup = (FooEmpty, cint)
type BarTup2 = (().type, cint)

# type MyEnum = enum k1, k2
type MyEnum {.exportc.} = enum k1, k2
type Obj = object
  x1: MyEnum
  x2: cint

test:
  FooEmpty
  FooEmptyArr
  Bar
  BarTup
  BarTup2
  MyEnum
  Obj

block: # c_currentFunction
  proc test1(){.exportc.} =
    doAssert c_currentFunction == "test1"
  proc test2() =
    doAssert c_currentFunction.startsWith "test2_", c_currentFunction
  test1()
  test2()

block: # c_currentFunction
  let file = c_currentSourcePath
  let name = currentSourcePath.splitFile.name
  doAssert file.contains name

  let code = file.readFile
  let z = "abc123"
  doAssert code.count(z) == 1 # string generated in code

block:
  # checks `c_astToStr` generates top-level macro `c_astToStrImp` only once
  let code = c_currentSourcePath.readFile
  proc compose(a, b: string): string =
    ## avoids forming a&b at CT, which could end up in cgen'd file
    ## and affect the count
    result = a & b
  doAssert code.count(compose("#define ", "c_astToStrImp")) == 1

block: # c_astToStr
  doAssert c_astToStr(cint) == "int"
  type Foo = object
  doAssert c_astToStr(Foo).startsWith "tyObject_Foo_"

block: # c_sizeof
  doAssert char.c_sizeof == 1
  {.emit("here"):"""
typedef struct Foo1{
} Foo1;
typedef enum FooEnum{
  k1, k2
} FooEnum;
""".}

  # type Foo1 {.importc, completeStruct.} = object # pending https://github.com/nim-lang/Nim/pull/13926
  type Foo1 {.importc.} = object
  type Foo1Alias = object

  type FooEnum {.importc.} = enum k1, k2
  when defined(cpp):
    doAssert Foo1.c_sizeof == 1
  else:
    doAssert Foo1.c_sizeof == 0

  template checkSize(T) =
    let s1 = T.c_sizeof
    let s2 = T.sizeof
    # check s1 == s2, $($T, c_astToStr(T), s1, s2) # pending https://github.com/nim-lang/Nim/pull/10558
    if s1 != s2:
      echo "sizeof mismatch " & $($T, c_astToStr(T), s1, s2)
    check s1 == s2
  checkSize cint
  checkSize int
  checkSize Foo1
  when false:
    checkSize Foo1Alias # pending https://github.com/nim-lang/Nim/issues/13945
    checkSize FooEnum # pending https://github.com/nim-lang/Nim/issues/13927
