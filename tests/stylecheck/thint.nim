discard """
  matrix: "--styleCheck:hint"
  action: compile
"""

# Test violating ident definition:
{.pragma: user_pragma.} #[tt.Hint
        ^ 'user_pragma' should be: 'userPragma' [Name] ]#

# Test violating ident usage style matches definition style:
{.userPragma.} #[tt.Hint
  ^ 'userPragma' should be: 'user_pragma' [template declared in thint.nim(7, 9)] [Name] ]#

# Test violating builtin pragma usage style:
{.no_side_effect.}: #[tt.Hint
  ^ 'no_side_effect' should be: 'noSideEffect' [Name] ]#
  discard 0

# Test:
#  - definition style violation
#  - user pragma usage style violation
#  - builtin pragma usage style violation
proc generic_proc*[T] {.no_destroy, userPragma.} = #[tt.Hint
     ^ 'generic_proc' should be: 'genericProc' [Name]; tt.Hint
                        ^ 'no_destroy' should be: 'nodestroy' [Name]; tt.Hint
                                    ^ 'userPragma' should be: 'user_pragma' [template declared in thint.nim(7, 9)] [Name] ]#
  # Test definition style violation:
  let snake_case = 0 #[tt.Hint
      ^ 'snake_case' should be: 'snakeCase' [Name] ]#
  # Test user pragma definition style violation:
  {.pragma: another_user_pragma.} #[tt.Hint
          ^ 'another_user_pragma' should be: 'anotherUserPragma' [Name] ]#
  # Test user pragma usage style violation:
  {.anotherUserPragma.} #[tt.Hint
    ^ 'anotherUserPragma' should be: 'another_user_pragma' [template declared in thint.nim(31, 11)] [Name] ]#
  # Test violating builtin pragma usage style:
  {.no_side_effect.}: #[tt.Hint
    ^ 'no_side_effect' should be: 'noSideEffect' [Name] ]#
    # Test usage style violation:
    discard snakeCase #[tt.Hint
            ^ 'snakeCase' should be: 'snake_case' [let declared in thint.nim(28, 7)] [Name] ]#

generic_proc[int]()
