discard """
  output: '''x: 0 y: 0'''
"""

proc toString*[T](x: T): string = return $x


type
  TMyObj = object
    x, y: int

proc `$`*(a: TMyObj): string =
  result = "x: " & $a.x & " y: " & $a.y

var a: TMyObj
echo toString(a)

