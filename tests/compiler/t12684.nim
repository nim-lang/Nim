discard """
  cmd: "nim check --hints:off --warnings:off $file"
  errormsg: "undeclared identifier: 'Undeclared'"
"""

var x: Undeclared
import compiler/nimeval
