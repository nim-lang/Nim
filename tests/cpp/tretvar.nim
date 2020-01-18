discard """
  targets: "cpp"
  output: '''test1
xest1
'''
"""
{.passC: "-std=c++14".}

{.experimental: "dotOperators".}

import macros

type
  stdString {.importcpp: "std::string", header: "<string>".} = object
  stdUniquePtr[T] {.importcpp: "std::unique_ptr", header: "<memory>".} = object

proc c_str(a: stdString): cstring {.importcpp: "(char *)(#.c_str())", header: "<string>".}

proc len(a: stdString): csize {.importcpp: "(#.length())", header: "<string>".}

proc setChar(a: var stdString, i: csize, c: char) {.importcpp: "(#[#] = #)", header: "<string>".}

proc `*`*[T](this: stdUniquePtr[T]): var T {.noSideEffect, importcpp: "(* #)", header: "<memory>".}

proc make_unique_str(a: cstring): stdUniquePtr[stdString] {.importcpp: "std::make_unique<std::string>(#)", header: "<string>".}

macro `.()`*[T](this: stdUniquePtr[T], name: untyped, args: varargs[untyped]): untyped =
  result = nnkCall.newTree(
    nnkDotExpr.newTree(
      newNimNode(nnkPar).add(prefix(this, "*")),
      name
    )
  )
  copyChildrenTo(args, result)

var val = make_unique_str("test1")
echo val.c_str()
val.setChar(0, 'x')
echo val.c_str()
