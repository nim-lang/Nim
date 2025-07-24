discard """
  cmd: "nim cpp --nimbasepattern:test.h --cincludes:./tests/options $file "
  output:'''
(a: 1)
'''
"""
const header = """
#pragma once
#include "nimbase.h"
struct Foo {
  int a;
};
"""

import os
static:
  const dir = "./tests/options/"
  createDir(dir)
  writeFile(dir / "test.h", header)

type 
  Foo {.importc.} = object
    a: int32 = 1
  

echo $Foo()