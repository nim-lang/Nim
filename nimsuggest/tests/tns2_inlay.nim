# `inlayHints` (protocol v4) through nimsuggest2's one-shot.

let a = 1
let s = "x"

discard """
$nimsuggest2 $file
>inlayHints $file:1:0:5:0
Type;;3;;5;;: int;;false;;false;;true;;
Type;;4;;5;;: string;;false;;false;;true;;
"""
