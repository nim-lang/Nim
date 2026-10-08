import fixtures/[mtypename, mtypename_inst]

const
  a = typeName(int)
  b = typeName(string)
  c = typeName(float)
  d = typeName(bool)
  e = typeName(char)

proc p1(): string {.compileTime.} = "s1"
const c1 = (let f = p1; f())
proc p2(): float {.compileTime.} = 2.0
const c2 = (let f = p2; f())
proc p3(): int {.compileTime.} = 3
const c3 = (let f = p3; f())
proc p4(): string {.compileTime.} = "s4"
const c4 = (let f = p4; f())
proc p5(): float {.compileTime.} = 5.0
const c5 = (let f = p5; f())
proc p6(): int {.compileTime.} = 6
const c6 = (let f = p6; f())
proc p7(): string {.compileTime.} = "s7"
const c7 = (let f = p7; f())
proc p8(): float {.compileTime.} = 8.0
const c8 = (let f = p8; f())
proc p9(): int {.compileTime.} = 9
const c9 = (let f = p9; f())
proc p10(): string {.compileTime.} = "s10"
const c10 = (let f = p10; f())
proc p11(): float {.compileTime.} = 11.0
const c11 = (let f = p11; f())
proc p12(): int {.compileTime.} = 12
const c12 = (let f = p12; f())

proc foo(): int = 1#[!]#

# Recompiling this module re-instantiates `typeName` here, so its own
# compile-time procs come after more symbols than in the first compilation.
# They must not reuse ids of that compilation: the VM would run the code of
# whichever proc had the id before.
discard """
$nimsuggest --tester --v4 $file
>chk $1
chk;;skUnknown;;;;Hint;;$file;;11;;6;;"\'c1\' is declared but not used [XDeclaredButNotUsed]";;0
!edit 'int = 1' 'int = 2'
>chk $1
chk;;skUnknown;;;;Hint;;$file;;11;;6;;"\'c1\' is declared but not used [XDeclaredButNotUsed]";;0
"""
