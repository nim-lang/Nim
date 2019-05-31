discard """
  output: "a\"\"long string\"\"\"\"\"abc\"def_'2'●𝌆𝌆A"
"""
# Test the new different string literals

const
  tripleEmpty = """"long string"""""""" # "long string """""

  rawQuote = r"a"""

  raw = r"abc""def"

  escaped = "\x5f'\50'\u25cf\u{1D306}\u{1d306}\u{41}"


stdout.write(rawQuote)
stdout.write(tripleEmpty)
stdout.write(raw)
stdout.writeLine(escaped)
