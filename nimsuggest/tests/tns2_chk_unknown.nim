# nimsuggest2's `chk` naming a file the project does not import checks that
# file too: langserver serves such files from the project's instance and sends
# `chk` for the file just saved.

discard notInProject(1)

discard """
$nimsuggest2 $file
!copy fixtures/mns2outsidebad.nim ns2outsidebad.nim
>changed $file
>chk $path/ns2outsidebad.nim:0:0
chk;;skUnknown;;;;Error;;$file;;5;;8;;"undeclared identifier: \'notInProject\'\x0Acandidates (edit distance, scope distance); see \'--spellSuggest\': \x0A (6, 2): \'protect\'";;0
chk;;skUnknown;;;;Error;;$file;;5;;20;;"attempting to call routine: \'notInProject\'\x0A  found \'notInProject\' [unknown declared in tests/tns2_chk_unknown.nim(5, 9)]";;0
chk;;skUnknown;;;;Error;;$file;;5;;20;;"attempting to call routine: \'notInProject\'\x0A  found \'notInProject\' [unknown declared in tests/tns2_chk_unknown.nim(5, 9)]";;0
chk;;skUnknown;;;;Error;;$file;;5;;20;;"attempting to call undeclared routine: \'notInProject\'";;0
chk;;skUnknown;;;;Error;;$file;;5;;20;;"expression \'\' has no type (or is ambiguous)";;0
chk;;skUnknown;;;;Hint;;???;;0;;-1;;"> (toplevel): import: tests/tns2_chk_unknown.nim [Processing]";;0
chk;;skUnknown;;;;Hint;;???;;0;;-1;;">> (toplevel): import: tests/ns2outsidebad.nim [Processing]";;0
chk;;skUnknown;;;;Error;;*/ns2outsidebad.nim;;1;;8;;"undeclared identifier: \'notInOutside\'\x0Acandidates (edit distance, scope distance); see \'--spellSuggest\': \x0A (7, 1): \'ns2outsidebad\'\x0A (7, 2): \'Positive\'\x0A (7, 2): \'notin\'";;0
chk;;skUnknown;;;;Error;;*/ns2outsidebad.nim;;1;;20;;"attempting to call routine: \'notInOutside\'\x0A  found \'notInOutside\' [unknown declared in tests/ns2outsidebad.nim(1, 9)]";;0
chk;;skUnknown;;;;Error;;*/ns2outsidebad.nim;;1;;20;;"attempting to call routine: \'notInOutside\'\x0A  found \'notInOutside\' [unknown declared in tests/ns2outsidebad.nim(1, 9)]";;0
chk;;skUnknown;;;;Error;;*/ns2outsidebad.nim;;1;;20;;"attempting to call undeclared routine: \'notInOutside\'";;0
chk;;skUnknown;;;;Error;;*/ns2outsidebad.nim;;1;;20;;"expression \'\' has no type (or is ambiguous)";;0
!del ns2outsidebad.nim
"""
