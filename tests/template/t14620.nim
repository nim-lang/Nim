discard """
  output: "1"
"""

# bug #14620
template t(body: untyped) =
  proc bod(a: int) =
    let x {.inject.} = a
    body
  let x = 1
  bod(x)
t:
  echo x
