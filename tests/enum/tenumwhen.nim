discard """
  output: "true\ntrue\nfive"
"""
import macros

type num = enum one, two, when false: three else: four, five

echo four>two
echo one<two

let x: num = five
case x
of one: echo "one"
of two: echo "two"
of four: echo "four"
of five: echo "five"

