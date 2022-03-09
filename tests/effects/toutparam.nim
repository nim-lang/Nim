discard """
  cmd: '''nim c --warningAsError:Uninit:on --skipCfg --skipParentCfg $file'''
  errormsg: "use explicit initialization of 'x' for clarity [Uninit]"
  line: 24
  disabled: "true"
"""

proc gah[T](x: out T) =
  x = 3

proc main =
  var a: array[2, int]
  var x: int
  gah(x)
  a[0] = 3
  a[x] = 3
  echo x

main()

proc mainB =
  var a: array[2, int]
  var x: int
  a[0] = 3
  a[x] = 3
  echo x

mainB()
