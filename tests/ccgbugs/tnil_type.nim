discard """
  targets: "c cpp"
"""

proc foo(v: type(nil)) = discard
foo nil
