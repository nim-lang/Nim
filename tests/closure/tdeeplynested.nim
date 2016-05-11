discard """
  output: '''int: 108'''
"""

# bug #4070

proc id(f: (proc())): auto =
  return f

proc foo(myinteger: int): (iterator(): int) =
  return iterator(): int {.closure.} =
           proc bar() =
             proc kk() =
               echo "int: ", myinteger

             kk()

           id(bar)()

discard foo(108)()
