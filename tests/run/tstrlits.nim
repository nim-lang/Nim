discard """
  file: "tstrlits.nim"
  output: "a\"\"long string\"\"\"\"\"abc\"def"
"""
# Test the new different string literals

const
  tripleEmpty = """"long string"""""""" # "long string """""
  
  rawQuote = r"a"""
  
  raw = r"abc""def"

stdout.write(rawQuote)
stdout.write(tripleEmpty)
stdout.write(raw)
#OUT a""long string"""""abc"def



