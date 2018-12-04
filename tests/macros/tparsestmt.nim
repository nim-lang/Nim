discard """
  output: '''
test case: -d:case_ok1--------------------


test case: -d:case_ok2--------------------


test case: -d:case1--------------------
stack trace: (most recent call last)
<replaced_file> fun
tparsestmt.nim(67, 6) template/generic instantiation of `fun` from here
tparsestmt.nim(61, 5) template/generic instantiation of `implicit_file_for_parseStmt.nim:
>>let a0=1
>>let a1=1
>>let a2=1) # inserting an error here
>>let a3=1
>>` from here
<replaced_file> Error: unhandled exception: implicit_file_for_parseStmt.nim(3, 9) Error: invalid indentation


test case: -d:case2--------------------
tparsestmt.nim(79, 6) template/generic instantiation of `fun` from here
tparsestmt.nim(72, 5) template/generic instantiation of `implicit_file_for_parseStmt.nim:
>>let a0=1
>>let a1=1
>>let a2=1
>>let a1=1  # inserting a redefinition error
>>
>>` from here
implicit_file_for_parseStmt.nim(4, 5) Error: redefinition of 'a1'; previous declaration here: implicit_file_for_parseStmt.nim(4, 4)


test case: -d:case3--------------------
stack trace: (most recent call last)
<replaced_file> fun
tparsestmt.nim(88, 6) template/generic instantiation of `fun` from here
tparsestmt.nim(84, 5) template/generic instantiation of `implicit_file_for_parseStmt.nim:
>>let a0=1
>>let a1=1 # inserting a 2nd statement should given an error
>>` from here
<replaced_file> Error: unhandled exception: tparsestmt.nim(84, 5) Error: expected expression, but got multiple statements


done
'''
  exitcode: "0"
"""

## this is at line 50

#[
See also: ttryparseexpr.nim;


]#

when defined(case1):  # simple example where code given as string litteral
  import macros
  macro fun(): untyped =
    parseStmt("""
let a0=1
let a1=1
let a2=1) # inserting an error here
let a3=1
""")
  fun()

when defined(case2): # more complex example where code is generated
  import macros
  macro fun(): untyped =
    proc genCode(): string =
      result.add "let a0=1\n"
      result.add "let a1=1\n"
      result.add "let a2=1\n"
      result.add "let a1=1  # inserting a redefinition error\n"
    const code = genCode()
    parseStmt(code & "\n")
  fun()

when defined(case3): # example with parseExpr
  import macros
  macro fun(): untyped =
    parseExpr("""
let a0=1
let a1=1 # inserting a 2nd statement should given an error
""")
  fun()

when defined(case_ok1): # example with parseExpr that should compile
  import macros
  macro fun(): untyped =
    parseExpr("""
let a0=1 # this should work
""")
  fun()

when defined(case_ok2): # example with parseStmt that should compile
  import macros
  macro fun(): untyped =
    parseStmt("""
let a0=1
let a1=1
""")
  fun()

when defined(case_bug): # BUG: TODO: probably got to do with not calling `popInfoContext(p.config)` in `opcParseStmtToAst` block
  import macros
  import times
  macro fun(): untyped =
    parseStmt("""
let a0=1
let a1=1
let a2=1) # inserting an error here
let a3=1
""")
  fun()


else: # main driver

  import os, strutils, osproc, nre

  proc sanitizeOutput(s: string): string =
    ## sanitize external location information to keep the test flexible, 
    ## eg `../../lib/core/macros.nim(505))` => <replaced_file>
    result = s.replace(re"(?m)^../../[^\)]+\)", "<replaced_file>")

  doAssert sanitizeOutput("""
stack trace: (most recent call last)
../../lib/core/macros.nim(505) fun
tparsestmt.nim(89, 6) template/generic instantiation of `fun` from here""") == """
stack trace: (most recent call last)
<replaced_file> fun
tparsestmt.nim(89, 6) template/generic instantiation of `fun` from here"""

  proc main()=
    const nim = getAppFilename()
    const self = currentSourcePath
    let cases_ok = @["-d:case_ok1", "-d:case_ok2"]
    let cases_err = @["-d:case1", "-d:case2", "-d:case3"]
    for opt in cases_ok & cases_err:
      let cmd = nim & " c --compileOnly --colors:off --hints:off " & opt & " " & self
      echo "test case: " & opt & "--------------------"
      let ret = execCmdEx(cmd, {poStdErrToStdOut, poEvalCommand})
      echo ret.output.sanitizeOutput
      doAssert (ret.exitCode == 0) == (opt in cases_ok), $(ret.exitCode, opt)
      echo ""
    echo "done"
  main()
