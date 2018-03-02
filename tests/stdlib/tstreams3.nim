discard """
  file: "tstreams3.nim"
  output: "threw exception"
"""
import streams

try:
  var fs = openFileStream("shouldneverexist.txt")
except IoError:
  echo "threw exception"
