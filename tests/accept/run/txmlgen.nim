discard """
  file: "txmlgen.nim"
  output: "<h1><a href=\"http://force7.de/nimrod\">Nimrod</a></h1>"
"""
import xmlgen

var nim = "Nimrod"
echo h1(a(href="http://force7.de/nimrod", nim))




