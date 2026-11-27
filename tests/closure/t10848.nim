discard """
  matrix: "--warning:StmtListLambda:off"
  output: '''10
false'''
"""

# bug #10848: the declarations of a statement list lifted to a lambda
# do not leak into the caller's scope
proc foo(p: proc) = p()
foo: (let x = 10; echo x)
echo declared(x)
