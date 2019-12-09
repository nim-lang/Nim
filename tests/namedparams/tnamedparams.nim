discard """
  errormsg: "type mismatch: got <input: string, filename: string, line: int literal(1), col: int literal(23)>"
  file: "tnamedparams.nim"
  line: 8
"""
import pegs

discard parsePeg(
      input = "input",
      filename = "filename",
      line = 1,
      col = 23)
