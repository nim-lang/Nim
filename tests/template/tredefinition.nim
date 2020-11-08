discard """
  errormsg: "redefinition of 'a`gensym"
  line: 9
"""
# bug #10180
proc f() =
  template t() =
    var a = 1
    var a = 2
    echo a
  t()

f()
