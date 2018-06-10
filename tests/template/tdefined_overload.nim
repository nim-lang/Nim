discard """
  output: "Valid and not defined"
"""
# test for issue #7997
# checking for `when not defined` in a template for some compile time symbol
# results in a compilation error of:
# Error: obsolete usage of 'defined', use 'declared' instead
# if the symbol is 'overloaded' by some variable or procedure, because in
# that case the argument of `defined` is of kind `nkSym` instead of `nkIdent`
# (for which was checked in `semexprs.semDefined`).

block:
  # check whether a proc with the same name as the argument to `defined`
  # compiles
  proc overloaded() =
    discard

  template definedCheck(): untyped =
    when not defined(overloaded): true
    else: false
  doAssert definedCheck == true

block:
  # check whether a variable with the same name as the argument to `defined`
  # compiles
  var overloaded: int

  template definedCheck(): untyped =
    when not defined(overloaded): true
    else: false
  doAssert definedCheck == true

block:
  # check whether a non overloaded when check still works properly
  when not defined(validIdentifier):
    echo "Valid and not defined"

block:
  # now check that invalid identifiers cause a compilation error
  # by using reject template.
  template reject(b) =
    static: doAssert(not compiles(b))

  reject:
    when defined(123):
      echo "Invalid identifier! Will not be echoed"
