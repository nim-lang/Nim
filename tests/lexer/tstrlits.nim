discard """
  file: "tstrlits.nim"
  output: "a\"\"long string\"\"\"\"\"abc\"def_'2'●"
"""
# Test the new different string literals

const
  tripleEmpty = """"long string"""""""" # "long string """""

  rawQuote = r"a"""

  raw = r"abc""def"

  escaped = "\x5f'\50'\u25cf"


stdout.write(rawQuote)
stdout.write(tripleEmpty)
stdout.write(raw)
stdout.write(escaped)
#OUT a""long string"""""abc"def



