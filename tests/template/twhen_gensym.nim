discard """
  output: "hi"
"""

# bug #2670
template testTemplate(b: bool): typed =
    when b:
        var a = "hi"
    else:
        var a = 5
    echo a

testTemplate(true)
