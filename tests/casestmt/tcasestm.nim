discard """
  file: "tcasestm.nim"
  output: "ayyydd"
"""
# Test the case statement

type
  Tenum = enum eA, eB, eC

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
of "cc", "hash", "when": discard
of "will", "it", "finally", "be", "generated": discard

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

let str1 = "Y"
let str2 = "NN"
let a = case str1:
  of "Y": true
  of "N": false
  else: 
    echo "no good"
    quit("quiting")

proc toBool(s: string): bool = 
  case s:
    of nil, "": raise newException(ValueError, "Invalid boolean")
    elif s[0] == 'Y': true
    elif s[0] == 'N': false
    else: "error".quit(2)


let b = "NN".toBool()

doAssert(a == true)
doAssert(b == false)

static:
  #bug #7407
  let bstatic = "N".toBool()
  doAssert(bstatic == false)

var bb: bool
doassert(not compiles(
  bb = case str2:
    of nil, "": raise newException(ValueError, "Invalid boolean")
    elif str.startsWith("Y"): true
    elif str.startsWith("N"): false
))

doassert(not compiles(
  bb = case str2:
    of "Y": true
    of "N": false
))

doassert(not compiles(
  bb = case str2:
    of "Y": true
    of "N": raise newException(ValueError, "N not allowed")
))

doassert(not compiles(
  bb = case str2:
    of "Y": raise newException(ValueError, "Invalid Y")
    else: raise newException(ValueError, "Invalid N")
))


doassert(not compiles(
  bb = case str2:
    of "Y":
      raise newException(ValueError, "Invalid Y")
      true    
    else: raise newException(ValueError, "Invalid")
))


doassert(not compiles(
  bb = case str2:
    of "Y":
      "invalid Y".quit(3)
      true    
    else: raise newException(ValueError, "Invalid")
))