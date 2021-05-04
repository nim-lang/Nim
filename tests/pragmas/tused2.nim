discard """
  matrix: "--hint:conf:off --hint:link:off --hint:cc:off --hint:SuccessX:off --path:. --import:tests/pragmas/mused2e"
  joinable: false
  nimoutFull: true
  nimout: '''
mused2a.nim(20, 7) Hint: 'fn7' is declared but not used [XDeclaredButNotUsed]
mused2a.nim(23, 6) Hint: 'T1' is declared but not used [XDeclaredButNotUsed]
mused2a.nim(12, 6) Hint: 'fn1' is declared but not used [XDeclaredButNotUsed]
mused2a.nim(16, 5) Hint: 'fn4' is declared but not used [XDeclaredButNotUsed]
mused2a.nim(1, 2) Warning: imported and not used: 'mused2e' [UnusedImport]
mused2a.nim(2, 11) Warning: imported and not used: 'sugar' [UnusedImport]
mused2a.nim(3, 9) Warning: imported and not used: 'os' [UnusedImport]
mused2a.nim(5, 23) Warning: imported and not used: 'typetraits2' [UnusedImport]
mused2a.nim(6, 9) Warning: imported and not used: 'setutils' [UnusedImport]
mused2c.nim(1, 2) Warning: imported and not used: 'mused2e' [UnusedImport]
mused2b.nim(1, 2) Warning: imported and not used: 'mused2e' [UnusedImport]
mused2d.nim(1, 2) Warning: imported and not used: 'mused2e' [UnusedImport]
tused2.nim(1, 2) Warning: imported and not used: 'mused2e' [UnusedImport]
tused2.nim(42, 8) Warning: imported and not used: 'mused2a' [UnusedImport]
tused2.nim(43, 8) Warning: imported and not used: 'mused2b' [UnusedImport]
tused2.nim(45, 11) Warning: imported and not used: 'strutils' [UnusedImport]
Hint: ***SLOW, DEBUG BUILD***; -d:release makes code run faster. [BuildMode]
'''
"""
  # matrix: "--hint:conf:off --hint:link:off --hint:cc:off --hint:SuccessX:off --import:tests/pragmas/mused2e"

#[
xxx the `testament.isSuccess` logic makes `nimoutFull` awkward to use, forcing it to show `BuildMode`; 
we should improve this.

xxx tused2.nim(32, 8) Warning: imported and not used: 'mused2b' [UnusedImport]
should not be generated (refs bug #17510)
]#






# line 40
fnMused2e() # ensures `--import:tests/pragmas/mused2e` works
import mused2a
import mused2b
import mused2d
import std/strutils
baz()
{.used: mused2d.}
