discard """
  output: '''!!Hi!!'''
"""
# bug #4658
import future

var x = 123

proc twice[T](f: T -> T): T -> T = (x: T) => f(f(x))

proc quote(s: string): string = "!" & s & "!"

echo twice(quote)("Hi")
