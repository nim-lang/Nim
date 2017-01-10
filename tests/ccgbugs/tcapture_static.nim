discard """
  output: '''hi'''
"""

# bug #4551

proc foo() =
    let arr = ["hi"]
    for i, v in arr:
        let bar = proc =
            echo v
        bar()
foo()
