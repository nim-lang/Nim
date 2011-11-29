discard """
  line: "13"
  errormsg: "for a 'var' type a variable needs to be passed"
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

