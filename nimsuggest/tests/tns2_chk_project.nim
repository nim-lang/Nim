# nimsuggest2's `chk` checks the whole project, like nimsuggest's, whatever file
# it names: langserver sends it for the file just saved, and an error in a
# module importing that file must still be reported.

import mns2lib

discard notInLib(1)

discard """
$nimsuggest2 $file
>changed $file
>chk $path/mns2lib.nim:0:0
chk;;skUnknown;;;;Error;;$file;;7;;8;;"undeclared identifier: \'notInLib\'\x0Acandidates (edit distance, scope distance); see \'--spellSuggest\': \x0A (3, 2): \'notin\'";;0
chk;;skUnknown;;;;Error;;$file;;7;;16;;"attempting to call routine: \'notInLib\'\x0A  found \'notInLib\' [unknown declared in tests/tns2_chk_project.nim(7, 9)]";;0
chk;;skUnknown;;;;Error;;$file;;7;;16;;"attempting to call routine: \'notInLib\'\x0A  found \'notInLib\' [unknown declared in tests/tns2_chk_project.nim(7, 9)]";;0
chk;;skUnknown;;;;Error;;$file;;7;;16;;"attempting to call undeclared routine: \'notInLib\'";;0
chk;;skUnknown;;;;Error;;$file;;7;;16;;"expression \'\' has no type (or is ambiguous)";;0
chk;;skUnknown;;;;Hint;;???;;0;;-1;;"> (toplevel): import: tests/tns2_chk_project.nim [Processing]";;0
"""
