
type
  TMyObj = object
    x: int

proc gen*[T](): T =
  var d: TMyObj
  # access private field here
  d.x = 3
  result = d.x

