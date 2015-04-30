discard """
  cmd: r"nim c --hints:on $options --threads:on $file"
"""

import algorithm

# bug #1657
var modules = @["hi", "ho", "ha", "huu"]
sort(modules, system.cmp)

type
  MyType = object
    x: string

proc cmp(a, b: MyType): int = cmp(a.x, b.x)

var modulesB = @[MyType(x: "ho"), MyType(x: "ha")]
sort(modulesB, cmp)

# bug #2397

proc f(x: (proc(a,b: string): int) = system.cmp) = discard
