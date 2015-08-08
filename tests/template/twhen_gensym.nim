discard """
  output: "hi"
"""

# bug #2670
template testTemplate(b: bool): stmt =
    when b:
        var a = "hi"
    else:
        var a = 5
    echo a

testTemplate(true)
