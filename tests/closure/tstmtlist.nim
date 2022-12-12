discard """
  action: compile
"""

proc foo(x: proc()) = x()
foo: echo "a" #[tt.Warning
     ^ statement list expression assumed to be anonymous proc; this is deprecated, use `do (): ...` or `proc () = ...` instead [StmtListLambda]]#
foo do: echo "b" #[tt.Warning
        ^ statement list expression assumed to be anonymous proc; this is deprecated, use `do (): ...` or `proc () = ...` instead [StmtListLambda]]#
