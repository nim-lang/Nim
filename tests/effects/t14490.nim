discard """
  output: "0"
"""

# bug #14490
proc foo(): string =
  raise newException(CatchableError, "err")
proc main() {.raises: [].} =
  let a =
    try:
      foo()
    except:
      default typeof foo()
  echo a.len
when isMainModule: main()
