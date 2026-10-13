# nimsuggest2's one-shot: `changed` runs `nim ns`, then each query loads the
# NIFs it built. Saved-file `highlight`/`def` come from the NIFs without
# compiling; the file sent as its own buffer is compiled. The main file is
# compiled like an import: its `when isMainModule` block is not checked.

import std/strutils

proc shout(s: string): string = s.toUpperAscii

discard shout("x")

when isMainModule:
  undefinedSymbol()

discard """
$nimsuggest2 $file
>changed $file
>known $file
true
>highlight $file:8:6
def;;skProc;;tns2_oneshot.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;8;;5;;""
use;;skProc;;tns2_oneshot.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;10;;8;;""
>highlight $file;$file:8:6
def;;skProc;;tns2_oneshot.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;8;;5;;""
def;;skProc;;tns2_oneshot.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;8;;5;;""
use;;skProc;;tns2_oneshot.shout;;proc (s: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$file;;10;;8;;""
>def $file:6:14
def;;skModule;;strutils;;;;*/pure/strutils.nim;;1;;0;;*
>chkFile $file;$file:0:0
"""
