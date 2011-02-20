discard """
  file: "tlenopenarray.nim"
  output: "1"
"""

# len(x) --> len([x]) --> match!
echo len(1_000_000) #OUT 1




