discard """
  file: "tnamedparams.nim"
  line: 8
  errormsg: "type mismatch: got <input: string, filename: string, line: int literal(1), col: int literal(23)>"
"""
import pegs

discard parsePeg(
      input = "input",
      filename = "filename",
      line = 1,
      col = 23)



