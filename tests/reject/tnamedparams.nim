discard """
  file: "tnamedparams.nim"
  line: 8
  errormsg: "Error: type mismatch: got (input: string, filename: string, line: int, col: int)"
"""
import pegs

discard parsePeg(
      input = "input", 
      filename = "filename", 
      line = 1, 
      col = 23)



