import fixtures/mlifted_hook_inst

proc useBox(): int {.compileTime.} =
  let b = box(1)
  b.val
const c0 = useBox()

proc p1(): string {.compileTime.} = "s1"
const c1 = (let f = p1; f())

proc foo*(): int = 1

# `box[int]` and the `=destroy` lifted for `Box[int]` are minted with this
# module's ids, but are cached under the generics of the fixture, so a
# recompilation of this module reuses them while `p1` gets the id the hook
# had. The VM must not hand `p1` the hook's proc handle (or the other way
# around): calling `f` then runs `=destroy`.
discard """
$nimsuggest --tester --v4 $file
>chk $file
chk;;skUnknown;;;;Hint;;$file;;6;;6;;"\'c0\' is declared but not used [XDeclaredButNotUsed]";;0
>changed $file
>chk $file
chk;;skUnknown;;;;Hint;;$file;;6;;6;;"\'c0\' is declared but not used [XDeclaredButNotUsed]";;0
chk;;skUnknown;;;;Hint;;$file;;9;;6;;"\'c1\' is declared but not used [XDeclaredButNotUsed]";;0
"""
