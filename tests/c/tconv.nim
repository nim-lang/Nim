discard """
  matrix: "-d:danger;"
  targets: "c cpp"
"""

block: # bug #18540
  block:
    let num = 256.1
    doAssert ord(uint8(num)) == 154
  block:
    let num = 255.0
    doAssert ord(char(num)) == 0
    let z = char(num)
    doAssert ord(z) == 0
