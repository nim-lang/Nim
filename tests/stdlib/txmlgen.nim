discard """
  file: "txmlgen.nim"
  output: "<h1><a href=\"http://force7.de/nim\">Nim</a></h1>"
"""
import htmlgen

var nim = "Nim"
echo h1(a(href="http://force7.de/nim", nim))




