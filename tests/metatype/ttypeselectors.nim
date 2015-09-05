import macros

template selectType(x: int): typeDesc =
  when x < 10:
    int
  else:
    string

template simpleTypeTempl: typeDesc =
  string

macro typeFromMacro: typedesc = string

proc t1*(x: int): simpleTypeTempl() =
  result = "test"

proc t2*(x: int): selectType(100) =
  result = "test"

proc t3*(x: int): selectType(1) =
  result = 10

proc t4*(x: int): typeFromMacro() =
  result = "test"

var x*: selectType(50) = "test"

proc t5*(x: selectType(5)) =
  var y = x + 10
  echo y

var y*: type(t2(100)) = "test"

proc t6*(x: type(t3(0))): type(t1(0)) =
  result = $x

proc t7*(x: int): type($x) =
  result = "test"

