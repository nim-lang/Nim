discard """
  errormsg: "index out of bounds: (a:0) <= (i:3) <= (b:1) "
  line: 9
"""

# Note: merge in tinvalidarrayaccess.nim pending https://github.com/nim-lang/Nim/issues/9906

let a = [1,2]
echo a[3]

when false:
  # TOOD: this case is not yet handled, giving: "index out of bounds"
  proc fun()=
    let a = @[1,2]
    echo a[3]
  static: fun()
