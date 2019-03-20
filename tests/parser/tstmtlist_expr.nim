discard """
  output: '''10'''
"""

proc xx(a: int): int =
  let y = 0
  return
    var x = 0
    x + y

proc b(x: int): int = 
  raise 
    var e: ref Exception
    new(e)
    e.msg = "My Exception msg"
    e

##issue 4035
echo(5 +
5)