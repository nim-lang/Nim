discard """
  targets: "cpp"
"""

# issue #4834
block:
  defer:
    let x = 0


proc main() =
  block:
    defer:
      raise newException(Exception, "foo")

doAssertRaises(Exception):
  main()
