discard """
  output: "@[(, +,  1,  2, )]"
"""

import re

let str = "(+ 1 2)"
var tokenRE = re"""[\s,]*(~@|[\[\]{}()'`~^@]|"(?:\\.|[^\\"])*"|;.*|[^\s\[\]{}('"`,;)]*)"""
echo str.findAll(tokenRE)
