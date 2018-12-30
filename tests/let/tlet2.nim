discard """
  errormsg: "type mismatch: got <int literal(8), int literal(5), int, int>"
  line: "13"
"""

proc divmod(a, b: int, res, remainder: var int) =
  res = a div b        # integer division
  remainder = a mod b  # integer modulo operation

let
  x = 9
  y = 3
divmod(8, 5, x, y) # modifies x and y
echo(x)
echo(y)
