discard """
  matrix: "--errorMax:0 --styleCheck:error"
"""

proc generic_proc*[T](a_a: int) = #[tt.Error
     ^ 'generic_proc' should be: 'genericProc'; tt.Error
                      ^ 'a_a' should be: 'aA' ]#
  discard
