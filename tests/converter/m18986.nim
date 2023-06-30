import std/macros

converter Lit*(x: uint): NimNode = newLit(x)
