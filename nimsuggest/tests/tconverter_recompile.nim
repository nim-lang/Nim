import mconverter

let x: int = "abc"#[!]#
echo x

# A converter removed from an imported module must no longer apply in its
# importers after both are recompiled.
discard """
!copy fixtures/mconverter_v1.nim mconverter.nim
$nimsuggest --tester --v4 $file
>chk $1
*
!copy fixtures/mconverter_v2.nim mconverter.nim
>changed $path/mconverter.nim
>chk $1
chk;;skUnknown;;;;Error;;$file;;3;;13;;"type mismatch*";;0
!del mconverter.nim
"""
