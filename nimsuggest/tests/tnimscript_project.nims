# a .nims project is checked as NimScript: the NimScript API resolves, and importing a
# module doesn't crash nimsuggest
from std/strutils import strip

switch("hints", "off")
let home = get#[!]#Env("HOME", "/")
echo home.strip

discard """
$nimsuggest --tester $file
>def $1
def;;skProc;;system.getEnv;;proc (key: string, default: string): string{.noSideEffect, gcsafe, raises: <inferred> [].};;$lib/system/nimscript.nim;;114;;5;;"Retrieves the environment variable of name `key`.";;100
"""
