discard """
  errormsg: "node is not a module symbol"
"""
import std/macros
macro syms(x: typed) = moduleSymbols(x)
syms(syms)