discard """
  errormsg: "node is not a symbol"
"""
import std/macros
macro syms(x: typed) = moduleSymbols(x)
syms(nil)