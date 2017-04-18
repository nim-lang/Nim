discard """
  file: "tstrchararray.nim"
  output: "Nim"
"""

# issue #4040

const
  a: array[3, char] = ['N', 'i', 'm']
  aStr = $a

echo aStr
