# bug #26380: recompiling a module must not replay its old macrocache puts
import std/[macros, macrocache]

const flags = CacheTable"flags26380"

static:
  flags["a"] = newLit(true)

proc foo*(): int = 1

echo foo()

discard """
$nimsuggest --tester --v4 $file
>changed $file
>chk $file
chk;;skUnknown;;;;Hint;;*
>changed $file
>chk $file
chk;;skUnknown;;;;Hint;;*
"""
