import fixtures/mctvars

register("main")
const s = state()
{.warning: s.}

proc bar(): int = 1#[!]#

# A recompilation starts a new VM: the compile-time globals of the unchanged
# `mctvars` are initialized again, like IC does for a module loaded from a NIF.
# Its own `static:` block is not run again, so "own" is gone; this module
# registers "main" again, so it is there once, not twice. The first `chk`
# already recompiles this module (it passes the dirty file).
discard """
$nimsuggest --tester --v4 $file
>chk $1
chk;;skUnknown;;;;Warning;;$file;;5;;9;;"init:main [User]";;0
!edit 'int = 1' 'int = 2'
>chk $1
chk;;skUnknown;;;;Warning;;$file;;5;;9;;"init:main [User]";;0
"""
