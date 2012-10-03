discard """
  file: "tcasestm.nim"
  output: "ayyydd"
"""
# Test the case statement

type
  tenum = enum eA, eB, eC

var
  x: string = "yyy"
  y: Tenum = eA
  i: int

case y
of eA: write(stdout, "a")
of eB, eC: write(stdout, "b or c")

case x
of "Andreas", "Rumpf": write(stdout, "Hallo Meister!")
of "aa", "bb": write(stdout, "Du bist nicht mein Meister")
of "cc", "hash", "when": nil
of "will", "it", "finally", "be", "generated": nil

var z = case i
  of 1..5, 8, 9: "aa"
  of 6, 7: "bb"
  elif x == "Ha": 
    "cc"
  elif x == "yyy":
    write(stdout, x)
    "dd"
  else:
    "zz"

echo z
#OUT ayyy



