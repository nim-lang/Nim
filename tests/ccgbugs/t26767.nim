discard """
  matrix: "--mm:refc --reportLargeStackObjects:1000000 --warningAsError:LargeStackObject; --mm:orc --reportLargeStackObjects:1000000 --warningAsError:LargeStackObject; --mm:orc -d:release --reportLargeStackObjects:1000000 --warningAsError:LargeStackObject"
  output: '''
@[1]
@[1]
@[2]
'''
"""

# bug #26767: a call in a nested object constructor of a `ref` constructor
# used a stack temporary of the full (huge) field type.
# `--reportLargeStackObjects` turns any such temporary into a compile error.

type
  Big = object
    data: array[16 * 1024 * 1024, byte]
    s: seq[int]
  Inner = object
    big: Big
  Outer = object
    inner: Inner

proc f(x = 1): Big = result.s = @[x]

let r = (ref Outer)(inner: Inner(big: f()))
echo r.inner.big.s

proc main() =
  let x = (ref Outer)(inner: Inner(big: f()))
  echo x.inner.big.s
  try:
    let y = (ref Outer)(inner: Inner(big: f(2)))
    echo y.inner.big.s
  except ValueError:
    discard

main()
