discard """
  errormsg: "module 'tself_import' cannot import itself"
  file: "tself_import.nim"
  line: 6
"""
import tself_import {.cyclic.}

proc fa*(): int = 1
